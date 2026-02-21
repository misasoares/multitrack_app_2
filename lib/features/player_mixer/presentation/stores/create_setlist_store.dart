import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio_engine/iaudio_engine_service.dart';
import '../../domain/entities/music.dart';
import '../../domain/entities/setlist.dart';
import '../../domain/entities/setlist_item.dart';
import '../../domain/repositories/imusic_repository.dart';

part 'create_setlist_store.g.dart';

class CreateSetlistStore = CreateSetlistStoreBase with _$CreateSetlistStore;

abstract class CreateSetlistStoreBase with Store {
  final IMusicRepository _repository;
  final IAudioEngineService _audioEngine;
  final Uuid _uuid = const Uuid();

  CreateSetlistStoreBase(this._repository, this._audioEngine);

  @observable
  ObservableList<SetlistItem> selectedItems = ObservableList<SetlistItem>();

  @observable
  String name = '';

  @observable
  String description = '';

  @observable
  bool isLoading = false;

  @observable
  String? existingId;

  @observable
  String? errorMessage;

  @observable
  bool isPlaying = false;

  @observable
  int currentItemIndex = 0;

  @observable
  Duration currentItemPosition = Duration.zero;

  @observable
  bool saveSuccess = false;

  @observable
  Setlist? savedSetlist;

  // ─── Computed ──────────────────────────────────────────────────────

  @computed
  Duration get totalDuration {
    if (selectedItems.isEmpty) return Duration.zero;
    // Sum of the longest track in each music
    return selectedItems.fold(Duration.zero, (prev, item) {
      if (item.originalMusic.tracks.isEmpty) return prev;
      final musicDuration = item.originalMusic.tracks
          .map((t) => t.duration)
          .reduce((a, b) => a > b ? a : b);
      return prev + musicDuration;
    });
  }

  // ─── Actions ───────────────────────────────────────────────────────

  @action
  void setName(String value) {
    name = value;
  }

  @action
  void setDescription(String value) {
    description = value;
  }

  @action
  void initFromSetlist(Setlist setlist) {
    existingId = setlist.id;
    name = setlist.name;
    description = setlist.description;
    selectedItems = ObservableList<SetlistItem>.of(setlist.items);
  }

  @action
  void addMusic(Music music) {
    // Create a SetlistItem from the selected music
    final item = SetlistItem.fromMusic(music);
    selectedItems.add(item);
  }

  @action
  void removeMusic(int index) {
    if (index >= 0 && index < selectedItems.length) {
      selectedItems.removeAt(index);
    }
  }

  @action
  void reorderMusic(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = selectedItems.removeAt(oldIndex);
    selectedItems.insert(newIndex, item);
  }

  @action
  Future<void> saveSetlist() async {
    if (name.isEmpty) {
      errorMessage = 'Setlist name is required';
      return;
    }

    saveSuccess = false;

    try {
      isLoading = true;
      errorMessage = null;

      final setlist = Setlist(
        id: existingId ?? _uuid.v4(),
        name: name,
        description: description,
        items: selectedItems.toList(),
        status: SetlistStatus.draft,
      );

      await _repository.saveSetlist(setlist);
      savedSetlist = setlist;
      saveSuccess = true;
    } catch (e) {
      errorMessage = 'Failed to save setlist: $e';
    } finally {
      isLoading = false;
    }
  }

  // ─── Playback Logic ───────────────────────────────────────────────

  Timer? _playbackTicker;

  @action
  Future<void> play() async {
    if (selectedItems.isEmpty) return;

    // Resume or Start from beginning of current track
    try {
      if (!isPlaying) {
        // If starting, ensure current music is loaded
        await _loadCurrentItemToEngine();
        await _audioEngine.play();
        isPlaying = true;
        _startTicker();
      } else {
        await _audioEngine.play();
      }
    } catch (e) {
      errorMessage = 'Playback failed: $e';
      isPlaying = false;
    }
  }

  @action
  Future<void> pause() async {
    isPlaying = false;
    _stopTicker();
    await _audioEngine.pause();
  }

  @action
  Future<void> stop() async {
    isPlaying = false;
    _stopTicker();
    currentItemIndex = 0;
    currentItemPosition = Duration.zero;
    await _audioEngine.pause(); // Or stop/reset if available
  }

  @action
  Future<void> skipToNext() async {
    if (currentItemIndex < selectedItems.length - 1) {
      await _audioEngine.pause();
      currentItemIndex++;
      currentItemPosition = Duration.zero;
      await play(); // Will reload engine with next track
    } else {
      await stop();
    }
  }

  @action
  Future<void> skipToPrevious() async {
    if (currentItemPosition.inSeconds > 3) {
      // Restart current song
      await _audioEngine.seekTo(Duration.zero);
      currentItemPosition = Duration.zero;
    } else if (currentItemIndex > 0) {
      await _audioEngine.pause();
      currentItemIndex--;
      currentItemPosition = Duration.zero;
      await play();
    }
  }

  Future<void> _loadCurrentItemToEngine() async {
    final item = selectedItems[currentItemIndex];
    // Load tracks into engine
    await _audioEngine.loadPreview(item.originalMusic.tracks);

    // Future: Apply volume, pan, etc. from SetlistItem
    // For now, we just load the tracks.

    // Seek to current position (if resumed)
    if (currentItemPosition > Duration.zero) {
      await _audioEngine.seekTo(currentItemPosition);
    }
  }

  void _startTicker() {
    _stopTicker();
    _playbackTicker = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (isPlaying) {
        currentItemPosition += const Duration(milliseconds: 100);

        // Check for end of song (auto-advance)
        final currentMusicDuration = _getItemDuration(
          selectedItems[currentItemIndex],
        );
        if (currentItemPosition >= currentMusicDuration) {
          skipToNext();
        }
      }
    });
  }

  void _stopTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = null;
  }

  Duration _getItemDuration(SetlistItem item) {
    if (item.originalMusic.tracks.isEmpty) return Duration.zero;
    return item.originalMusic.tracks
        .map((t) => t.duration)
        .reduce((a, b) => a > b ? a : b);
  }

  void dispose() {
    _stopTicker();
    // Don't dispose audio engine here if it's injected singleton,
    // but if it's scoped, then yes. Assuming scoped or handle externally.
    // _audioEngine.dispose();
  }
}
