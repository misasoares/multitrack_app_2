abstract class IAudioEngineService {
  /// Plays the current audio.
  Future<void> play();

  /// Pauses the current audio.
  Future<void> pause();

  /// Seeks to a specific timestamp.
  Future<void> seekTo(Duration timestamp);

  /// Sets the volume for a specific track.
  /// [trackId] is the unique identifier for the track.
  /// [volume] is a value between 0.0 and 1.0.
  Future<void> setVolume(String trackId, double volume);
}
