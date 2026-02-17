import '../../features/player_mixer/domain/entities/track.dart';

/// Contract for the native audio engine bridge.
///
/// This service abstracts platform-specific audio playback and mixing.
/// Implementations should use a low-latency native engine (e.g., Oboe on Android,
/// AVAudioEngine on iOS) to handle multi-track playback in real time.
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

  /// Starts playing the loaded preview from the current position.
  void playPreview();

  /// Pauses the preview playback without releasing the loaded buffers.
  void pausePreview();

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

  // ─── Lifecycle ─────────────────────────────────────────────────────

  /// Releases all native audio resources.
  ///
  /// Call this when the page/feature is disposed to prevent memory leaks.
  void dispose();
}
