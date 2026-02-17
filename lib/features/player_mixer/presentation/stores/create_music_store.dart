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
      pan: 0.0,
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
    tracks[index] = current.copyWith(isMuted: newMuted);
    _audioEngine.setTrackMute(trackId, newMuted);
  }

  @action
  void toggleSolo(String trackId) {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    final current = tracks[index];
    final newSolo = !current.isSolo;
    tracks[index] = current.copyWith(isSolo: newSolo);
    _audioEngine.setTrackSolo(trackId, newSolo);
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

    final bpmInt = int.tryParse(bpm) ?? 0;
    if (bpmInt <= 0) {
      errorMessage = 'A valid BPM is required';
      return;
    }

    if (timeSignatureNumerator <= 0 || timeSignatureDenominator <= 0) {
      errorMessage = 'A valid time signature is required';
      return;
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
        timeSignatureNumerator: timeSignatureNumerator,
        timeSignatureDenominator: timeSignatureDenominator,
        key: key,
        tracks: List<Track>.from(tracks),
      );

      await _repository.saveMusic(music);

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
