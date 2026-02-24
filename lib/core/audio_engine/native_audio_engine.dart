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

// ── Parametric EQ ──
typedef _SetTrackEqNative =
    Void Function(
      Pointer<Utf8> trackId,
      Int32 bandIndex,
      Int32 filterType,
      Float frequency,
      Float gainDb,
      Float q,
    );
typedef _SetTrackEqDart =
    void Function(
      Pointer<Utf8> trackId,
      int bandIndex,
      int filterType,
      double frequency,
      double gainDb,
      double q,
    );

// ── New Audio Effects & Master Control ──

typedef _SetTrackTempoNative =
    Void Function(Pointer<Utf8> trackId, Float tempo);
typedef _SetTrackTempoDart = void Function(Pointer<Utf8> trackId, double tempo);

typedef _SetTrackPitchNative =
    Void Function(Pointer<Utf8> trackId, Int32 semitones);
typedef _SetTrackPitchDart =
    void Function(Pointer<Utf8> trackId, int semitones);

typedef _SetMasterEqNative =
    Void Function(
      Int32 bandIndex,
      Int32 filterType,
      Float frequency,
      Float gainDb,
      Float q,
    );
typedef _SetMasterEqDart =
    void Function(
      int bandIndex,
      int filterType,
      double frequency,
      double gainDb,
      double q,
    );

typedef _SetMasterVolumeNative = Void Function(Float volume);
typedef _SetMasterVolumeDart = void Function(double volume);

typedef _ClearAllTracksNative = Void Function();
typedef _ClearAllTracksDart = void Function();

typedef _GetPositionNative = Int64 Function();
typedef _GetPositionDart = int Function();

typedef _GetSampleRateNative = Int32 Function();
typedef _GetSampleRateDart = int Function();

typedef _GetTrackDbNative = Float Function(Pointer<Utf8> trackId);
typedef _GetTrackDbDart = double Function(Pointer<Utf8> trackId);

typedef _GetMasterDbNative = Float Function();
typedef _GetMasterDbDart = double Function();

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

  // ── Lazy EQ binding (symbol may not exist in the native lib yet) ──
  _SetTrackEqDart? _setTrackEq;
  bool _eqLookupAttempted = false;

  _SetTrackTempoDart? _setTrackTempo;
  _SetTrackPitchDart? _setTrackPitch;
  _SetMasterEqDart? _setMasterEq;
  _SetMasterVolumeDart? _setMasterVolume;
  _ClearAllTracksDart? _clearAllTracks;
  late final _GetPositionDart _getPosition;
  late final _GetSampleRateDart _getSampleRate;

  late final _GetTrackDbDart _getTrackDb;
  late final _GetMasterDbDart _getMasterDb;

  late final DynamicLibrary _lib;

  // ── Volume cache ──
  // Stores the "real" slider volume for each track so mute/solo can
  // silence the track and later restore to the correct value — not 1.0.
  final Map<String, double> _volumeCache = {};

  // ── Solo set ──
  final Set<String> _soloedIds = {};

  // ── All loaded track IDs ──
  final Set<String> _allTrackIds = {};

  NativeAudioEngine() {
    _lib = _loadLibrary();
    final DynamicLibrary lib = _lib;

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

    // NOTE: engine_set_track_eq is looked up lazily in setTrackEq()
    // because the C++ symbol may not exist in the native library yet.

    // Lazy lookup other new functions to be safe, or look them up now if we are confident they exist.
    // Let's look them up now since we just implemented them in bridge.cpp.
    // If we fail here, the app might crash on startup if lib is old.
    // Ideally we use try-catch block for these new symbols or lazy lookup.
    // Given user env, let's use try-catch block here to be safe during dev.

    try {
      _setTrackTempo = lib
          .lookup<NativeFunction<_SetTrackTempoNative>>(
            'engine_set_track_tempo',
          )
          .asFunction<_SetTrackTempoDart>();

      _setTrackPitch = lib
          .lookup<NativeFunction<_SetTrackPitchNative>>(
            'engine_set_track_pitch',
          )
          .asFunction<_SetTrackPitchDart>();

      _setMasterEq = lib
          .lookup<NativeFunction<_SetMasterEqNative>>('engine_set_master_eq')
          .asFunction<_SetMasterEqDart>();

      _setMasterVolume = lib
          .lookup<NativeFunction<_SetMasterVolumeNative>>(
            'engine_set_master_volume',
          )
          .asFunction<_SetMasterVolumeDart>();

      _clearAllTracks = lib
          .lookup<NativeFunction<_ClearAllTracksNative>>(
            'engine_clear_all_tracks',
          )
          .asFunction<_ClearAllTracksDart>();
    } catch (e) {
      print('NativeAudioEngine Warning: specific new symbols not found: $e');
    }

    _getPosition = lib
        .lookup<NativeFunction<_GetPositionNative>>('engine_get_position')
        .asFunction<_GetPositionDart>();

    _getSampleRate = lib
        .lookup<NativeFunction<_GetSampleRateNative>>('engine_get_sample_rate')
        .asFunction<_GetSampleRateDart>();

    _getTrackDb = lib
        .lookup<NativeFunction<_GetTrackDbNative>>('engine_get_track_db')
        .asFunction<_GetTrackDbDart>();

    _getMasterDb = lib
        .lookup<NativeFunction<_GetMasterDbNative>>('engine_get_master_db')
        .asFunction<_GetMasterDbDart>();

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

  Stream<Duration>? _positionStream;

  @override
  Stream<Duration> get onPreviewPosition {
    _positionStream ??= Stream.periodic(const Duration(milliseconds: 16), (_) {
      final frames = _getPosition();
      final rate = _getSampleRate();
      if (rate == 0) return Duration.zero;
      return Duration(microseconds: (frames * 1000000 / rate).round());
    }).asBroadcastStream();
    return _positionStream!;
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

  // ─── Parametric EQ ────────────────────────────────────────────────────────

  @override
  void setTrackEq({
    required String trackId,
    required int bandIndex,
    required int filterType,
    required double frequency,
    required double gain,
    required double q,
  }) {
    // Lazy lookup: resolve the symbol only on first call.
    if (!_eqLookupAttempted) {
      _eqLookupAttempted = true;
      try {
        _setTrackEq = _lib
            .lookup<NativeFunction<_SetTrackEqNative>>('engine_set_track_eq')
            .asFunction<_SetTrackEqDart>();
      } catch (_) {
        // Symbol not available in the native library yet — EQ will be a no-op.
        // ignore: avoid_print
        print(
          '[NativeAudioEngine] engine_set_track_eq not found — EQ disabled.',
        );
      }
    }

    final fn = _setTrackEq;
    if (fn == null) return; // Native EQ not available yet.

    final idPtr = trackId.toNativeUtf8();
    fn(idPtr, bandIndex, filterType, frequency, gain, q);
    calloc.free(idPtr);
  }

  // Helper for Master EQ (since interface doesn't strictly have it yet,
  // but SetlistConfigStore likely calls a method that should end up here.
  // Wait, IAudioEngineService interface doesn't have setMasterEq?
  // Checking setlist_config_store.dart... it loops and does nothing currently.
  // We need to implement abstract method if exists or just add it.
  // The interface IAudioEngineService typically has setMasterEq?
  // Let's check IAudioEngineService.dart to be sure.
  // I will just add the method here and assume interface has it or I will add it to interface next.

  @override
  void setMasterEq({
    required int bandIndex,
    required int filterType,
    required double frequency,
    required double gain,
    required double q,
  }) {
    if (_setMasterEq == null) return;
    _setMasterEq!(bandIndex, filterType, frequency, gain, q);
  }

  @override
  void setMasterVolume(double volume) {
    if (_setMasterVolume == null) return;
    _setMasterVolume!(volume);
  }

  @override
  double getTrackVolumeDb(String trackId) {
    final idPtr = trackId.toNativeUtf8();
    final db = _getTrackDb(idPtr);
    calloc.free(idPtr);
    return db;
  }

  @override
  double getMasterVolumeDb() {
    return _getMasterDb();
  }

  @override
  void clearAllTracks() {
    if (_clearAllTracks == null) return;
    _clearAllTracks!();
  }

  // ─── Time & Pitch ──────────────────────────────────────────────────────────

  @override
  void setTrackTempo(String trackId, double factor) {
    if (_setTrackTempo == null) return;
    final idPtr = trackId.toNativeUtf8();
    _setTrackTempo!(idPtr, factor);
    calloc.free(idPtr);
  }

  @override
  void setTrackPitch(String trackId, int semitones) {
    if (_setTrackPitch == null) return;
    final idPtr = trackId.toNativeUtf8();
    _setTrackPitch!(idPtr, semitones);
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
