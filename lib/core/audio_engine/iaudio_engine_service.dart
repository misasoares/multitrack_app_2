import '../../features/player_mixer/domain/entities/track.dart';

abstract class IAudioEngineService {
  // ─── Playback ──────────────────────────────────────────────────────

  /// Plays the current audio from the last seek position.
  Future<void> play();

  /// Pauses the current audio without resetting the position.
  Future<void> pause();

  /// Seeks to a specific [timestamp] in the audio timeline.
  Future<void> seekTo(Duration timestamp);

  // ─── Preview ───────────────────────────────────────────────────────

  /// Loads a list of [tracks] into the native engine memory for preview.
  ///
  /// This should decode the audio files and prepare audio buffers.
  /// Call this before [playPreview]. If tracks are already loaded,
  /// this should release the previous buffers before loading new ones.
  Future<void> loadPreview(List<Track> tracks);

  /// Clears all tracks from the audio engine.
  /// This is used to reset the engine state before loading a new set of tracks.
  void clearAllTracks();

  /// Starts playing the loaded preview from the current position.

  /// Starts playing the loaded preview from the current position.
  void playPreview();

  /// Pauses the preview playback without releasing the loaded buffers.
  void pausePreview();

  /// Stream of current playback position for the preview.
  ///
  /// This should emit regular updates (e.g., every 16ms or 30ms)
  /// while the preview is playing.
  Stream<Duration> get onPreviewPosition;

  // ─── Real-Time Mixing ─────────────────────────────────────────────

  /// Sets the playback volume for a specific track.
  ///
  /// [trackId] is the unique identifier for the track.
  /// [volume] is a value between 0.0 (silent) and 1.0 (max).
  ///
  /// **CRITICAL IMPLEMENTATION REQUIREMENT:**
  /// The native implementation **MUST** apply "Gain Smoothing"
  /// (linear interpolation over ~50ms) when changing the gain value.
  /// Directly setting the gain without smoothing will cause audible
  /// audio peaks and clicks, which is unacceptable for a professional
  /// audio application.
  void setTrackVolume(String trackId, double volume);

  /// Sets the stereo panorama (pan) for a specific track.
  ///
  /// [trackId] is the unique identifier for the track.
  /// [pan] ranges from -1.0 (full left) to 1.0 (full right).
  /// A value of 0.0 represents center.
  void setTrackPan(String trackId, double pan);

  /// Mutes or unmutes a specific track.
  ///
  /// When muted, the track's audio output is silenced but its
  /// position in the mix is preserved.
  void setTrackMute(String trackId, bool isMuted);

  /// Solos or un-solos a specific track.
  ///
  /// When a track is soloed, only soloed tracks should be audible.
  /// The engine must internally manage the solo group logic:
  /// if any track has solo enabled, all non-soloed tracks are silenced.
  void setTrackSolo(String trackId, bool isSolo);

  // ─── Parametric EQ ─────────────────────────────────────────────────

  // ─── Parametric EQ ─────────────────────────────────────────────────

  /// Sets a parametric EQ band for a specific track.
  ///
  /// [trackId] is the unique identifier for the track.
  /// [bandIndex] is the band to modify (0 = Low, 1 = Mid, 2 = High).
  /// [frequency] is the center frequency in Hz.
  /// [gain] is the gain in dB (typically -24 to +24).
  /// [q] is the quality factor (bandwidth).
  void setTrackEq({
    required String trackId,
    required int bandIndex,
    required double frequency,
    required double gain,
    required double q,
  });

  // ─── Time & Pitch ──────────────────────────────────────────────────

  /// Sets the time-stretch factor for a specific track.
  ///
  /// [trackId] is the unique identifier for the track.
  /// [factor] is the playback rate multiplier.
  /// 1.0 is normal speed. 0.5 is half speed. 2.0 is double speed.
  /// This should strictly preserve pitch (Time Stretching).
  void setTrackTempo(String trackId, double factor);

  /// Sets the pitch shift in semitones for a specific track.
  ///
  /// [trackId] is the unique identifier for the track.
  /// [semitones] is the pitch shift amount (offset).
  /// 0 is original pitch. +12 is an octave up. -12 is an octave down.
  /// This should strictly preserve duration (Pitch Shifting).
  void setTrackPitch(String trackId, int semitones);

  // ─── Master FX ───

  /// Sets the Master Volume (0.0 to 1.0).
  void setMasterVolume(double volume);

  /// Sets a parametric EQ band for the Master Output.
  void setMasterEq({
    required int bandIndex,
    required double frequency,
    required double gain,
    required double q,
  });

  // ─── Waveform ───────────────────────────────────────────────────────

  /// Returns downsampled peak amplitudes for a loaded track's audio data.
  ///
  /// [trackId] is the unique identifier for the track.
  /// [numBins] is the desired number of amplitude bins.
  /// Returns a list of values in [0.0, 1.0] representing max amplitude
  /// per bin.  Returns an empty list if the track is not loaded.
  List<double> getWaveformData(String trackId, int numBins);

  // ─── Lifecycle ─────────────────────────────────────────────────────

  /// Releases all native audio resources.
  ///
  /// Call this when the page/feature is disposed to prevent memory leaks.
  void dispose();
}
