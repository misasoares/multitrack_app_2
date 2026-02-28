import 'dart:async';
import 'package:mobx/mobx.dart';
import '../../domain/entities/setlist.dart';
import '../../domain/entities/setlist_item.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/eq_band_data.dart';
import '../../domain/repositories/imusic_repository.dart';
import '../../domain/services/setlist_export_service.dart';
import '../../../../../core/audio_engine/iaudio_engine_service.dart';
import 'dart:developer' as developer;

part 'setlist_config_store.g.dart';

class SetlistConfigStore = SetlistConfigStoreBase with _$SetlistConfigStore;

abstract class SetlistConfigStoreBase with Store {
  final IAudioEngineService _audioEngine;
  final IMusicRepository _musicRepository;
  final SetlistExportService _exportService;
  SetlistConfigStoreBase(
    this._audioEngine,
    this._musicRepository,
    this._exportService,
  );

  Timer? _saveDebouncer;

  @observable
  Setlist? currentSetlist;

  @observable
  String? playingItemId;

  @observable
  bool isPlaying = false;

  /// Linear peak per track (0.0 to 1.0) for VU meters when preview is playing.
  @observable
  Map<String, double> trackPeaks = {};

  Timer? _peakTimer;

  Stream<Duration> get previewPosition => _audioEngine.onPreviewPosition;

  List<String> get _currentPreviewTrackIds {
    if (playingItemId == null || currentSetlist == null) return [];
    try {
      final item = currentSetlist!.items.firstWhere((i) => i.id == playingItemId);
      return item.originalMusic.tracks
          .where((t) => !t.isMuted)
          .map((t) => t.id)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @observable
  bool isLoading = false;

  @computed
  Duration get totalDuration {
    if (currentSetlist == null || currentSetlist!.items.isEmpty) {
      return Duration.zero;
    }
    // Sum of the longest active (non-muted) track in each music
    return currentSetlist!.items.fold(Duration.zero, (prev, item) {
      final activeTracks =
          item.originalMusic.tracks.where((t) => !t.isMuted).toList();
      if (activeTracks.isEmpty) return prev;
      final musicDuration =
          activeTracks.map((t) => t.duration).reduce((a, b) => a > b ? a : b);
      return prev + (musicDuration * (1 / item.tempoFactor));
    });
  }

  @action
  void init(Setlist setlist) {
    currentSetlist = setlist;
  }

  @action
  void updateItemVolume(String itemId, double volume) {
    if (currentSetlist == null) return;

    final index = currentSetlist!.items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final updatedItem = currentSetlist!.items[index].copyWith(volume: volume);
      final newItems = List<SetlistItem>.from(currentSetlist!.items);
      newItems[index] = updatedItem;
      currentSetlist = currentSetlist!.copyWith(items: newItems);

      if (playingItemId == itemId) {
        _applyMastering(updatedItem);
      }
    }
  }

  @action
  void updateItemTempo(String itemId, double factor) {
    if (currentSetlist == null) return;

    final index = currentSetlist!.items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final updatedItem = currentSetlist!.items[index].copyWith(
        tempoFactor: factor,
      );
      final newItems = List<SetlistItem>.from(currentSetlist!.items);
      newItems[index] = updatedItem;
      currentSetlist = currentSetlist!.copyWith(items: newItems);

      if (playingItemId == itemId) {
        _applyMastering(updatedItem);
      }
    }
  }

  @action
  void updateItemTranspose(String itemId, int semitones) {
    if (currentSetlist == null) return;

    final index = currentSetlist!.items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      SetlistItem item = currentSetlist!.items[index];

      // If returning to original key (0), reset all smart octave shifts
      if (semitones == 0) {
        final resetTracks = item.originalMusic.tracks
            .map((t) => t.copyWith(octaveShift: 0))
            .toList();
        item = item.copyWith(
          originalMusic: item.originalMusic.copyWith(tracks: resetTracks),
        );
      }

      final updatedItem = item.copyWith(transposeSemitones: semitones);
      final newItems = List<SetlistItem>.from(currentSetlist!.items);
      newItems[index] = updatedItem;
      currentSetlist = currentSetlist!.copyWith(items: newItems);

      if (playingItemId == itemId) {
        // Re-apply pitch to all tracks based on the new global value
        for (final track in updatedItem.originalMusic.tracks) {
          final pitch = _calculateTrackPitch(updatedItem, track);
          _audioEngine.setTrackPitch(track.id, pitch);
        }
      }
      _debouncedSave();
    }
  }

  @action
  void toggleTrackTranspose(String itemId, String trackId, bool apply) {
    _updateTrack(
      itemId,
      trackId,
      (track) => track.copyWith(
        applyTranspose: apply,
        octaveShift: apply ? track.octaveShift : 0,
      ),
    );
    if (playingItemId == itemId) {
      final item = currentSetlist!.items.firstWhere((i) => i.id == itemId);
      final track = item.originalMusic.tracks.firstWhere(
        (t) => t.id == trackId,
      );
      _audioEngine.setTrackPitch(trackId, _calculateTrackPitch(item, track));
    }
    _debouncedSave();
  }

  @action
  void toggleTrackOctave(String itemId, String trackId) {
    _updateTrack(itemId, trackId, (track) {
      if (track.octaveShift != 0) {
        return track.copyWith(octaveShift: 0);
      }

      final item = currentSetlist?.items.firstWhere((i) => i.id == itemId);
      if (item == null) return track;

      // Suggest +1 if song is lowered, -1 if song is raised
      final suggestedShift = item.transposeSemitones <= 0 ? 1 : -1;
      return track.copyWith(octaveShift: suggestedShift);
    });

    if (playingItemId == itemId) {
      final item = currentSetlist!.items.firstWhere((i) => i.id == itemId);
      final track = item.originalMusic.tracks.firstWhere(
        (t) => t.id == trackId,
      );
      _audioEngine.setTrackPitch(trackId, _calculateTrackPitch(item, track));
    }
    _debouncedSave();
  }

  int _calculateTrackPitch(SetlistItem item, Track track) {
    final basePitch = track.applyTranspose ? item.transposeSemitones : 0;
    return basePitch + (track.octaveShift * 12);
  }

  @action
  void updateItemMasterEq(String itemId, EqBandData updatedBand) {
    if (currentSetlist == null) return;

    final index = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = currentSetlist!.items[index];
    final newBands = List<EqBandData>.from(item.masterEqBands);
    final bandIndex = newBands.indexWhere(
      (b) => b.bandIndex == updatedBand.bandIndex,
    );

    if (bandIndex != -1) {
      newBands[bandIndex] = updatedBand;
    } else {
      newBands.add(updatedBand);
    }

    final updatedItem = item.copyWith(masterEqBands: newBands);
    final newItems = List<SetlistItem>.from(currentSetlist!.items);
    newItems[index] = updatedItem;
    currentSetlist = currentSetlist!.copyWith(items: newItems);

    if (playingItemId == itemId) {
      // Apply the specific band change immediately
      _audioEngine.setMasterEq(
        bandIndex: updatedBand.bandIndex,
        filterType: updatedBand.type.index,
        frequency: updatedBand.frequency,
        gain: updatedBand.gain,
        q: updatedBand.q,
      );
    }
  }

  @action
  void updateTrackEq(String itemId, String trackId, EqBandData updatedBand) {
    if (currentSetlist == null) return;

    final index = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = currentSetlist!.items[index];
    final song = item.originalMusic;
    final trackIndex = song.tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex == -1) return;

    final track = song.tracks[trackIndex];
    final newBands = List<EqBandData>.from(track.eqBands);
    final bandIndex = newBands.indexWhere(
      (b) => b.bandIndex == updatedBand.bandIndex,
    );

    if (bandIndex != -1) {
      newBands[bandIndex] = updatedBand;
    } else {
      newBands.add(updatedBand);
    }

    final updatedTrack = track.copyWith(eqBands: newBands);
    final newTracks = List<Track>.from(song.tracks);
    newTracks[trackIndex] = updatedTrack;

    final updatedSong = song.copyWith(tracks: newTracks);
    final updatedItem = item.copyWith(originalMusic: updatedSong);

    final newItems = List<SetlistItem>.from(currentSetlist!.items);
    newItems[index] = updatedItem;
    currentSetlist = currentSetlist!.copyWith(items: newItems);

    if (playingItemId == itemId) {
      _audioEngine.setTrackEq(
        trackId: trackId,
        bandIndex: updatedBand.bandIndex,
        filterType: updatedBand.type.index,
        frequency: updatedBand.frequency,
        gain: updatedBand.gain,
        q: updatedBand.q,
      );
    }

    _debouncedSave();
  }

  @action
  void updateTrackMute(String itemId, String trackId, bool muted) {
    _updateTrack(itemId, trackId, (track) => track.copyWith(isMuted: muted));
    if (playingItemId == itemId) {
      _audioEngine.setTrackMute(trackId, muted);
    }
    _debouncedSave();
  }

  @action
  void updateTrackSolo(String itemId, String trackId, bool solo) {
    _updateTrack(itemId, trackId, (track) => track.copyWith(isSolo: solo));
    if (playingItemId == itemId) {
      _audioEngine.setTrackSolo(trackId, solo);
    }
    _debouncedSave();
  }

  @action
  void updateTrackVolume(String itemId, String trackId, double volume) {
    _updateTrack(itemId, trackId, (track) => track.copyWith(volume: volume));
    if (playingItemId == itemId) {
      _audioEngine.setTrackVolume(trackId, volume);
    }
    _debouncedSave();
  }

  @action
  void updateTrackPan(String itemId, String trackId, double pan) {
    _updateTrack(itemId, trackId, (track) => track.copyWith(pan: pan));
    if (playingItemId == itemId) {
      _audioEngine.setTrackPan(trackId, pan);
    }
    _debouncedSave();
  }

  void _updateTrack(
    String itemId,
    String trackId,
    Track Function(Track) updateFn,
  ) {
    if (currentSetlist == null) return;

    final index = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = currentSetlist!.items[index];
    final song = item.originalMusic;
    final trackIndex = song.tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex == -1) return;

    final track = song.tracks[trackIndex];
    final updatedTrack = updateFn(track);

    final newTracks = List<Track>.from(song.tracks);
    newTracks[trackIndex] = updatedTrack;

    final updatedSong = song.copyWith(tracks: newTracks);
    final updatedItem = item.copyWith(originalMusic: updatedSong);

    final newItems = List<SetlistItem>.from(currentSetlist!.items);
    newItems[index] = updatedItem;
    currentSetlist = currentSetlist!.copyWith(items: newItems);
  }

  void _debouncedSave() {
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 500), () {
      saveDraft();
    });
  }

  @action
  Future<void> saveDraft() async {
    if (currentSetlist == null) return;

    try {
      await _musicRepository.saveSetlist(currentSetlist!);
      developer.log('Setlist settings saved to DB', name: 'SetlistConfigStore');
    } catch (e) {
      developer.log('Error saving setlist: $e', name: 'SetlistConfigStore');
    }
  }

  @action
  Future<void> seek(Duration position) async {
    await _audioEngine.seekTo(position);
  }

  @observable
  String? previewLoadingItemId;

  @observable
  bool isRendering = false;

  @observable
  double renderProgress = 0.0;

  @observable
  String renderMessage = '';

  @action
  Future<void> togglePreview(String itemId) async {
    // If clicking the currently playing item, just toggle pause/stop
    if (playingItemId == itemId && isPlaying) {
      await _audioEngine.pause();
      _audioEngine.clearAllTracks(); // Clear tracks to avoid memory usage
      isPlaying = false;
      _peakTimer?.cancel();
      _peakTimer = null;
      trackPeaks = {};
      return;
    }

    // If clicking a different item or starting playback
    if (playingItemId != itemId) {
      // Stop current
      if (isPlaying) {
        await _audioEngine.pause();
        isPlaying = false;
        _peakTimer?.cancel();
        _peakTimer = null;
        trackPeaks = {};
      }

      // Clear old playing ID to remove its timeline immediately
      playingItemId = null;

      // Set loading state
      previewLoadingItemId = itemId;

      try {
        final item = currentSetlist!.items.firstWhere((i) => i.id == itemId);
        final tracksToRender =
            item.originalMusic.tracks.where((t) => !t.isMuted).toList();

        // Load only active (non-muted) tracks to save RAM/CPU
        await _audioEngine.loadPreview(tracksToRender);
        _applyMastering(item); // Apply tempo/pitch/volume

        // Ready to play
        playingItemId = itemId;
        _audioEngine.playPreview();
        isPlaying = true;
        _startPeakTimer();
      } catch (e) {
        developer.log('Error loading preview: $e', name: 'SetlistConfigStore');
      } finally {
        previewLoadingItemId = null;
      }
    } else {
      // Case: playingItemId == itemId but isPlaying is false (paused)
      // Just resume
      _audioEngine.playPreview();
      isPlaying = true;
      _startPeakTimer();
    }
  }

  void _startPeakTimer() {
    _peakTimer?.cancel();
    _peakTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      final ids = _currentPreviewTrackIds;
      if (ids.isEmpty) return;
      runInAction(() {
        final m = Map<String, double>.from(trackPeaks);
        for (final id in ids) {
          final raw = _audioEngine.getTrackPeak(id);
          final prev = m[id] ?? 0.0;
          final smoothed = raw > prev
              ? prev + (raw - prev) * 0.42
              : prev * 0.88;
          m[id] = smoothed < 0.005 ? 0.0 : smoothed.clamp(0.0, 1.0);
        }
        trackPeaks = m;
      });
    });
  }

  @action
  Future<void> renderShow() async {
    if (currentSetlist == null) return;

    if (isPlaying) {
      await _audioEngine.pause();
      _audioEngine.clearAllTracks();
      isPlaying = false;
      _peakTimer?.cancel();
      _peakTimer = null;
      trackPeaks = {};
    }

    isRendering = true;
    renderProgress = 0.0;
    renderMessage = 'Preparando...';

    try {
      final updatedSetlist = await _exportService.exportSetlist(
        currentSetlist!,
        onProgress: (p) {
          runInAction(() {
            renderProgress = p.globalPercent;
            final title = p.currentMusicTitle ?? '';
            final track = p.currentTrackName ?? '';
            final percent = (p.globalPercent * 100).round();
            renderMessage = title.isNotEmpty && track.isNotEmpty
                ? '$title - $track ($percent%)'
                : 'Preparando...';
          });
        },
      );
      final toSave = updatedSetlist.copyWith(status: SetlistStatus.ready);
      await _musicRepository.saveSetlist(toSave);
      currentSetlist = toSave;
    } catch (e) {
      developer.log('Render show failed: $e', name: 'SetlistConfigStore');
      rethrow;
    } finally {
      runInAction(() {
        isRendering = false;
        renderProgress = 0.0;
        renderMessage = '';
      });
    }
  }

  void _applyMastering(SetlistItem item) {
    final activeTracks =
        item.originalMusic.tracks.where((t) => !t.isMuted).toList();
    for (final track in activeTracks) {
      _audioEngine.setTrackTempo(track.id, item.tempoFactor);
      _audioEngine.setTrackPitch(track.id, _calculateTrackPitch(item, track));
      _audioEngine.setTrackVolume(track.id, track.volume);
      _audioEngine.setTrackPan(track.id, track.pan);
    }

    // Apply Master Volume (using item volume as master volume for the mix)
    _audioEngine.setMasterVolume(item.volume);

    // Apply Master EQ
    for (final band in item.masterEqBands) {
      _audioEngine.setMasterEq(
        bandIndex: band.bandIndex,
        filterType: band.type.index,
        frequency: band.frequency,
        gain: band.gain,
        q: band.q,
      );
    }
  }

  void dispose() {
    _peakTimer?.cancel();
    _peakTimer = null;
    _audioEngine.clearAllTracks();
    _audioEngine.pause();
    isPlaying = false;
    currentSetlist = null;
    playingItemId = null;
  }
}
