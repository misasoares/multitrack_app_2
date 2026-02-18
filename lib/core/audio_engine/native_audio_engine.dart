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
typedef _LoadFileNative =
    Int32 Function(Pointer<Utf8> trackId, Pointer<Utf8> filePath);
typedef _LoadFileDart =
    int Function(Pointer<Utf8> trackId, Pointer<Utf8> filePath);

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

// ── Waveform ──
typedef _GetWaveformPeaksNative =
    Int32 Function(
      Pointer<Utf8> trackId,
      Pointer<Float> outPeaks,
      Int32 numBins,
    );
typedef _GetWaveformPeaksDart =
    int Function(Pointer<Utf8> trackId, Pointer<Float> outPeaks, int numBins);

// ─────────────────────────────────────────────────────────────────────────────
// NativeAudioEngine — IAudioEngineService implementation via dart:ffi
// ─────────────────────────────────────────────────────────────────────────────

/// Production audio engine backed by a C++ mixer + Oboe output.
///
/// Key capabilities:
/// - Single-buffer mix (no multi-player drift)
/// - Per-sample gain smoothing (no clicks/pops)
/// - Constant-power stereo panning
/// - Proper volume caching for mute/solo restore
/// - Low-latency playback via Oboe
class NativeAudioEngine implements IAudioEngineService {
  // ── FFI function pointers ──
  late final _EngineInitDart _engineInit;
  late final _EngineDisposeDart _engineDispose;
  late final _LoadFileDart _loadFile;

  late final _RemoveAllTracksDart _removeAllTracks;
  late final _PlayDart _play;
  late final _PauseDart _pause;
  late final _SeekToDart _seekTo;
  late final _SetVolumeDart _setVolume;
  late final _SetPanDart _setPan;
  late final _SetMuteDart _setMute;
  late final _SetSoloDart _setSolo;
  late final _GetWaveformPeaksDart _getWaveformPeaks;

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

    _loadFile = lib
        .lookup<NativeFunction<_LoadFileNative>>('engine_load_file')
        .asFunction<_LoadFileDart>();

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

    _getWaveformPeaks = lib
        .lookup<NativeFunction<_GetWaveformPeaksNative>>(
          'engine_get_waveform_peaks',
        )
        .asFunction<_GetWaveformPeaksDart>();

    // Initialise the native engine + Oboe output stream.
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
      _allTrackIds.add(track.id);
      _volumeCache[track.id] = track.volume;

      // Decode audio file and load PCM into the native mixer.
      final idPtr = track.id.toNativeUtf8();
      final pathPtr = track.filePath.toNativeUtf8();

      final result = _loadFile(idPtr, pathPtr);
      calloc.free(pathPtr);

      if (result == 0) {
        // Decoding failed — skip this track but free the id pointer
        calloc.free(idPtr);
        continue;
      }

      // Apply initial volume
      _setVolume(idPtr, track.volume);

      // Apply initial pan
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

  // ─── Waveform ──────────────────────────────────────────────────────────────

  @override
  List<double> getWaveformData(String trackId, int numBins) {
    final idPtr = trackId.toNativeUtf8();
    final peaksPtr = calloc<Float>(numBins);

    final filled = _getWaveformPeaks(idPtr, peaksPtr, numBins);

    final peaks = List<double>.generate(filled, (i) => peaksPtr[i]);

    calloc.free(peaksPtr);
    calloc.free(idPtr);
    return peaks;
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
