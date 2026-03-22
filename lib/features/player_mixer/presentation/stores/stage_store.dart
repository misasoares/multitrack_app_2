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
import 'package:isar/isar.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import '../../data/models/midi_config_model.dart';
import 'dart:developer' as developer;

part 'stage_store.g.dart';

class StageStore = StageStoreBase with _$StageStore;

abstract class StageStoreBase with Store {
  final IAudioEngineService _audioEngine;
  final IMusicRepository _musicRepository;
  final SetlistExportService _exportService;
  final Isar _isar;

  StageStoreBase(
    this._audioEngine,
    this._musicRepository,
    this._exportService,
    this._isar,
  );

  Future<void> initialize() async {
    await _initMidi();
  }

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
  String? previewLoadingItemId;

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

  @computed
  Duration get totalDuration {
    if (currentSetlist == null) return Duration.zero;
    return currentSetlist!.items.fold(
      Duration.zero,
      (prev, item) => prev + item.originalMusic.duration,
    );
  }

  @computed
  Stream<Duration> get previewPosition => _audioEngine.onPreviewPosition;

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
  void updateTrackSolo(String itemId, String trackId, bool isSolo) {
    _updateTrackState(itemId, trackId, (t) => t.copyWith(isSolo: isSolo));
    _audioEngine.setTrackSolo(trackId, isSolo);
    _autoSaveMusic(itemId);
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
  void updateItemMasterEq(String itemId, EqBandData band) {
    if (currentSetlist == null) return;
    final itemIndex = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = currentSetlist!.items[itemIndex];
    final newBands = List<EqBandData>.from(item.masterEqBands);
    final bandIndex = newBands.indexWhere((b) => b.bandIndex == band.bandIndex);
    if (bandIndex != -1) {
      newBands[bandIndex] = band;
    } else {
      newBands.add(band);
    }

    final updatedItem = item.copyWith(masterEqBands: newBands);
    final newItems = List<SetlistItem>.from(currentSetlist!.items)
      ..[itemIndex] = updatedItem;
    currentSetlist = currentSetlist!.copyWith(items: newItems);

    _audioEngine.setMasterEq(
      bandIndex: band.bandIndex,
      filterType: band.type.index,
      frequency: band.frequency,
      gain: band.gain,
      q: band.q,
    );

    _autoSaveMusic(itemId);
  }

  @action
  void updateItemVolume(String itemId, double volume) {
    if (currentSetlist == null) return;
    final index = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = currentSetlist!.items[index].copyWith(volume: volume);
    final newItems = List<SetlistItem>.from(currentSetlist!.items)
      ..[index] = item;
    currentSetlist = currentSetlist!.copyWith(items: newItems);

    if (playingItemId == itemId) {
      _audioEngine.setMasterVolume(volume);
    }
    _debouncedSetlistSave();
  }

  @observable
  Duration currentPosition = Duration.zero;

  @observable
  bool isScrubbing = false;

  @observable
  double masterVolume = 1.0;

  @observable
  double metronomeBpm = 120.0;

  @observable
  double metronomeVolume = 2.0;

  @observable
  double metronomePan = -1.0;

  @observable
  bool isMetronomePlaying = false;

  @observable
  bool isMixerVisible = false;

  @observable
  bool isMetronomeVisible = false;

  @observable
  bool isDrumRackVisible = false;

  @observable
  ObservableMap<int, String> midiDrumMap = ObservableMap<int, String>();

  final List<int> _tapTempoTimestamps = [];
  static const int _tapTempoMaxTaps = 4;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<dynamic>? _midiSubscription; // Placeholder for MIDI

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

  // ─── Metronome & Master ──────────────────────────────────────────────────

  @action
  void setMasterVolume(double volume) {
    masterVolume = volume.clamp(0.0, 5.0);
    _audioEngine.setMasterVolume(masterVolume);
  }

  @action
  void setMetronomeBpm(double bpm) {
    metronomeBpm = bpm.clamp(20.0, 300.0);
    _audioEngine.setMetronomeBpm(metronomeBpm);
  }

  @action
  void setMetronomeVolume(double volume) {
    metronomeVolume = volume.clamp(0.0, 3.0);
    _audioEngine.setMetronomeVolume(metronomeVolume);
  }

  @action
  void setMetronomePan(double pan) {
    metronomePan = pan.clamp(-1.0, 1.0);
    _audioEngine.setMetronomePan(metronomePan);
  }

  @action
  void setMetronomePlaying(bool playing) {
    isMetronomePlaying = playing;
    _audioEngine.setMetronomePlaying(playing);
  }

  @action
  void tapTempo() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _tapTempoTimestamps.add(now);
    if (_tapTempoTimestamps.length > _tapTempoMaxTaps) {
      _tapTempoTimestamps.removeAt(0);
    }
    if (_tapTempoTimestamps.length < 2) return;
    final diffs = <int>[];
    for (var i = 1; i < _tapTempoTimestamps.length; i++) {
      diffs.add(_tapTempoTimestamps[i] - _tapTempoTimestamps[i - 1]);
    }
    final avgDiff = diffs.reduce((a, b) => a + b) / diffs.length;
    if (avgDiff > 0) {
      final bpm = 60000.0 / avgDiff;
      setMetronomeBpm(bpm.clamp(20.0, 300.0));
    }
  }

  @action
  void toggleMixerVisible() {
    if (!isMixerVisible) {
      isMetronomeVisible = false;
      isDrumRackVisible = false;
    }
    isMixerVisible = !isMixerVisible;
  }

  @action
  void toggleMetronomeVisible() {
    if (!isMetronomeVisible) {
      isMixerVisible = false;
      isDrumRackVisible = false;
    }
    isMetronomeVisible = !isMetronomeVisible;
  }

  @action
  void toggleDrumRackVisible() {
    if (!isDrumRackVisible) {
      isMixerVisible = false;
      isMetronomeVisible = false;
    }
    isDrumRackVisible = !isDrumRackVisible;
  }

  // ─── MIDI & Transport ─────────────────────────────────────────────────────

  @action
  Future<void> _initMidi() async {
    await loadMidiConfig();
    _midiSubscription = MidiCommand().onMidiDataReceived?.listen(
      _handlePerformanceMidi,
    );
  }

  @action
  Future<void> loadMidiConfig() async {
    try {
      final config = await _isar.midiConfigModels
          .filter()
          .deviceIdEqualTo('default_config')
          .findFirst();

      if (config != null) {
        midiDrumMap.clear();
        midiDrumMap.addAll(config.getMap());
      }
    } catch (e) {
      developer.log('Error loading MIDI config: $e', name: 'StageStore');
    }
  }

  void _handlePerformanceMidi(MidiPacket packet) {
    // Basic note-on detection
    final data = packet.data;
    if (data.length >= 3 && (data[0] & 0xF0) == 0x90) {
      final note = data[1];
      final velocity = data[2];

      if (velocity > 0) {
        final padId = midiDrumMap[note];
        if (padId != null) {
          _audioEngine.triggerDrumPad(padId);
        }
      }
    }
  }

  @action
  Future<void> seekToPosition(Duration position) async {
    currentPosition = position;
    await _audioEngine.seekTo(position);
  }

  @action
  void startScrubbing() {
    isScrubbing = true;
  }

  @action
  void updateScrubPosition(Duration position) {
    currentPosition = position;
  }

  @action
  void endScrubbing() {
    isScrubbing = false;
    _audioEngine.seekTo(currentPosition);
  }

  void _setupPositionSubscription() {
    _positionSubscription?.cancel();
    _positionSubscription = _audioEngine.onPreviewPosition.listen((d) {
      if (!isScrubbing) {
        runInAction(() => currentPosition = d);
      }
    });
  }

  // ─── Preview ───────────────────────────────────────────────────────────────

  @action
  Future<void> togglePreview(String itemId) async {
    if (playingItemId == itemId && isPlaying) {
      await _audioEngine.pause();
      isPlaying = false;
      _peakTimer?.cancel();
      _positionSubscription?.cancel();
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
      _setupPositionSubscription();

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
      _setupPositionSubscription();
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

  @observable
  int activeSongIndex = 0;

  @computed
  SetlistItem? get currentItem {
    if (currentSetlist == null || currentSetlist!.items.isEmpty) return null;
    return currentSetlist!.items[activeSongIndex.clamp(
      0,
      currentSetlist!.items.length - 1,
    )];
  }

  @action
  Future<void> nextSong() async {
    if (currentSetlist == null) return;
    if (activeSongIndex < currentSetlist!.items.length - 1) {
      activeSongIndex++;
      await _loadCurrentItem();
    }
  }

  @action
  Future<void> previousSong() async {
    if (activeSongIndex > 0) {
      activeSongIndex--;
      await _loadCurrentItem();
    }
  }

  @action
  Future<void> goToSong(int index) async {
    if (currentSetlist == null ||
        index < 0 ||
        index >= currentSetlist!.items.length) {
      return;
    }
    activeSongIndex = index;
    await _loadCurrentItem();
  }

  Future<void> _loadCurrentItem() async {
    final item = currentItem;
    if (item == null) return;

    if (isPlaying) {
      await _audioEngine.pause();
      isPlaying = false;
    }

    currentPosition = Duration.zero;
    playingItemId = item.id;

    // Determine tracks based on mode
    List<Track> tracksToLoad;
    if (mode == AppMode.performance &&
        item.exportedItemDirectory != null &&
        item.exportedItemDirectory!.isNotEmpty) {
      tracksToLoad = item.originalMusic.tracks.map((t) {
        final path = '${item.exportedItemDirectory}/${t.id}.wav';
        return t.copyWith(filePath: path);
      }).toList();
    } else {
      tracksToLoad = item.originalMusic.tracks
          .where((t) => !t.isMuted)
          .toList();
    }

    await _audioEngine.loadPreview(tracksToLoad);
    _setupPositionSubscription();

    // Apply mix/normalization
    for (final t in tracksToLoad) {
      _audioEngine.setTrackVolume(t.id, t.volume);
      _audioEngine.setTrackPan(t.id, t.pan);

      if (mode == AppMode.performance) {
        // In performance mode, tempo and pitch are usually baked if using rendered files,
        // but let's reset to defaults just in case.
        _audioEngine.setTrackTempo(t.id, 1.0);
        _audioEngine.setTrackPitch(t.id, 0);
      } else {
        final pitch = t.applyTranspose
            ? item.transposeSemitones + (t.octaveShift * 12)
            : (t.octaveShift * 12);
        _audioEngine.setTrackPitch(t.id, pitch);
        _audioEngine.setTrackTempo(t.id, item.tempoFactor);
        _audioEngine.setTrackNormalizationGain(t.id, t.normalizationGain);
      }
    }

    // Setlist-level metronome/master
    _audioEngine.setMetronomeBpm(metronomeBpm);
    _audioEngine.setMasterVolume(masterVolume);

    // Autoplay if in performance? Usually not, wait for user.
  }

  void dispose() {
    _peakTimer?.cancel();
    _saveDebouncer?.cancel();
    _positionSubscription?.cancel();
    _midiSubscription?.cancel();
    _audioEngine.pause();
    developer.log('StageStore disposed', name: 'StageStore');
  }

  @action
  void seek(Duration position) {
    _audioEngine.seekTo(position);
  }

  @action
  void toggleTrackTranspose(String itemId, String trackId, bool apply) {
    _updateTrackState(
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
      final pitch = track.applyTranspose
          ? item.transposeSemitones + (track.octaveShift * 12)
          : (track.octaveShift * 12);
      _audioEngine.setTrackPitch(trackId, pitch);
    }
    _autoSaveMusic(itemId);
  }

  @action
  void toggleTrackOctave(String itemId, String trackId) {
    _updateTrackState(itemId, trackId, (t) {
      if (t.octaveShift != 0) return t.copyWith(octaveShift: 0);
      try {
        final item = currentSetlist!.items.firstWhere((i) => i.id == itemId);
        final suggestedShift = item.transposeSemitones <= 0 ? 1 : -1;
        return t.copyWith(octaveShift: suggestedShift);
      } catch (_) {
        return t;
      }
    });

    if (playingItemId == itemId) {
      final item = currentSetlist!.items.firstWhere((i) => i.id == itemId);
      final track = item.originalMusic.tracks.firstWhere(
        (t) => t.id == trackId,
      );
      final pitch = track.applyTranspose
          ? item.transposeSemitones + (track.octaveShift * 12)
          : (track.octaveShift * 12);
      _audioEngine.setTrackPitch(trackId, pitch);
    }
    _autoSaveMusic(itemId);
  }

  @action
  Future<void> saveDraft() async {
    if (currentSetlist == null) return;
    await _musicRepository.saveSetlist(currentSetlist!);
  }

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
}
