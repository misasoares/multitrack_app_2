import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:multitracks_df_pro/core/audio_engine/iaudio_engine_service.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/setlist.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/setlist_item.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/track.dart';

part 'live_performance_store.g.dart';

/// Store for the Live Performance (stage) screen.
///
/// Uses pre-rendered audio files (track freezing) for zero-latency playback via Oboe.
/// Stage mixer (volume, mute, solo) is ephemeral — never persisted to Isar.
class LivePerformanceStore = LivePerformanceStoreBase with _$LivePerformanceStore;

abstract class LivePerformanceStoreBase with Store {
  final IAudioEngineService _audioEngine;

  StreamSubscription<Duration>? _positionSubscription;

  /// Guards async callbacks from running after dispose (e.g. playPreview after user left the page).
  bool _disposed = false;

  LivePerformanceStoreBase(this._audioEngine);

  @observable
  Setlist? currentSetlist;

  @observable
  int activeSongIndex = 0;

  @observable
  bool isPlaying = false;

  @observable
  Duration currentPosition = Duration.zero;

  /// True while a song is being loaded into the engine (next/prev/goToSong or initial load).
  /// UI should disable transport and show loading feedback.
  @observable
  bool isLoadingSong = false;

  /// Returns the currently active setlist item, or null if none.
  SetlistItem? get currentItem {
    final list = currentSetlist;
    if (list == null || list.items.isEmpty) return null;
    final idx = activeSongIndex.clamp(0, list.items.length - 1);
    return list.items[idx];
  }

  /// Returns the list of tracks for the current song (for UI).
  List<Track> get currentTracks => currentItem?.originalMusic.tracks ?? const [];

  /// Resolves the file path for a track in live mode: exported WAV if show was rendered, else original.
  static String liveFilePath(SetlistItem item, Track track) {
    if (item.exportedItemDirectory != null && item.exportedItemDirectory!.isNotEmpty) {
      return '${item.exportedItemDirectory}/${track.id}.wav';
    }
    return track.filePath;
  }

  @action
  Future<void> loadSetlist(Setlist setlist) async {
    _disposed = false;
    _positionSubscription?.cancel();
    currentSetlist = setlist;
    activeSongIndex = 0;
    currentPosition = Duration.zero;
    isPlaying = false;
    isLoadingSong = true;
    try {
      await _loadCurrentSong();
      if (_disposed) return;
      _positionSubscription = _audioEngine.onPreviewPosition.listen((d) {
        if (_disposed) return;
        runInAction(() => currentPosition = d);
      });
    } finally {
      if (!_disposed) isLoadingSong = false;
    }
  }

  /// Loads only the song at [activeSongIndex] into the engine (pre-rendered paths, flat EQ, tempo 1, pitch 0).
  Future<void> _loadCurrentSong() async {
    final item = currentItem;
    if (item == null || currentSetlist == null) return;

    final tracks = item.originalMusic.tracks;
    if (tracks.isEmpty) return;

    final liveTracks = tracks.map((t) {
      final path = liveFilePath(item, t);
      return t.copyWith(filePath: path);
    }).toList();

    await _audioEngine.loadPreview(liveTracks);

    for (final t in liveTracks) {
      _audioEngine.setTrackTempo(t.id, 1.0);
      _audioEngine.setTrackPitch(t.id, 0);
    }
  }

  @action
  void togglePlay() {
    if (isPlaying) {
      _audioEngine.pausePreview();
      isPlaying = false;
    } else {
      _audioEngine.playPreview();
      isPlaying = true;
    }
  }

  @action
  void nextSong() {
    final list = currentSetlist;
    if (list == null || list.items.isEmpty) return;
    if (isLoadingSong) return;
    final wasPlaying = isPlaying;
    _audioEngine.pausePreview();
    _audioEngine.clearAllTracks();
    activeSongIndex = (activeSongIndex + 1) % list.items.length;
    currentPosition = Duration.zero;
    isLoadingSong = true;
    _loadCurrentSong().then((_) {
      if (_disposed) return;
      runInAction(() => isLoadingSong = false);
      if (wasPlaying) _audioEngine.playPreview();
    }).catchError((_, __) {
      if (!_disposed) runInAction(() => isLoadingSong = false);
    });
  }

  @action
  void prevSong() {
    final list = currentSetlist;
    if (list == null || list.items.isEmpty) return;
    if (isLoadingSong) return;
    final wasPlaying = isPlaying;
    _audioEngine.pausePreview();
    _audioEngine.clearAllTracks();
    activeSongIndex = activeSongIndex <= 0
        ? list.items.length - 1
        : activeSongIndex - 1;
    currentPosition = Duration.zero;
    isLoadingSong = true;
    _loadCurrentSong().then((_) {
      if (_disposed) return;
      runInAction(() => isLoadingSong = false);
      if (wasPlaying) _audioEngine.playPreview();
    }).catchError((_, __) {
      if (!_disposed) runInAction(() => isLoadingSong = false);
    });
  }

  /// Jumps to the song at [index] (e.g. from setlist ribbon tap). Does not change play state.
  @action
  void goToSong(int index) {
    final list = currentSetlist;
    if (list == null || list.items.isEmpty) return;
    if (isLoadingSong) return;
    final idx = index.clamp(0, list.items.length - 1);
    if (idx == activeSongIndex) return;
    final wasPlaying = isPlaying;
    _audioEngine.pausePreview();
    _audioEngine.clearAllTracks();
    activeSongIndex = idx;
    currentPosition = Duration.zero;
    isLoadingSong = true;
    _loadCurrentSong().then((_) {
      if (_disposed) return;
      runInAction(() => isLoadingSong = false);
      if (wasPlaying) _audioEngine.playPreview();
    }).catchError((_, __) {
      if (!_disposed) runInAction(() => isLoadingSong = false);
    });
  }

  /// Ephemeral: updates engine and in-memory setlist only. Does NOT persist to Isar.
  @action
  void setTrackVolume(String trackId, double volume) {
    _audioEngine.setTrackVolume(trackId, volume);
    _updateCurrentItemTrack(trackId, (t) => t.copyWith(volume: volume));
  }

  /// Ephemeral: updates engine and in-memory setlist only. Does NOT persist to Isar.
  @action
  void setTrackMute(String trackId, bool isMuted) {
    _audioEngine.setTrackMute(trackId, isMuted);
    _updateCurrentItemTrack(trackId, (t) => t.copyWith(isMuted: isMuted));
  }

  /// Ephemeral: updates engine and in-memory setlist only. Does NOT persist to Isar.
  @action
  void setTrackSolo(String trackId, bool isSolo) {
    _audioEngine.setTrackSolo(trackId, isSolo);
    _updateCurrentItemTrack(trackId, (t) => t.copyWith(isSolo: isSolo));
  }

  void _updateCurrentItemTrack(String trackId, Track Function(Track) update) {
    final setlist = currentSetlist;
    final item = currentItem;
    if (setlist == null || item == null) return;

    final tracks = item.originalMusic.tracks;
    final idx = tracks.indexWhere((t) => t.id == trackId);
    if (idx < 0) return;

    final newTracks = List<Track>.from(tracks);
    newTracks[idx] = update(tracks[idx]);

    final newMusic = item.originalMusic.copyWith(tracks: newTracks);
    final newItem = item.copyWith(originalMusic: newMusic);

    final newItems = List<SetlistItem>.from(setlist.items);
    final itemIdx = activeSongIndex.clamp(0, newItems.length - 1);
    newItems[itemIdx] = newItem;

    currentSetlist = setlist.copyWith(items: newItems);
  }

  /// Call when leaving the live performance screen (e.g. dispose).
  /// Stops playback, clears engine tracks, and cancels the position stream so no leaks occur.
  void dispose() {
    _disposed = true;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _audioEngine.pausePreview();
    _audioEngine.clearAllTracks();
  }
}
