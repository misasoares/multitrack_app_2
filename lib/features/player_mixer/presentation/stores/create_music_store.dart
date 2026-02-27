import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio_engine/iaudio_engine_service.dart';
import '../../domain/entities/eq_band_data.dart';
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

  /// Yields one frame so the UI can render (spinner, animations)
  /// before heavy synchronous work begins.
  Future<void> _yieldFrame() => Future.delayed(Duration.zero);

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

  @observable
  DateTime? originalCreatedAt;

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

  @observable
  bool isProcessingAudio = false;

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

  // ─── Timeline State ───────────────────────────────────────────────

  @observable
  Duration currentPosition = Duration.zero;

  @computed
  Duration get totalDuration {
    if (tracks.isEmpty) return Duration.zero;
    return tracks.map((t) => t.duration).reduce((a, b) => a > b ? a : b);
  }

  /// Unified waveform data (merged peaks from all tracks)
  @computed
  List<double> get unifiedWaveform {
    if (tracks.isEmpty) return [];

    // If no waveform data loaded yet, return empty
    if (waveformData.isEmpty) return [];

    // Combine all track waveforms into one.
    // Logic: normalize all to same length (150 bins) and take max at each point.
    // In a real DAW, this would be complex mixing. Here we simplify for UI.
    const int numBins = 150;
    final List<double> combined = List.filled(numBins, 0.0);

    for (final track in tracks) {
      final peaks = waveformData[track.id];
      if (peaks != null && peaks.isNotEmpty) {
        final length = peaks.length < numBins ? peaks.length : numBins;
        for (int i = 0; i < length; i++) {
          if (peaks[i] > combined[i]) {
            combined[i] = peaks[i];
          }
        }
      }
    }
    return combined;
  }

  ReactionDisposer? _tickerReaction;

  // ─── Track Management Actions ─────────────────────────────────────

  @action
  Future<void> importTracks(List<({String name, String path})> files) async {
    if (files.isEmpty) return;

    isProcessingAudio = true;
    await _yieldFrame(); // Let Flutter render the spinner first
    try {
      final player = AudioPlayer();

      for (final file in files) {
        Duration duration = Duration.zero;
        try {
          await player.setFilePath(file.path);
          duration = player.duration ?? Duration.zero;
        } catch (e) {
          debugPrint('Error getting duration for ${file.path}: $e');
        }

        final newTrack = Track(
          id: _uuid.v4(),
          name: file.name,
          filePath: file.path,
          volume: 1.0,
          pan: 1.0,
          isClick: file.name.toLowerCase().contains('click'),
          order: tracks.length,
          duration: duration,
        );
        tracks.add(newTrack);

        await _yieldFrame(); // Breathe between tracks
      }
      await player.dispose();

      // Auto-load preview data to update timeline
      await _reloadPreviewData();
    } finally {
      isProcessingAudio = false;
    }
  }

  @action
  Future<void> addTrack(
    String name,
    String filePath, {
    bool isClick = false,
  }) async {
    isProcessingAudio = true;
    await _yieldFrame(); // Let Flutter render the spinner first
    try {
      // Attempt to get duration using a temporary player
      Duration duration = Duration.zero;
      try {
        final player = AudioPlayer(); // from just_audio
        await player.setFilePath(filePath);
        duration = player.duration ?? Duration.zero;
        await player.dispose();
      } catch (e) {
        debugPrint('Error getting duration for $filePath: $e');
      }

      final newTrack = Track(
        id: _uuid.v4(),
        name: name,
        filePath: filePath,
        volume: 1.0,
        pan: 0.0, // Default: center
        isClick: isClick,
        order: tracks.length,
        duration: duration,
      );
      tracks.add(newTrack);

      // Auto-load preview data to update timeline
      await _reloadPreviewData();
    } finally {
      isProcessingAudio = false;
    }
  }

  @action
  Future<void> removeTrack(String trackId) async {
    tracks.removeWhere((t) => t.id == trackId);
    _reindexTrackOrder();

    // Update timeline
    if (tracks.isNotEmpty) {
      isProcessingAudio = true;
      await _yieldFrame(); // Let Flutter render the spinner first
      try {
        await _reloadPreviewData();
      } finally {
        isProcessingAudio = false;
      }
    } else {
      waveformData.clear();
      currentPosition = Duration.zero;
      _stopTicker();
    }
  }

  // ─── Mixing Actions ───────────────────────────────────────────────
  // ... (Mixing actions unchanged)

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

    tracks[index] = current.copyWith(
      isSolo: newSolo,
      isMuted: newSolo ? false : current.isMuted,
    );

    _audioEngine.setTrackSolo(trackId, newSolo);
    if (newSolo && current.isMuted) {
      _audioEngine.setTrackMute(trackId, false);
    }

    final allSoloed = tracks.every((t) => t.isSolo);
    if (allSoloed) {
      for (int i = 0; i < tracks.length; i++) {
        tracks[i] = tracks[i].copyWith(isSolo: false);
        _audioEngine.setTrackSolo(tracks[i].id, false);
      }
    }
  }

  /// Updates an EQ band in memory and sends to C++ engine.
  /// **No database call** — persisted only on global Save.
  @action
  void updateTrackEq(String trackId, EqBandData band) {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    final track = tracks[index];
    final updatedBands = List<EqBandData>.from(track.eqBands);

    // Upsert by bandIndex
    final existing = updatedBands.indexWhere(
      (b) => b.bandIndex == band.bandIndex,
    );
    if (existing != -1) {
      updatedBands[existing] = band;
    } else {
      updatedBands.add(band);
    }

    // 1. Update in-memory state
    tracks[index] = track.copyWith(eqBands: updatedBands);

    // 2. Send to C++ engine (FFI) — NO database call
    _audioEngine.setTrackEq(
      trackId: trackId,
      bandIndex: band.bandIndex,
      filterType: band.type.index,
      frequency: band.frequency,
      gain: band.gain,
      q: band.q,
    );
  }

  // ─── Reorder Action (Drag & Drop) ─────────────────────────────────
  // ... (Reorder actions unchanged)

  @action
  void reorderTracks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    final track = tracks.removeAt(oldIndex);
    tracks.insert(newIndex, track);

    _reindexTrackOrder();
  }

  void _reindexTrackOrder() {
    tracks.asMap().forEach((index, track) {
      tracks[index] = track.copyWith(order: index);
    });
  }

  // ─── Preview Actions ──────────────────────────────────────────────

  /// Loads tracks into engine and extracts waveforms, without starting playback.
  Future<void> _reloadPreviewData() async {
    try {
      await _audioEngine.loadPreview(List<Track>.from(tracks));
      await _yieldFrame(); // Breathe after heavy FFI decode

      // Extract waveform peaks for each track (150 bins).
      waveformData.clear();
      for (final t in tracks) {
        final peaks = await _audioEngine.getWaveformData(t.id, 150);
        if (peaks.isNotEmpty) {
          waveformData[t.id] = peaks;
        }
        await _yieldFrame(); // Yield between per-track waveform extraction
      }
      // Restore position if valid
      await _audioEngine.seekTo(currentPosition);
    } catch (e) {
      errorMessage = 'Error loading preview: $e';
    }
  }

  @action
  Future<void> playPreview() async {
    if (tracks.isEmpty) return;

    // If we haven't loaded waveforms yet, strictly we should load.
    // But since we auto-load on add/remove, we assume engine is ready.
    // However, to be safe, if waveformData.isEmpty, we force reload.
    if (waveformData.isEmpty) {
      isProcessingAudio = true;
      await _yieldFrame(); // Let Flutter render the spinner first
      await _reloadPreviewData();
      isProcessingAudio = false;
    } else {
      // Ensure engine is at the correct position before playing
      try {
        await _audioEngine.seekTo(currentPosition);
      } catch (e) {
        debugPrint('Seek error before play: $e');
      }
    }

    try {
      await _audioEngine.play();
      isPlaying = true;
      _startTicker();
    } catch (e) {
      errorMessage = 'Playback error: $e';
    }
  }

  @action
  void pausePreview() {
    _audioEngine.pausePreview();
    isPlaying = false;
    _stopTicker();
  }

  @action
  Future<void> seekTo(Duration position) async {
    currentPosition = position;
    if (isPlaying) {
      await _audioEngine.seekTo(position);
    }
  }

  void _startTicker() {
    _stopTicker();
    _tickerReaction = reaction((_) => isPlaying, (playing) {
      // Logic to update position roughly every 16ms or so
      // Since logic is complex in mobx reaction, using a Stream/Timer is easier
    });

    // Simple timer for updates
    // In a real app we'd sync with audio engine's reported position
    // Here we simulate progress
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (isPlaying) {
        final newPos = currentPosition + const Duration(milliseconds: 50);
        if (newPos >= totalDuration && totalDuration > Duration.zero) {
          currentPosition = totalDuration;
          pausePreview();
          currentPosition = Duration.zero; // Reset on finish
        } else {
          currentPosition = newPos;
        }
      }
    });
  }

  Timer? _tickerTimer;

  void _stopTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  // ─── Edit Mode State ──────────────────────────────────────────────
  @observable
  String? editingMusicId;

  @action
  Future<void> loadMusic(Music music) async {
    _resetForm(); // Clear any previous state

    editingMusicId = music.id;
    title = music.title;
    artist = music.artist;
    bpm = music.bpm.toString();
    manualBpm = music.bpm;
    key = music.key;
    timeSignatureNumerator = music.timeSignatureNumerator;
    timeSignatureDenominator = music.timeSignatureDenominator;
    originalCreatedAt = music.createdAt;

    // Recalculate durations since not persisted
    isProcessingAudio = true;
    await _yieldFrame(); // Let Flutter render the spinner first
    try {
      final player = AudioPlayer();
      final loadedTracks = <Track>[];

      for (final t in music.tracks) {
        Duration duration = t.duration;
        // Only recalculate if duration is missing (legacy data)
        if (duration <= Duration.zero) {
          try {
            await player.setFilePath(t.filePath);
            duration = player.duration ?? Duration.zero;
          } catch (e) {
            debugPrint('Error getting duration for ${t.filePath}: $e');
          }
        }
        loadedTracks.add(t.copyWith(duration: duration));

        await _yieldFrame(); // Breathe between tracks
      }
      await player.dispose();

      tracks = ObservableList.of(loadedTracks);

      // Auto-load preview for the timeline
      if (tracks.isNotEmpty) {
        await _reloadPreviewData();

        // Apply saved EQ to C++ engine BEFORE play is allowed
        for (final track in tracks) {
          for (final band in track.eqBands) {
            _audioEngine.setTrackEq(
              trackId: track.id,
              bandIndex: band.bandIndex,
              filterType: band.type.index,
              frequency: band.frequency,
              gain: band.gain,
              q: band.q,
            );
          }
        }
      }
    } finally {
      isProcessingAudio = false;
    }
  }

  // ─── Save Action ──────────────────────────────────────────────────
  // ... (Save logic unchanged)

  @action
  Future<void> saveMusicConfig() async {
    // ... validation ...
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
      if (bpmInt <= 0) bpmInt = 120;
      if (tsNum <= 0) tsNum = 4;
      if (tsDen <= 0) tsDen = 4;
    }

    try {
      isLoading = true;
      errorMessage = null;
      await _yieldFrame(); // Let Flutter render the loading state first

      _reindexTrackOrder();

      final music = Music(
        id: editingMusicId ?? _uuid.v4(), // Use existing ID if editing
        title: title,
        artist: artist,
        bpm: bpmInt,
        timeSignatureNumerator: tsNum,
        timeSignatureDenominator: tsDen,
        key: key,
        tracks: List<Track>.from(tracks),
        createdAt: editingMusicId != null ? originalCreatedAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.saveMusic(music);

      saveSuccess = true;
      await _yieldFrame(); // Let MobX reaction fire (Navigator.pop) before reset

      _resetForm();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  void _resetForm() {
    editingMusicId = null;
    saveSuccess = false; // Reset success flag
    title = '';
    artist = '';
    bpm = '';
    key = '';
    manualBpm = 120;
    timeSignatureNumerator = 4;
    timeSignatureDenominator = 4;
    tracks.clear();
    currentPosition = Duration.zero;
    _stopTicker();
    waveformData.clear();
  }

  /// Releases audio engine resources. Call from the widget's dispose().
  void disposeAudioEngine() {
    _stopTicker();
    _tickerReaction?.call();
    _audioEngine.dispose();
  }
}
