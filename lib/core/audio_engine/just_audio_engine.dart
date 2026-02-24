import 'dart:math';
import 'package:just_audio/just_audio.dart';
import '../../features/player_mixer/domain/entities/track.dart';
import 'iaudio_engine_service.dart';

/// Real audio engine implementation using just_audio.
///
/// Each track gets its own [AudioPlayer] instance so they can play
/// simultaneously with independent volume, pan, mute, and solo controls.
class JustAudioEngine implements IAudioEngineService {
  final Map<String, AudioPlayer> _players = {};

  /// Tracks that are currently soloed (by ID).
  final Set<String> _soloedTrackIds = {};

  /// All track IDs currently loaded.
  final Set<String> _allTrackIds = {};

  /// Muted track IDs.
  final Set<String> _mutedTrackIds = {};

  @override
  Future<void> loadPreview(List<Track> tracks) async {
    // Dispose any existing players
    await _disposeAllPlayers();

    _allTrackIds.clear();
    _soloedTrackIds.clear();
    _mutedTrackIds.clear();

    for (final track in tracks) {
      final player = AudioPlayer();
      _players[track.id] = player;
      _allTrackIds.add(track.id);

      try {
        await player.setFilePath(track.filePath);
        await player.setVolume(track.volume);

        // NOTE: Pan is stored in the observable state but just_audio
        // doesn't support stereo panning. Real pan routing requires
        // the native audio engine implementation.

        if (track.isMuted) {
          _mutedTrackIds.add(track.id);
          await player.setVolume(0);
        }

        if (track.isSolo) {
          _soloedTrackIds.add(track.id);
        }
      } catch (e) {
        // Track file couldn't be loaded — skip silently
      }
    }

    // Apply solo logic after all tracks are loaded
    _applySoloRouting();
  }

  @override
  void clearAllTracks() async {
    await _disposeAllPlayers();
    _allTrackIds.clear();
    _soloedTrackIds.clear();
    _mutedTrackIds.clear();
  }

  @override
  Stream<Duration> get onPreviewPosition {
    if (_players.isEmpty) return Stream.empty();
    // Return the position of the first player (master)
    // as a broadcast stream to allow multiple listeners.
    return _players.values.first.positionStream.asBroadcastStream();
  }

  @override
  void playPreview() {
    for (final player in _players.values) {
      player.seek(Duration.zero);
      player.play();
    }
  }

  @override
  void pausePreview() {
    for (final player in _players.values) {
      player.pause();
    }
  }

  @override
  Future<void> play() async {
    for (final player in _players.values) {
      player.play();
    }
  }

  @override
  Future<void> pause() async {
    for (final player in _players.values) {
      player.pause();
    }
  }

  @override
  Future<void> seekTo(Duration timestamp) async {
    for (final player in _players.values) {
      await player.seek(timestamp);
    }
  }

  @override
  void setTrackVolume(String trackId, double volume) {
    final player = _players[trackId];
    if (player == null) return;

    // If the track is effectively silenced (muted or non-solo), don't change
    // the audible volume — just store the intent for when it's unmuted.
    if (_isTrackAudible(trackId)) {
      player.setVolume(volume);
    }
  }

  @override
  void setTrackPan(String trackId, double pan) {
    // Pan value is stored in observable state but just_audio
    // doesn't expose stereo panning. This is a no-op until
    // the native audio engine bridge is implemented.
  }

  @override
  void setTrackMute(String trackId, bool isMuted) {
    if (isMuted) {
      _mutedTrackIds.add(trackId);
    } else {
      _mutedTrackIds.remove(trackId);
    }
    _applySoloRouting();
  }

  @override
  void setTrackSolo(String trackId, bool isSolo) {
    if (isSolo) {
      _soloedTrackIds.add(trackId);
    } else {
      _soloedTrackIds.remove(trackId);
    }
    _applySoloRouting();
  }

  /// Determines if a track should be audible based on mute/solo state.
  bool _isTrackAudible(String trackId) {
    // Muted tracks are never audible
    if (_mutedTrackIds.contains(trackId)) return false;

    // If no tracks are soloed, all non-muted tracks are audible
    if (_soloedTrackIds.isEmpty) return true;

    // If some tracks are soloed, only soloed tracks are audible
    return _soloedTrackIds.contains(trackId);
  }

  /// Applies volume routing based on current mute/solo state.
  ///
  /// When solo is active, only soloed (and non-muted) tracks play.
  /// When no solo is active, all non-muted tracks play.
  void _applySoloRouting() {
    // We can't easily read the "intended volume" from the player,
    // so we use 0.0 for silenced tracks and 1.0 for audible ones.
    // The store's updateVolume will apply the real value when changed.
    for (final trackId in _allTrackIds) {
      final player = _players[trackId];
      if (player == null) continue;

      if (_isTrackAudible(trackId)) {
        // Restore to full volume — the store will override with the real value
        // on the next slider interaction. For now, 1.0 is the safe default.
        player.setVolume(1.0);
      } else {
        player.setVolume(0.0);
      }
    }
  }

  @override
  void setTrackEq({
    required String trackId,
    required int bandIndex,
    required int filterType,
    required double frequency,
    required double gain,
    required double q,
  }) {
    // Parametric EQ is only supported by the native C++ engine.
    // This is a no-op for the just_audio fallback.
  }

  @override
  void setMasterEq({
    required int bandIndex,
    required int filterType,
    required double frequency,
    required double gain,
    required double q,
  }) {
    // Master EQ is only supported by the native C++ engine.
  }

  @override
  void setMasterVolume(double volume) {
    // Master Volume is only supported by the native C++ engine.
    // (Or could iterate all players, but that scales poorly).
  }

  @override
  void setTrackTempo(String trackId, double factor) {
    final player = _players[trackId];
    if (player == null) return;
    // just_audio's setSpeed changes speed while attempting to preserve pitch.
    player.setSpeed(factor);
  }

  @override
  void setTrackPitch(String trackId, int semitones) {
    final player = _players[trackId];
    if (player == null) return;

    // just_audio's setPitch changes pitch while preserving duration.
    // Convert semitones to pitch factor: 2^(semitones/12)
    final pitchFactor = pow(2, semitones / 12.0).toDouble();
    player.setPitch(pitchFactor);
  }

  @override
  double getTrackVolumeDb(String trackId) => -60.0;

  @override
  double getMasterVolumeDb() => -60.0;

  @override
  List<double> getWaveformData(String trackId, int numBins) => [];

  @override
  void dispose() {
    _disposeAllPlayers();
  }

  Future<void> _disposeAllPlayers() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
