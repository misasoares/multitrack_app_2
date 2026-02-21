import 'package:mobx/mobx.dart';
import '../../domain/entities/setlist.dart';
import '../../domain/entities/setlist_item.dart';
import '../../domain/entities/eq_band_data.dart';
import '../../../../../core/audio_engine/iaudio_engine_service.dart';

part 'setlist_config_store.g.dart';

class SetlistConfigStore = SetlistConfigStoreBase with _$SetlistConfigStore;

abstract class SetlistConfigStoreBase with Store {
  final IAudioEngineService _audioEngine;

  SetlistConfigStoreBase(this._audioEngine);

  @observable
  Setlist? currentSetlist;

  @observable
  String? playingItemId;

  @observable
  bool isPlaying = false;

  Stream<Duration> get previewPosition => _audioEngine.onPreviewPosition;

  @observable
  bool isLoading = false;

  @computed
  Duration get totalDuration {
    if (currentSetlist == null || currentSetlist!.items.isEmpty) {
      return Duration.zero;
    }
    // Sum of the longest track in each music
    return currentSetlist!.items.fold(Duration.zero, (prev, item) {
      if (item.originalMusic.tracks.isEmpty) return prev;
      final musicDuration = item.originalMusic.tracks
          .map((t) => t.duration)
          .reduce((a, b) => a > b ? a : b);
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
      final updatedItem = currentSetlist!.items[index].copyWith(
        transposeSemitones: semitones,
      );
      final newItems = List<SetlistItem>.from(currentSetlist!.items);
      newItems[index] = updatedItem;
      currentSetlist = currentSetlist!.copyWith(items: newItems);

      if (playingItemId == itemId) {
        // For now, re-apply mastering to hear the change
        _applyMastering(updatedItem);
      }
    }
  }

  @action
  void updateTransposableTracks(String itemId, List<String> trackIds) {
    final index = currentSetlist!.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = currentSetlist!.items[index];
    final updated = item.copyWith(transposableTrackIds: trackIds);

    final newItems = List<SetlistItem>.from(currentSetlist!.items);
    newItems[index] = updated;
    currentSetlist = currentSetlist!.copyWith(items: newItems);

    // Re-apply mastering to respond to the change
    _applyMastering(updated);
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
        frequency: updatedBand.frequency,
        gain: updatedBand.gain,
        q: updatedBand.q,
      );
    }
  }

  @action
  Future<void> saveDraft() async {
    // Stop playback if playing
    if (isPlaying) {
      await _audioEngine.pause();
      isPlaying = false;
    }

    // TODO: Persist to DB
    // setlistRepository.save(currentSetlist!);
  }

  @action
  Future<void> seek(Duration position) async {
    await _audioEngine.seekTo(position);
  }

  @observable
  String? previewLoadingItemId;

  @action
  Future<void> togglePreview(String itemId) async {
    // If clicking the currently playing item, just toggle pause/stop
    if (playingItemId == itemId && isPlaying) {
      await _audioEngine.pause();
      isPlaying = false;
      return;
    }

    // If clicking a different item or starting playback
    if (playingItemId != itemId) {
      // Stop current
      if (isPlaying) {
        await _audioEngine.pause();
        isPlaying = false;
      }

      // Clear old playing ID to remove its timeline immediately
      playingItemId = null;

      // Set loading state
      previewLoadingItemId = itemId;

      try {
        final item = currentSetlist!.items.firstWhere((i) => i.id == itemId);

        // Simulate a small delay if needed or just wait for load
        // await Future.delayed(Duration(milliseconds: 100));

        await _audioEngine.loadPreview(item.originalMusic.tracks);
        _applyMastering(item); // Apply tempo/pitch/volume

        // Ready to play
        playingItemId = itemId;
        _audioEngine.playPreview();
        isPlaying = true;
      } catch (e) {
        // Handle error, maybe show snackbar?
        print('Error loading preview: $e');
      } finally {
        previewLoadingItemId = null;
      }
    } else {
      // Case: playingItemId == itemId but isPlaying is false (paused)
      // Just resume
      _audioEngine.playPreview();
      isPlaying = true;
    }
  }

  void _applyMastering(SetlistItem item) {
    for (final track in item.originalMusic.tracks) {
      _audioEngine.setTrackTempo(track.id, item.tempoFactor);

      if (item.transposableTrackIds.contains(track.id)) {
        _audioEngine.setTrackPitch(track.id, item.transposeSemitones);
      } else {
        _audioEngine.setTrackPitch(track.id, 0);
      }

      _audioEngine.setTrackVolume(track.id, track.volume);
    }

    // Apply Master Volume (using item volume as master volume for the mix)
    _audioEngine.setMasterVolume(item.volume);

    // Apply Master EQ
    for (final band in item.masterEqBands) {
      _audioEngine.setMasterEq(
        bandIndex: band.bandIndex,
        frequency: band.frequency,
        gain: band.gain,
        q: band.q,
      );
    }
  }

  void dispose() {
    _audioEngine.pause();
    isPlaying = false;
    currentSetlist = null;
    playingItemId = null;
  }
}
