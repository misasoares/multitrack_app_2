import 'dart:async';
import 'package:mobx/mobx.dart';
import '../../domain/entities/setlist.dart';
import '../../domain/entities/setlist_item.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/music.dart';
import '../../domain/entities/app_mode.dart';
import '../../domain/entities/eq_band_data.dart';
import '../../domain/repositories/imusic_repository.dart';
import '../../domain/services/setlist_export_service.dart';
import '../../../../../core/audio_engine/iaudio_engine_service.dart';
import 'dart:developer' as developer;

part 'stage_store.g.dart';

class StageStore = StageStoreBase with _$StageStore;

abstract class StageStoreBase with Store {
  final IAudioEngineService _audioEngine;
  final IMusicRepository _musicRepository;
  final SetlistExportService _exportService;

  StageStoreBase(this._audioEngine, this._musicRepository, this._exportService);

  @observable
  AppMode mode = AppMode.rehearsal;

  @observable
  Setlist? currentSetlist;

  @observable
  String? playingItemId;

  @observable
  bool isPlaying = false;

  @observable
  bool isLoading = false;

  @observable
  bool isRendering = false;

  @observable
  double renderProgress = 0.0;

  @observable
  String renderMessage = '';

  @observable
  Map<String, double> trackPeaks = {};

  Timer? _peakTimer;
  Timer? _saveDebouncer;

  @computed
  bool get isRehearsalMode => mode == AppMode.rehearsal;

  @computed
  bool get isPerformanceMode => mode == AppMode.performance;

  @action
  void setMode(AppMode newMode) {
    mode = newMode;
    if (mode == AppMode.performance) {
      // Lock UI or stop background processes if needed
    }
  }

  @action
  void init(Setlist setlist) {
    currentSetlist = setlist;
  }

  // ─── Import & Analysis ─────────────────────────────────────────────────────

  @action
  Future<void> importTracksForNewMusic({
    required String title,
    required List<String> filePaths,
  }) async {
    isLoading = true;
    try {
      final List<Track> analyzedTracks = [];

      for (final path in filePaths) {
        final fileName = path.split('/').last;
        final isUtility = Track.checkIsUtility(fileName);

        // Analyze track
        final result = await _audioEngine.analyzeTrack(path, targetLufs: -14.0);

        double normGain = 1.0;
        if (result != null) {
          if (isUtility) {
            // Peak normalization for Click/Guide (-3dB)
            // Target linear peak = 10^(-3/20) = 0.7079
            const double targetPeak = 0.7079;
            normGain = result.truePeak > 0 ? targetPeak / result.truePeak : 1.0;
          } else {
            // LUFS normalization for Musical Tracks (-14.0)
            normGain = result.normalizationGain;
          }
        }

        final track = Track(
          id: DateTime.now().millisecondsSinceEpoch.toString() + fileName,
          name: fileName,
          filePath: path,
          volume: 1.0,
          isClick: isUtility,
          normalizationGain: normGain, // Store normalization gain
          // We can't store normalization gain in Track yet, but we'll apply it now
          // and maybe we should add it to the Track entity or use the Engine directly.
          // For now, let's assume we want to store the "mix" gain.
        );

        // Apply individual gain in the engine if we were playing, but here we are just importing.
        analyzedTracks.add(track);
      }

      final music = Music(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        bpm: 120, // Default, user can edit
        tracks: analyzedTracks,
      );

      // Save to library
      await _musicRepository.saveMusic(music);

      // Add to current setlist
      if (currentSetlist != null) {
        final item = SetlistItem.fromMusic(music);
        final newItems = List<SetlistItem>.from(currentSetlist!.items)
          ..add(item);
        currentSetlist = currentSetlist!.copyWith(items: newItems);
        await _musicRepository.saveSetlist(currentSetlist!);
      }
    } finally {
      isLoading = false;
    }
  }

  // ─── Mixing & Auto-Save ────────────────────────────────────────────────────

  @action
  void updateTrackVolume(String itemId, String trackId, double volume) {
    _updateTrackState(itemId, trackId, (t) => t.copyWith(volume: volume));
    if (playingItemId == itemId) {
      _audioEngine.setTrackVolume(trackId, volume);
    }
    if (isRehearsalMode) _autoSaveMusic(itemId);
  }

  @action
  void updateTrackMute(String itemId, String trackId, bool muted) {
    _updateTrackState(itemId, trackId, (t) => t.copyWith(isMuted: muted));
    if (playingItemId == itemId) {
      _audioEngine.setTrackMute(trackId, muted);
    }
    if (isRehearsalMode) _autoSaveMusic(itemId);
  }

  @action
  void updateTrackPan(String itemId, String trackId, double pan) {
    _updateTrackState(itemId, trackId, (t) => t.copyWith(pan: pan));
    if (playingItemId == itemId) {
      _audioEngine.setTrackPan(trackId, pan);
    }
    if (isRehearsalMode) _autoSaveMusic(itemId);
  }

  @action
  void updateTrackEq(String itemId, String trackId, EqBandData updatedBand) {
    _updateTrackState(itemId, trackId, (t) {
      final newBands = List<EqBandData>.from(t.eqBands);
      final index = newBands.indexWhere(
        (b) => b.bandIndex == updatedBand.bandIndex,
      );
      if (index != -1) {
        newBands[index] = updatedBand;
      } else {
        newBands.add(updatedBand);
      }
      return t.copyWith(eqBands: newBands);
    });
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
    if (isRehearsalMode) _autoSaveMusic(itemId);
  }

  @action
  void updateItemTempo(String itemId, double tempo) {
    if (currentSetlist == null) return;
    final index = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = currentSetlist!.items[index].copyWith(tempoFactor: tempo);
    final newItems = List<SetlistItem>.from(currentSetlist!.items)
      ..[index] = item;
    currentSetlist = currentSetlist!.copyWith(items: newItems);

    if (playingItemId == itemId) {
      for (final t in item.originalMusic.tracks) {
        _audioEngine.setTrackTempo(t.id, tempo);
      }
    }
    _debouncedSetlistSave();
  }

  @action
  void updateItemTranspose(String itemId, int semitones) {
    if (currentSetlist == null) return;
    final index = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = currentSetlist!.items[index].copyWith(
      transposeSemitones: semitones,
    );
    final newItems = List<SetlistItem>.from(currentSetlist!.items)
      ..[index] = item;
    currentSetlist = currentSetlist!.copyWith(items: newItems);

    if (playingItemId == itemId) {
      for (final t in item.originalMusic.tracks) {
        final totalPitch = t.applyTranspose
            ? semitones + (t.octaveShift * 12)
            : (t.octaveShift * 12);
        _audioEngine.setTrackPitch(t.id, totalPitch);
      }
    }
    _debouncedSetlistSave();
  }

  // ─── Preview ───────────────────────────────────────────────────────────────

  @action
  Future<void> togglePreview(String itemId) async {
    if (playingItemId == itemId && isPlaying) {
      await _audioEngine.pause();
      isPlaying = false;
      _peakTimer?.cancel();
      return;
    }

    if (playingItemId != itemId) {
      if (isPlaying) await _audioEngine.pause();
      playingItemId = itemId;

      final item = currentSetlist!.items.firstWhere((i) => i.id == itemId);
      final tracks = item.originalMusic.tracks
          .where((t) => !t.isMuted)
          .toList();

      await _audioEngine.loadPreview(tracks);

      // Apply mix
      for (final t in tracks) {
        _audioEngine.setTrackVolume(t.id, t.volume);
        _audioEngine.setTrackPan(t.id, t.pan);
        final pitch = t.applyTranspose
            ? item.transposeSemitones + (t.octaveShift * 12)
            : (t.octaveShift * 12);
        _audioEngine.setTrackPitch(t.id, pitch);
        _audioEngine.setTrackTempo(t.id, item.tempoFactor);

        // Apply normalization gain
        _audioEngine.setTrackNormalizationGain(t.id, t.normalizationGain);
      }

      await _audioEngine.play();
      isPlaying = true;
      _startPeakTimer();
    } else {
      await _audioEngine.play();
      isPlaying = true;
      _startPeakTimer();
    }
  }

  void _startPeakTimer() {
    _peakTimer?.cancel();
    _peakTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (playingItemId == null || currentSetlist == null) return;
      final item = currentSetlist!.items.firstWhere(
        (i) => i.id == playingItemId,
      );
      runInAction(() {
        final peaks = <String, double>{};
        for (final t in item.originalMusic.tracks) {
          peaks[t.id] = _audioEngine.getTrackPeak(t.id);
        }
        trackPeaks = peaks;
      });
    });
  }

  void _debouncedSetlistSave() {
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 1000), () async {
      if (currentSetlist != null) {
        await _musicRepository.saveSetlist(currentSetlist!);
        developer.log('Setlist saved', name: 'StageStore');
      }
    });
  }

  void dispose() {
    _peakTimer?.cancel();
    _saveDebouncer?.cancel();
    _audioEngine.pause(); // Changed from _audioEngine.stopApp(0)
  }

  void _updateTrackState(
    String itemId,
    String trackId,
    Track Function(Track) updater,
  ) {
    if (currentSetlist == null) return;
    final itemIndex = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = currentSetlist!.items[itemIndex];
    final music = item.originalMusic;
    final trackIndex = music.tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex == -1) return;

    final updatedTrack = updater(music.tracks[trackIndex]);
    final newTracks = List<Track>.from(music.tracks)
      ..[trackIndex] = updatedTrack;
    final updatedMusic = music.copyWith(tracks: newTracks);
    final updatedItem = item.copyWith(originalMusic: updatedMusic);

    final newItems = List<SetlistItem>.from(currentSetlist!.items)
      ..[itemIndex] = updatedItem;
    currentSetlist = currentSetlist!.copyWith(items: newItems);
  }

  void _autoSaveMusic(String itemId) {
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 1000), () async {
      if (currentSetlist == null) return;
      final item = currentSetlist!.items.firstWhere((i) => i.id == itemId);
      await _musicRepository.saveMusic(item.originalMusic);
      await _musicRepository.saveSetlist(currentSetlist!);
      developer.log('Auto-saved music/setlist', name: 'StageStore');
    });
  }

  // ─── Playback & Rendering ──────────────────────────────────────────────────

  @action
  Future<void> renderSetlist() async {
    if (currentSetlist == null) return;
    isRendering = true;
    try {
      final updatedSetlist = await _exportService.exportSetlist(
        currentSetlist!,
        onProgress: (p) => runInAction(() {
          renderProgress = p.globalPercent;
          renderMessage = 'Rendering ${p.currentMusicTitle ?? ''}...';
        }),
      );
      currentSetlist = updatedSetlist.copyWith(status: SetlistStatus.ready);
      await _musicRepository.saveSetlist(currentSetlist!);
    } catch (e) {
      developer.log('Render failed: $e', name: 'StageStore');
    } finally {
      isRendering = false;
    }
  }

  // (Implement togglePreview, seek, etc. similar to SetlistConfigStore)
}
