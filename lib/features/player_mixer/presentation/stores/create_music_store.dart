import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio_engine/iaudio_engine_service.dart';
import '../../domain/entities/music.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/imusic_repository.dart';

part 'create_music_store.g.dart';

class CreateMusicStore = CreateMusicStoreBase with _$CreateMusicStore;

abstract class CreateMusicStoreBase with Store {
  final IMusicRepository _repository;
  final IAudioEngineService _audioEngine;
  final Uuid _uuid = const Uuid();

  CreateMusicStoreBase(this._repository, this._audioEngine);

  // ─── Metadata Observables ──────────────────────────────────────────

  @observable
  String title = '';

  @observable
  String artist = '';

  @observable
  String bpm = '';

  @observable
  int manualBpm = 120;

  @observable
  String key = '';

  @observable
  int timeSignatureNumerator = 4;

  @observable
  int timeSignatureDenominator = 4;

  // ─── Track List ────────────────────────────────────────────────────

  @observable
  ObservableList<Track> tracks = ObservableList<Track>();

  // ─── UI State ──────────────────────────────────────────────────────

  @observable
  bool isLoading = false;

  @observable
  bool isPlaying = false;

  @observable
  String? errorMessage;

  /// Per-track waveform peak data (populated after loadPreview).
  @observable
  ObservableMap<String, List<double>> waveformData =
      ObservableMap<String, List<double>>();

  /// Set to true after a successful save —
  /// the UI uses this to trigger navigation.
  @observable
  bool saveSuccess = false;

  // ─── Metadata Actions ─────────────────────────────────────────────

  @action
  void setTitle(String value) {
    title = value;
  }

  @action
  void setArtist(String value) {
    artist = value;
  }

  @action
  void setBpm(String value) {
    bpm = value;
  }

  @action
  void setManualBpm(int value) {
    manualBpm = value;
    bpm = value.toString();
  }

  @action
  void setKey(String value) {
    key = value;
  }

  @action
  void setTimeSignatureNumerator(int value) {
    timeSignatureNumerator = value;
  }

  @action
  void setTimeSignatureDenominator(int value) {
    timeSignatureDenominator = value;
  }

  // ─── Track Management Actions ─────────────────────────────────────

  @action
  void addTrack(String name, String filePath, {bool isClick = false}) {
    final newTrack = Track(
      id: _uuid.v4(),
      name: name,
      filePath: filePath,
      volume: 1.0,
      pan: 1.0, // Default: right
      isClick: isClick,
      order: tracks.length,
    );
    tracks.add(newTrack);
  }

  @action
  void removeTrack(String trackId) {
    tracks.removeWhere((t) => t.id == trackId);
    _reindexTrackOrder();
  }

  // ─── Mixing Actions ───────────────────────────────────────────────
  // Each action updates the local observable state AND delegates to
  // the audio engine for real-time changes.

  @action
  void updateVolume(String trackId, double newVolume) {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    tracks[index] = tracks[index].copyWith(volume: newVolume);
    _audioEngine.setTrackVolume(trackId, newVolume);
  }

  @action
  void updatePan(String trackId, double newPan) {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    tracks[index] = tracks[index].copyWith(pan: newPan);
    _audioEngine.setTrackPan(trackId, newPan);
  }

  @action
  void toggleMute(String trackId) {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    final current = tracks[index];
    final newMuted = !current.isMuted;

    // Mute and Solo are mutually exclusive —
    // activating mute must deactivate solo on the same track.
    tracks[index] = current.copyWith(
      isMuted: newMuted,
      isSolo: newMuted ? false : current.isSolo,
    );

    _audioEngine.setTrackMute(trackId, newMuted);
    if (newMuted && current.isSolo) {
      _audioEngine.setTrackSolo(trackId, false);
    }
  }

  @action
  void toggleSolo(String trackId) {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    final current = tracks[index];
    final newSolo = !current.isSolo;

    // Solo and Mute are mutually exclusive —
    // activating solo must deactivate mute on the same track.
    tracks[index] = current.copyWith(
      isSolo: newSolo,
      isMuted: newSolo ? false : current.isMuted,
    );

    _audioEngine.setTrackSolo(trackId, newSolo);
    if (newSolo && current.isMuted) {
      _audioEngine.setTrackMute(trackId, false);
    }

    // Solo group rule: if ALL tracks are now soloed, treat as none soloed
    // (normal playback for everyone).
    final allSoloed = tracks.every((t) => t.isSolo);
    if (allSoloed) {
      for (int i = 0; i < tracks.length; i++) {
        tracks[i] = tracks[i].copyWith(isSolo: false);
        _audioEngine.setTrackSolo(tracks[i].id, false);
      }
    }
  }

  // ─── Reorder Action (Drag & Drop) ─────────────────────────────────

  @action
  void reorderTracks(int oldIndex, int newIndex) {
    // ReorderableListView passes newIndex that accounts for removal,
    // so we adjust when moving downward.
    if (newIndex > oldIndex) newIndex--;

    final track = tracks.removeAt(oldIndex);
    tracks.insert(newIndex, track);

    _reindexTrackOrder();
  }

  /// Updates the `order` property of every track to match its current
  /// position in the list (0..N-1).
  void _reindexTrackOrder() {
    tracks.asMap().forEach((index, track) {
      tracks[index] = track.copyWith(order: index);
    });
  }

  // ─── Preview Actions ──────────────────────────────────────────────

  @action
  Future<void> loadAndPlayPreview() async {
    if (tracks.isEmpty) return;

    try {
      await _audioEngine.loadPreview(List<Track>.from(tracks));

      // Extract waveform peaks for each track (150 bins).
      waveformData.clear();
      for (final t in tracks) {
        final peaks = _audioEngine.getWaveformData(t.id, 150);
        if (peaks.isNotEmpty) {
          waveformData[t.id] = peaks;
        }
      }

      _audioEngine.playPreview();
      isPlaying = true;
    } catch (e) {
      errorMessage = 'Preview error: $e';
    }
  }

  @action
  void pausePreview() {
    _audioEngine.pausePreview();
    isPlaying = false;
  }

  // ─── Save Action ──────────────────────────────────────────────────

  @action
  Future<void> saveMusicConfig() async {
    // ── Validation ──
    if (title.isEmpty) {
      errorMessage = 'Song title is required';
      return;
    }
    if (artist.isEmpty) {
      errorMessage = 'Artist name is required';
      return;
    }

    int bpmInt = int.tryParse(bpm) ?? 0;
    int tsNum = timeSignatureNumerator;
    int tsDen = timeSignatureDenominator;

    // Strict validation only if NO tracks are present
    if (tracks.isEmpty) {
      if (bpmInt <= 0) {
        errorMessage = 'A valid BPM is required (since no tracks are added)';
        return;
      }
      if (tsNum <= 0 || tsDen <= 0) {
        errorMessage = 'A valid time signature is required';
        return;
      }
    } else {
      // Relaxed validation: use defaults if missing
      if (bpmInt <= 0) bpmInt = 120; // Default to 120 if invalid/empty
      if (tsNum <= 0) tsNum = 4;
      if (tsDen <= 0) tsDen = 4;
    }

    try {
      isLoading = true;
      errorMessage = null;

      // Ensure track order is up-to-date before saving
      _reindexTrackOrder();

      final music = Music(
        id: _uuid.v4(),
        title: title,
        artist: artist,
        bpm: bpmInt,
        timeSignatureNumerator: tsNum,
        timeSignatureDenominator: tsDen,
        key: key,
        tracks: List<Track>.from(tracks),
      );

      await _repository.saveMusic(music);

      saveSuccess = true;

      // Reset form on success
      _resetForm();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  void _resetForm() {
    title = '';
    artist = '';
    bpm = '';
    key = '';
    manualBpm = 120;
    timeSignatureNumerator = 4;
    timeSignatureDenominator = 4;
    tracks.clear();
  }

  /// Releases audio engine resources. Call from the widget's dispose().
  void disposeAudioEngine() {
    _audioEngine.dispose();
  }
}
