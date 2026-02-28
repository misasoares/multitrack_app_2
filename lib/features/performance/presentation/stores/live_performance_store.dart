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

  /// True while the user is dragging the waveform playhead (scrubbing).
  /// Position updates from the engine are ignored so the UI is not overwritten.
  @observable
  bool isScrubbing = false;

  /// Linear peak per track (0.0 to 1.0) for VU meters. Updated by _peakTimer when isPlaying.
  @observable
  Map<String, double> trackPeaks = {};

  Timer? _peakTimer;

  /// When true, the bottom mixer panel (tracks + metronome + master) is visible.
  @observable
  bool isMixerVisible = false;

  /// Master output volume (0.0 to 1.0). Synced to native.
  @observable
  double masterVolume = 1.0;

  /// Metronome BPM. Synced to native.
  @observable
  double metronomeBpm = 120.0;

  /// Metronome click volume (0.0 to 1.0). Synced to native.
  @observable
  double metronomeVolume = 0.8;

  /// Metronome pan (-1 = left, 0 = center, 1 = right). Synced to native.
  @observable
  double metronomePan = -1.0;

  /// When true, synthetic click plays (only when VS is paused/stopped). Synced to native.
  @observable
  bool isMetronomePlaying = false;

  /// Last 4 tap timestamps (ms since epoch) for Tap Tempo.
  final List<int> _tapTempoTimestamps = [];
  static const int _tapTempoMaxTaps = 4;

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
    _peakTimer?.cancel();
    _peakTimer = null;
    _positionSubscription?.cancel();
    currentSetlist = setlist;
    activeSongIndex = 0;
    currentPosition = Duration.zero;
    isPlaying = false;
    trackPeaks = {};
    isLoadingSong = true;
    try {
      // Same rite of passage as nextSong/prevSong: pause + clear so C++ is in a known state
      // before loading. clearAllTracks() is synchronous in C++ so new tracks are not wiped.
      _audioEngine.pausePreview();
      _audioEngine.clearAllTracks();
      await _loadCurrentSong();
      if (_disposed) return;
      _positionSubscription = _audioEngine.onPreviewPosition.listen((d) {
        if (_disposed) return;
        if (!isScrubbing) runInAction(() => currentPosition = d);
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
      _peakTimer?.cancel();
      _peakTimer = null;
      trackPeaks = {};
    } else {
      // Regra de Ouro: ao iniciar a música, desligar o metrônomo.
      isMetronomePlaying = false;
      _audioEngine.setMetronomePlaying(false);
      _audioEngine.playPreview();
      isPlaying = true;
      _startPeakTimer();
    }
  }

  void _startPeakTimer() {
    _peakTimer?.cancel();
    _peakTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (_disposed) return;
      final tracks = currentTracks;
      if (tracks.isEmpty) return;
      runInAction(() {
        final m = Map<String, double>.from(trackPeaks);
        for (final t in tracks) {
          final raw = _audioEngine.getTrackPeak(t.id);
          final prev = m[t.id] ?? 0.0;
          final smoothed = raw > prev
              ? prev + (raw - prev) * 0.42
              : prev * 0.88;
          m[t.id] = smoothed < 0.005 ? 0.0 : smoothed.clamp(0.0, 1.0);
        }
        trackPeaks = m;
      });
    });
  }

  /// Seeks to [position] and updates the engine (C++ playhead + ring buffer).
  /// Safe to call when paused; scrubbing is only allowed when [isPlaying] is false.
  @action
  void seekToPosition(Duration position) {
    currentPosition = position;
    _audioEngine.seekTo(position);
  }

  /// Called when the user starts dragging the waveform. Stops applying engine position to UI.
  @action
  void startScrubbing() {
    isScrubbing = true;
  }

  /// Called on each drag move. Updates only [currentPosition] (UI); does NOT call C++.
  @action
  void updateScrubPosition(Duration position) {
    currentPosition = position;
  }

  /// Called when the user releases the drag. Applies [currentPosition] to the engine once.
  @action
  void endScrubbing() {
    isScrubbing = false;
    _audioEngine.seekTo(currentPosition);
  }

  @action
  void nextSong() {
    if (isPlaying) return;
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
    if (isPlaying) return;
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

  @action
  void goToSong(int index) {
    if (isPlaying) return;
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

  /// Toggle mixer panel visibility (timeline expands when hidden).
  @action
  void toggleMixerVisible() {
    isMixerVisible = !isMixerVisible;
  }

  /// Master volume (0.0 to 1.0). Synced to native.
  @action
  void setMasterVolume(double volume) {
    masterVolume = volume.clamp(0.0, 1.0);
    _audioEngine.setMasterVolume(masterVolume);
  }

  /// Metronome: BPM, volume, pan, playing. All synced to native.
  @action
  void setMetronomeBpm(double bpm) {
    metronomeBpm = bpm.clamp(20.0, 300.0);
    _audioEngine.setMetronomeBpm(metronomeBpm);
  }

  @action
  void setMetronomeVolume(double volume) {
    metronomeVolume = volume.clamp(0.0, 1.0);
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

  /// Tap Tempo: record tap, compute average interval from last 4 taps, set metronomeBpm = 60000/avgMs.
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
    _peakTimer?.cancel();
    _peakTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _audioEngine.pausePreview();
    _audioEngine.clearAllTracks();
  }
}
