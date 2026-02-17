import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../../features/player_mixer/domain/entities/track.dart';
import 'iaudio_engine_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FFI Typedefs — Native ↔ Dart function signatures
// ─────────────────────────────────────────────────────────────────────────────

// ── Lifecycle ──
typedef _EngineInitNative = Void Function(Int32 sampleRate);
typedef _EngineInitDart = void Function(int sampleRate);

typedef _EngineDisposeNative = Void Function();
typedef _EngineDisposeDart = void Function();

// ── Track Management ──
typedef _LoadTrackNative =
    Void Function(
      Pointer<Utf8> trackId,
      Pointer<Float> pcmData,
      Int64 numFrames,
      Int32 numChannels,
    );
typedef _LoadTrackDart =
    void Function(
      Pointer<Utf8> trackId,
      Pointer<Float> pcmData,
      int numFrames,
      int numChannels,
    );

typedef _RemoveTrackNative = Void Function(Pointer<Utf8> trackId);
typedef _RemoveTrackDart = void Function(Pointer<Utf8> trackId);

typedef _RemoveAllTracksNative = Void Function();
typedef _RemoveAllTracksDart = void Function();

// ── Transport ──
typedef _PlayNative = Void Function();
typedef _PlayDart = void Function();

typedef _PauseNative = Void Function();
typedef _PauseDart = void Function();

typedef _SeekToNative = Void Function(Int64 framePosition);
typedef _SeekToDart = void Function(int framePosition);

// ── Per-track parameters ──
typedef _SetVolumeNative = Void Function(Pointer<Utf8> trackId, Float volume);
typedef _SetVolumeDart = void Function(Pointer<Utf8> trackId, double volume);

typedef _SetPanNative = Void Function(Pointer<Utf8> trackId, Float pan);
typedef _SetPanDart = void Function(Pointer<Utf8> trackId, double pan);

typedef _SetMuteNative = Void Function(Pointer<Utf8> trackId, Int32 isMuted);
typedef _SetMuteDart = void Function(Pointer<Utf8> trackId, int isMuted);

typedef _SetSoloNative = Void Function(Pointer<Utf8> trackId, Int32 isSolo);
typedef _SetSoloDart = void Function(Pointer<Utf8> trackId, int isSolo);

// NOTE: _ProcessNative/_ProcessDart and _IsPlayingNative/_IsPlayingDart
// typedefs will be added when the Oboe audio callback integration is
// implemented. They are not needed until the process() loop is driven
// from the native audio thread.

// ─────────────────────────────────────────────────────────────────────────────
// NativeAudioEngine — IAudioEngineService implementation via dart:ffi
// ─────────────────────────────────────────────────────────────────────────────

/// Production audio engine backed by a C++ mixer library (libaudio_engine.so).
///
/// Key improvements over the prototype JustAudioEngine:
/// - Single-buffer mix (no multi-player drift)
/// - Per-sample gain smoothing (no clicks/pops)
/// - Constant-power stereo panning
/// - Proper volume caching for mute/solo restore
class NativeAudioEngine implements IAudioEngineService {
  // ── FFI function pointers ──
  late final _EngineInitDart _engineInit;
  late final _EngineDisposeDart _engineDispose;
  // ignore: unused_field — will be used when native PCM decoder is wired
  late final _LoadTrackDart _loadTrack;
  // ignore: unused_field — will be used when native PCM decoder is wired
  late final _RemoveTrackDart _removeTrack;
  late final _RemoveAllTracksDart _removeAllTracks;
  late final _PlayDart _play;
  late final _PauseDart _pause;
  late final _SeekToDart _seekTo;
  late final _SetVolumeDart _setVolume;
  late final _SetPanDart _setPan;
  late final _SetMuteDart _setMute;
  late final _SetSoloDart _setSolo;

  // ── Volume cache ──
  // Stores the "real" slider volume for each track so mute/solo can
  // silence the track and later restore to the correct value — not 1.0.
  final Map<String, double> _volumeCache = {};

  // ── Solo set ──
  final Set<String> _soloedIds = {};

  // ── All loaded track IDs ──
  final Set<String> _allTrackIds = {};

  NativeAudioEngine() {
    final DynamicLibrary lib = _loadLibrary();

    _engineInit = lib
        .lookup<NativeFunction<_EngineInitNative>>('engine_init')
        .asFunction<_EngineInitDart>();

    _engineDispose = lib
        .lookup<NativeFunction<_EngineDisposeNative>>('engine_dispose')
        .asFunction<_EngineDisposeDart>();

    _loadTrack = lib
        .lookup<NativeFunction<_LoadTrackNative>>('engine_load_track')
        .asFunction<_LoadTrackDart>();

    _removeTrack = lib
        .lookup<NativeFunction<_RemoveTrackNative>>('engine_remove_track')
        .asFunction<_RemoveTrackDart>();

    _removeAllTracks = lib
        .lookup<NativeFunction<_RemoveAllTracksNative>>(
          'engine_remove_all_tracks',
        )
        .asFunction<_RemoveAllTracksDart>();

    _play = lib
        .lookup<NativeFunction<_PlayNative>>('engine_play')
        .asFunction<_PlayDart>();

    _pause = lib
        .lookup<NativeFunction<_PauseNative>>('engine_pause')
        .asFunction<_PauseDart>();

    _seekTo = lib
        .lookup<NativeFunction<_SeekToNative>>('engine_seek_to')
        .asFunction<_SeekToDart>();

    _setVolume = lib
        .lookup<NativeFunction<_SetVolumeNative>>('engine_set_volume')
        .asFunction<_SetVolumeDart>();

    _setPan = lib
        .lookup<NativeFunction<_SetPanNative>>('engine_set_pan')
        .asFunction<_SetPanDart>();

    _setMute = lib
        .lookup<NativeFunction<_SetMuteNative>>('engine_set_mute')
        .asFunction<_SetMuteDart>();

    _setSolo = lib
        .lookup<NativeFunction<_SetSoloNative>>('engine_set_solo')
        .asFunction<_SetSoloDart>();

    // Initialise the native engine with standard CD sample rate.
    _engineInit(44100);
  }

  /// Loads the platform-appropriate shared library.
  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libaudio_engine.so');
    }
    if (Platform.isIOS || Platform.isMacOS) {
      // On iOS/macOS the library will be statically linked into the
      // app binary — use DynamicLibrary.process().
      // This path will be activated when we add the Xcode build step.
      return DynamicLibrary.process();
    }
    throw UnsupportedError(
      'NativeAudioEngine is not supported on ${Platform.operatingSystem}',
    );
  }

  // ─── Playback ──────────────────────────────────────────────────────────────

  @override
  Future<void> play() async {
    _play();
  }

  @override
  Future<void> pause() async {
    _pause();
  }

  @override
  Future<void> seekTo(Duration timestamp) async {
    // Convert Duration to frame position at 44100 Hz.
    final frames = (timestamp.inMicroseconds * 44100 / 1000000).round();
    _seekTo(frames);
  }

  // ─── Preview ───────────────────────────────────────────────────────────────

  @override
  Future<void> loadPreview(List<Track> tracks) async {
    // Remove previously loaded tracks from the native engine.
    _removeAllTracks();
    _volumeCache.clear();
    _soloedIds.clear();
    _allTrackIds.clear();

    for (final track in tracks) {
      // TODO: In a future step, decode the audio file at `track.filePath`
      // into raw PCM float data using a native decoder (e.g. MediaCodec on
      // Android).  For now, we register the track metadata so the FFI
      // bridge and volume/pan/mute/solo pipeline can be validated end-to-end
      // once the decoder is wired up.
      //
      // Placeholder: we'll load an empty buffer so the track is registered.
      _allTrackIds.add(track.id);
      _volumeCache[track.id] = track.volume;

      // Apply initial volume
      final idPtr = track.id.toNativeUtf8();
      _setVolume(idPtr, track.volume);

      // Apply initial pan (now correctly defaults to 0.0 = center)
      _setPan(idPtr, track.pan);

      // Apply mute state
      if (track.isMuted) {
        _setMute(idPtr, 1);
      }

      // Apply solo state
      if (track.isSolo) {
        _soloedIds.add(track.id);
        _setSolo(idPtr, 1);
      }

      calloc.free(idPtr);
    }
  }

  @override
  void playPreview() {
    // Seek all tracks to the beginning and start playback.
    _seekTo(0);
    _play();
  }

  @override
  void pausePreview() {
    _pause();
  }

  // ─── Real-Time Mixing ─────────────────────────────────────────────────────

  @override
  void setTrackVolume(String trackId, double volume) {
    // Cache the slider value so we can restore after mute/solo.
    _volumeCache[trackId] = volume;

    final idPtr = trackId.toNativeUtf8();
    _setVolume(idPtr, volume);
    calloc.free(idPtr);
  }

  @override
  void setTrackPan(String trackId, double pan) {
    final idPtr = trackId.toNativeUtf8();
    _setPan(idPtr, pan);
    calloc.free(idPtr);
  }

  @override
  void setTrackMute(String trackId, bool isMuted) {
    final idPtr = trackId.toNativeUtf8();
    _setMute(idPtr, isMuted ? 1 : 0);

    if (!isMuted) {
      // Restore the cached volume when un-muting (not 1.0!).
      final cachedVolume = _volumeCache[trackId] ?? 1.0;
      _setVolume(idPtr, cachedVolume);
    }

    calloc.free(idPtr);
  }

  @override
  void setTrackSolo(String trackId, bool isSolo) {
    if (isSolo) {
      _soloedIds.add(trackId);
    } else {
      _soloedIds.remove(trackId);
    }

    final idPtr = trackId.toNativeUtf8();
    _setSolo(idPtr, isSolo ? 1 : 0);
    calloc.free(idPtr);
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _engineDispose();
    _volumeCache.clear();
    _soloedIds.clear();
    _allTrackIds.clear();
  }
}
