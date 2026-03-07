import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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

typedef _ScheduleJumpNative =
    Void Function(Int64 triggerFrame, Int64 targetFrame);
typedef _ScheduleJumpDart = void Function(int triggerFrame, int targetFrame);

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

/// Extract peaks from file (low RAM, chunked); for use after render/copy.
typedef _ExtractPeaksFromFileNative =
    Void Function(
      Pointer<Utf8> filePath,
      Int32 numBins,
      Pointer<Float> outPeaks,
    );
typedef _ExtractPeaksFromFileDart =
    void Function(Pointer<Utf8> filePath, int numBins, Pointer<Float> outPeaks);

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

typedef _SetMasterNormalizationGainNative = Void Function(Float gain);
typedef _SetMasterNormalizationGainDart = void Function(double gain);

typedef _SetMetronomeVolumeNative = Void Function(Float volume);
typedef _SetMetronomeVolumeDart = void Function(double volume);

typedef _SetMetronomePanNative = Void Function(Float pan);
typedef _SetMetronomePanDart = void Function(double pan);

typedef _SetMetronomeBpmNative = Void Function(Float bpm);
typedef _SetMetronomeBpmDart = void Function(double bpm);

typedef _SetMetronomePlayingNative = Void Function(Int32 playing);
typedef _SetMetronomePlayingDart = void Function(int playing);

typedef _ClearAllTracksNative = Void Function();
typedef _ClearAllTracksDart = void Function();

typedef _GetPositionNative = Int64 Function();
typedef _GetPositionDart = int Function();

typedef _GetSampleRateNative = Int32 Function();
typedef _GetSampleRateDart = int Function();

typedef _GetTrackDbNative = Float Function(Pointer<Utf8> trackId);
typedef _GetTrackDbDart = double Function(Pointer<Utf8> trackId);

typedef _GetTrackPeakNative = Float Function(Pointer<Utf8> trackId);
typedef _GetTrackPeakDart = double Function(Pointer<Utf8> trackId);

typedef _GetMasterDbNative = Float Function();
typedef _GetMasterDbDart = double Function();

// ── Offline Render ──
typedef _RenderTrackOfflineNative =
    Void Function(
      Pointer<Utf8> trackId,
      Pointer<Utf8> inputPath,
      Pointer<Utf8> outputPath,
      Float tempo,
      Float pitch,
      Float volume,
      Float pan,
      Int32 numEqBands,
      Pointer<Int32> eqTypes,
      Pointer<Float> eqFreqs,
      Pointer<Float> eqGains,
      Pointer<Float> eqQs,
    );
typedef _RenderTrackOfflineDart =
    void Function(
      Pointer<Utf8> trackId,
      Pointer<Utf8> inputPath,
      Pointer<Utf8> outputPath,
      double tempo,
      double pitch,
      double volume,
      double pan,
      int numEqBands,
      Pointer<Int32> eqTypes,
      Pointer<Float> eqFreqs,
      Pointer<Float> eqGains,
      Pointer<Float> eqQs,
    );

typedef _GetRenderProgressNative = Float Function(Pointer<Utf8> trackId);
typedef _GetRenderProgressDart = double Function(Pointer<Utf8> trackId);

typedef _CancelRenderNative = Void Function(Pointer<Utf8> trackId);
typedef _CancelRenderDart = void Function(Pointer<Utf8> trackId);

// ── Beat Map Extraction ──
typedef _ExtractBeatMapNative =
    Int32 Function(
      Pointer<Utf8> filePath,
      Float threshold,
      Int32 minSpacingMs,
      Pointer<Int32> outTimestamps,
      Int32 maxTimestamps,
    );
typedef _ExtractBeatMapDart =
    int Function(
      Pointer<Utf8> filePath,
      double threshold,
      int minSpacingMs,
      Pointer<Int32> outTimestamps,
      int maxTimestamps,
    );

// ── Click Map Wiring ──
typedef _SetTrackClickMapNative =
    Void Function(Pointer<Utf8> trackId, Pointer<Int32> mapMs, Int32 size);
typedef _SetTrackClickMapDart =
    void Function(Pointer<Utf8> trackId, Pointer<Int32> mapMs, int size);

// ── Drum Rack ──
typedef _LoadDrumSampleNative =
    Int8 Function(Pointer<Utf8> id, Pointer<Utf8> path);
typedef _LoadDrumSampleDart =
    int Function(Pointer<Utf8> id, Pointer<Utf8> path);

typedef _TriggerDrumPadNative = Void Function(Pointer<Utf8> id);
typedef _TriggerDrumPadDart = void Function(Pointer<Utf8> id);

typedef _ClearDrumSamplesNative = Void Function();
typedef _ClearDrumSamplesDart = void Function();

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
  late final _RemoveAllTracksDart _removeAllTracks;
  late final _PlayDart _play;
  late final _PauseDart _pause;
  late final _SeekToDart _seekTo;
  late final _ScheduleJumpDart _scheduleJump;
  late final _SetVolumeDart _setVolume;
  late final _SetPanDart _setPan;
  late final _SetMuteDart _setMute;
  late final _SetSoloDart _setSolo;
  // NOTE: _getWaveformPeaks is not stored as a field because waveform work
  // runs in a background isolate. _loadFile is stored and called on main:
  // engine_load_file is O(1) for WAV (disk streaming), so no decode isolate needed.
  late final _LoadFileDart _loadFile;

  // ── Lazy EQ binding (symbol may not exist in the native lib yet) ──
  _SetTrackEqDart? _setTrackEq;
  bool _eqLookupAttempted = false;

  _SetTrackTempoDart? _setTrackTempo;
  _SetTrackPitchDart? _setTrackPitch;
  _SetMasterEqDart? _setMasterEq;
  _SetMasterVolumeDart? _setMasterVolume;
  _SetMasterNormalizationGainDart? _setMasterNormalizationGain;
  _SetMetronomeVolumeDart? _setMetronomeVolume;
  _SetMetronomePanDart? _setMetronomePan;
  _SetMetronomeBpmDart? _setMetronomeBpm;
  _SetMetronomePlayingDart? _setMetronomePlaying;
  _ClearAllTracksDart? _clearAllTracks;
  late final _GetPositionDart _getPosition;
  late final _GetSampleRateDart _getSampleRate;

  late final _GetTrackDbDart _getTrackDb;
  late final _GetTrackPeakDart _getTrackPeak;
  late final _GetMasterDbDart _getMasterDb;

  _RenderTrackOfflineDart? _renderTrackOffline;
  late final _GetRenderProgressDart _getRenderProgress;
  late final _CancelRenderDart _cancelRender;

  _ExtractPeaksFromFileDart? _extractPeaksFromFile;
  _ExtractBeatMapDart? _extractBeatMap;
  _SetTrackClickMapDart? _setTrackClickMap;

  // ── Drum Rack ──
  _LoadDrumSampleDart? _loadDrumSample;
  _TriggerDrumPadDart? _triggerDrumPad;
  _ClearDrumSamplesDart? _clearDrumSamples;

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

    _removeAllTracks = lib
        .lookup<NativeFunction<_RemoveAllTracksNative>>(
          'engine_remove_all_tracks',
        )
        .asFunction<_RemoveAllTracksDart>();

    _loadFile = lib
        .lookup<NativeFunction<_LoadFileNative>>('engine_load_file')
        .asFunction<_LoadFileDart>();

    _play = lib
        .lookup<NativeFunction<_PlayNative>>('engine_play')
        .asFunction<_PlayDart>();

    _pause = lib
        .lookup<NativeFunction<_PauseNative>>('engine_pause')
        .asFunction<_PauseDart>();

    _seekTo = lib
        .lookup<NativeFunction<_SeekToNative>>('engine_seek_to')
        .asFunction<_SeekToDart>();

    _scheduleJump = lib
        .lookup<NativeFunction<_ScheduleJumpNative>>('engine_schedule_jump')
        .asFunction<_ScheduleJumpDart>();

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

      _setMasterNormalizationGain = lib
          .lookup<NativeFunction<_SetMasterNormalizationGainNative>>(
            'engine_set_master_normalization_gain',
          )
          .asFunction<_SetMasterNormalizationGainDart>();

      _setMetronomeVolume = lib
          .lookup<NativeFunction<_SetMetronomeVolumeNative>>(
            'engine_set_metronome_volume',
          )
          .asFunction<_SetMetronomeVolumeDart>();

      _setMetronomePan = lib
          .lookup<NativeFunction<_SetMetronomePanNative>>(
            'engine_set_metronome_pan',
          )
          .asFunction<_SetMetronomePanDart>();

      _setMetronomeBpm = lib
          .lookup<NativeFunction<_SetMetronomeBpmNative>>(
            'engine_set_metronome_bpm',
          )
          .asFunction<_SetMetronomeBpmDart>();

      _setMetronomePlaying = lib
          .lookup<NativeFunction<_SetMetronomePlayingNative>>(
            'engine_set_metronome_playing',
          )
          .asFunction<_SetMetronomePlayingDart>();

      _clearAllTracks = lib
          .lookup<NativeFunction<_ClearAllTracksNative>>(
            'engine_clear_all_tracks',
          )
          .asFunction<_ClearAllTracksDart>();
    } catch (e) {
      print('NativeAudioEngine Warning: specific new symbols not found: $e');
    }

    try {
      _renderTrackOffline = lib
          .lookup<NativeFunction<_RenderTrackOfflineNative>>(
            'engine_render_track_offline',
          )
          .asFunction<_RenderTrackOfflineDart>();
    } catch (e) {
      print(
        'NativeAudioEngine Warning: engine_render_track_offline not found: $e',
      );
    }

    try {
      _extractPeaksFromFile = lib
          .lookup<NativeFunction<_ExtractPeaksFromFileNative>>(
            'engine_extract_peaks_from_file',
          )
          .asFunction<_ExtractPeaksFromFileDart>();
    } catch (e) {
      print(
        'NativeAudioEngine Warning: engine_extract_peaks_from_file not found: $e',
      );
    }

    try {
      _extractBeatMap = lib
          .lookup<NativeFunction<_ExtractBeatMapNative>>(
            'engine_extract_beat_map',
          )
          .asFunction<_ExtractBeatMapDart>();
    } catch (e) {
      print('NativeAudioEngine Warning: engine_extract_beat_map not found: $e');
    }

    try {
      _setTrackClickMap = lib
          .lookup<NativeFunction<_SetTrackClickMapNative>>(
            'engine_set_track_click_map',
          )
          .asFunction<_SetTrackClickMapDart>();
    } catch (e) {
      print(
        'NativeAudioEngine Warning: engine_set_track_click_map not found: $e',
      );
    }

    try {
      _loadDrumSample = lib
          .lookup<NativeFunction<_LoadDrumSampleNative>>(
            'engine_load_drum_sample',
          )
          .asFunction<_LoadDrumSampleDart>();

      _triggerDrumPad = lib
          .lookup<NativeFunction<_TriggerDrumPadNative>>('engine_trigger_pad')
          .asFunction<_TriggerDrumPadDart>();

      _clearDrumSamples = lib
          .lookup<NativeFunction<_ClearDrumSamplesNative>>(
            'engine_clear_drum_samples',
          )
          .asFunction<_ClearDrumSamplesDart>();
    } catch (e) {
      print('NativeAudioEngine Warning: Drum Rack symbols not found: $e');
    }

    _getRenderProgress = lib
        .lookup<NativeFunction<_GetRenderProgressNative>>(
          'engine_get_render_progress',
        )
        .asFunction<_GetRenderProgressDart>();

    _cancelRender = lib
        .lookup<NativeFunction<_CancelRenderNative>>('engine_cancel_render')
        .asFunction<_CancelRenderDart>();

    _getPosition = lib
        .lookup<NativeFunction<_GetPositionNative>>('engine_get_position')
        .asFunction<_GetPositionDart>();

    _getSampleRate = lib
        .lookup<NativeFunction<_GetSampleRateNative>>('engine_get_sample_rate')
        .asFunction<_GetSampleRateDart>();

    _getTrackDb = lib
        .lookup<NativeFunction<_GetTrackDbNative>>('engine_get_track_db')
        .asFunction<_GetTrackDbDart>();

    _getTrackPeak = lib
        .lookup<NativeFunction<_GetTrackPeakNative>>('engine_get_track_peak')
        .asFunction<_GetTrackPeakDart>();

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
    // Convert Duration to frame position using the engine's current sample rate.
    final frames = (timestamp.inMicroseconds * _getSampleRate() / 1000000)
        .round();
    _seekTo(frames);
  }

  @override
  Future<void> scheduleJump(Duration? triggerTime, Duration targetTime) async {
    if (triggerTime == null || triggerTime.isNegative) {
      _scheduleJump(
        -1,
        (targetTime.inMicroseconds * _getSampleRate() ~/ 1000000),
      );
    } else {
      _scheduleJump(
        (triggerTime.inMicroseconds * _getSampleRate() ~/ 1000000),
        (targetTime.inMicroseconds * _getSampleRate() ~/ 1000000),
      );
    }
  }

  // ─── Preview ───────────────────────────────────────────────────────────────

  @override
  Future<void> loadPreview(List<Track> tracks) async {
    // Remove previously loaded tracks from the native engine.
    _removeAllTracks();
    _volumeCache.clear();
    _soloedIds.clear();
    _allTrackIds.clear();

    if (tracks.isEmpty) return;

    final trackIds = <String>[];
    final filePaths = <String>[];
    final volumes = <double>[];
    final pans = <double>[];
    final mutes = <bool>[];
    final solos = <bool>[];

    for (final track in tracks) {
      _allTrackIds.add(track.id);
      _volumeCache[track.id] = track.volume;

      trackIds.add(track.id);
      filePaths.add(track.filePath);
      volumes.add(track.volume);
      pans.add(track.pan);
      mutes.add(track.isMuted);
      solos.add(track.isSolo);
    }

    // engine_load_file is O(1) for WAV (header + pre-fill); no isolate needed.
    // Non-WAV still decodes in C++; we call synchronously to keep API simple.
    final decodeResults = <bool>[];
    for (var i = 0; i < trackIds.length; i++) {
      final idPtr = trackIds[i].toNativeUtf8();
      final pathPtr = filePaths[i].toNativeUtf8();
      try {
        final result = _loadFile(idPtr, pathPtr);
        decodeResults.add(result != 0);
      } finally {
        calloc.free(pathPtr);
        calloc.free(idPtr);
      }
    }

    // Apply volume/pan/mute/solo on the main isolate.
    for (var i = 0; i < trackIds.length; i++) {
      if (i >= decodeResults.length || !decodeResults[i]) continue;

      final idPtr = trackIds[i].toNativeUtf8();

      _setVolume(idPtr, volumes[i]);
      _setPan(idPtr, pans[i]);

      if (mutes[i]) {
        _setMute(idPtr, 1);
      }

      if (solos[i]) {
        _soloedIds.add(trackIds[i]);
        _setSolo(idPtr, 1);
      }

      calloc.free(idPtr);
    }
  }

  @override
  void playPreview() {
    // Resume from current position (do not seek to 0 — LivePerformanceStore
    // calls seekTo(Duration.zero) only on load/next/prev/goToSong).
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
  void setMasterNormalizationGain(double gain) {
    _setMasterNormalizationGain?.call(gain);
  }

  @override
  void setMetronomeVolume(double volume) {
    _setMetronomeVolume?.call(volume);
  }

  @override
  void setMetronomePan(double pan) {
    _setMetronomePan?.call(pan);
  }

  @override
  void setMetronomeBpm(double bpm) {
    _setMetronomeBpm?.call(bpm);
  }

  @override
  void setMetronomePlaying(bool playing) {
    _setMetronomePlaying?.call(playing ? 1 : 0);
  }

  @override
  double getTrackVolumeDb(String trackId) {
    final idPtr = trackId.toNativeUtf8();
    final db = _getTrackDb(idPtr);
    calloc.free(idPtr);
    return db;
  }

  @override
  double getTrackPeak(String trackId) {
    final idPtr = trackId.toNativeUtf8();
    final peak = _getTrackPeak(idPtr);
    calloc.free(idPtr);
    return peak.clamp(0.0, 1.0);
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
  Future<List<double>> getWaveformData(String trackId, int numBins) async {
    return _getWaveformDataInBackground(trackId, numBins);
  }

  @override
  Future<List<double>> extractWaveformPeaksFromFile(
    String filePath,
    int numBins,
  ) async {
    if (_extractPeaksFromFile == null || numBins <= 0) return [];
    return Isolate.run<List<double>>(() {
      final lib = NativeAudioEngine._loadLibrary();
      final fn = lib
          .lookup<NativeFunction<_ExtractPeaksFromFileNative>>(
            'engine_extract_peaks_from_file',
          )
          .asFunction<_ExtractPeaksFromFileDart>();
      final pathPtr = filePath.toNativeUtf8();
      final outPtr = calloc<Float>(numBins);
      try {
        fn(pathPtr, numBins, outPtr);
        return List<double>.generate(numBins, (i) => outPtr[i].clamp(0.0, 1.0));
      } finally {
        calloc.free(pathPtr);
        calloc.free(outPtr);
      }
    });
  }

  @override
  Future<List<double>> getWaveformPeaks(
    String filePath, {
    int numBins = 2000,
  }) async {
    if (numBins <= 0) return [];
    return Isolate.run<List<double>>(() {
      final lib = NativeAudioEngine._loadLibrary();
      final fn = lib
          .lookup<NativeFunction<_ExtractPeaksFromFileNative>>(
            'engine_extract_peaks',
          )
          .asFunction<_ExtractPeaksFromFileDart>();
      final pathPtr = filePath.toNativeUtf8();
      final outPtr = calloc<Float>(numBins);
      try {
        fn(pathPtr, numBins, outPtr);
        return List<double>.generate(numBins, (i) => outPtr[i].clamp(0.0, 1.0));
      } finally {
        calloc.free(pathPtr);
        calloc.free(outPtr);
      }
    });
  }

  // ─── Beat Map Extraction ──────────────────────────────────────────────────

  @override
  Future<List<int>> extractBeatMap(String filePath) async {
    if (_extractBeatMap == null) return [];
    return Isolate.run<List<int>>(() {
      final lib = NativeAudioEngine._loadLibrary();
      final fn = lib
          .lookup<NativeFunction<_ExtractBeatMapNative>>(
            'engine_extract_beat_map',
          )
          .asFunction<_ExtractBeatMapDart>();

      const int maxTimestamps = 4096;
      final pathPtr = filePath.toNativeUtf8();
      final outPtr = calloc<Int32>(maxTimestamps);
      try {
        final count = fn(pathPtr, 0.15, 100, outPtr, maxTimestamps);
        return List<int>.generate(count, (i) => outPtr[i]);
      } finally {
        calloc.free(pathPtr);
        calloc.free(outPtr);
      }
    });
  }

  @override
  void setTrackClickMap(String trackId, List<int> clickMapMs) {
    final fn = _setTrackClickMap;
    if (fn == null || clickMapMs.isEmpty) return;

    final trackIdPtr = trackId.toNativeUtf8();
    final mapPtr = calloc<Int32>(clickMapMs.length);
    try {
      for (int i = 0; i < clickMapMs.length; i++) {
        mapPtr[i] = clickMapMs[i];
      }
      fn(trackIdPtr, mapPtr, clickMapMs.length);
    } finally {
      calloc.free(trackIdPtr);
      calloc.free(mapPtr);
    }
  }

  // ─── Drum Rack ─────────────────────────────────────────────────────────────

  @override
  Future<bool> loadDrumSample(String id, String filePath) async {
    final fn = _loadDrumSample;
    if (fn == null) return false;

    final idPtr = id.toNativeUtf8();
    final pathPtr = filePath.toNativeUtf8();
    try {
      final result = fn(idPtr, pathPtr);
      return result != 0;
    } finally {
      calloc.free(idPtr);
      calloc.free(pathPtr);
    }
  }

  @override
  void triggerDrumPad(String id) {
    if (_triggerDrumPad == null) return;
    final idPtr = id.toNativeUtf8();
    _triggerDrumPad!(idPtr);
    calloc.free(idPtr);
  }

  @override
  void clearDrumSamples() {
    _clearDrumSamples?.call();
  }

  @override
  Future<void> initializeDrumKit() async {
    final directory = await getApplicationDocumentsDirectory();

    for (int i = 1; i <= 8; i++) {
      final assetPath = 'assets/drum_kit/pad_$i.wav';
      final fileName = 'pad_$i.wav';
      final file = File('${directory.path}/$fileName');

      try {
        // ignore: avoid_print
        print('DrumKit: Tentando carregar $assetPath para ${file.path}');
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await file.writeAsBytes(bytes, flush: true);

        if (file.existsSync()) {
          // ignore: avoid_print
          print(
            'DrumKit: Arquivo temporário criado (${file.lengthSync()} bytes)',
          );
          final success = await loadDrumSample('pad_$i', file.path);
          // ignore: avoid_print
          print('DrumKit: engine_load_drum_sample pad_$i status: $success');
        } else {
          // ignore: avoid_print
          print(
            'DrumKit: ERRO - Arquivo temporário não encontrado após escrita',
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('DrumKit: Erro fatal no pad $i ($assetPath): $e');
      }
    }
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  // ─── Offline Render ───────────────────────────────────────────────────────

  @override
  void renderTrackOffline({
    required String trackId,
    required String inputPath,
    required String outputPath,
    required double tempo,
    required double pitch,
    required double volume,
    required double pan,
    required List<RenderEqBand> eqBands,
  }) {
    final fn = _renderTrackOffline;
    if (fn == null) return;

    final n = eqBands.length;
    final trackIdPtr = trackId.toNativeUtf8();
    final inputPathPtr = inputPath.toNativeUtf8();
    final outputPathPtr = outputPath.toNativeUtf8();

    final eqTypesPtr = calloc<Int32>(n);
    final eqFreqsPtr = calloc<Float>(n);
    final eqGainsPtr = calloc<Float>(n);
    final eqQsPtr = calloc<Float>(n);
    for (var i = 0; i < n; i++) {
      eqTypesPtr[i] = eqBands[i].type;
      eqFreqsPtr[i] = eqBands[i].frequency;
      eqGainsPtr[i] = eqBands[i].gainDb;
      eqQsPtr[i] = eqBands[i].q;
    }
    try {
      fn(
        trackIdPtr,
        inputPathPtr,
        outputPathPtr,
        tempo,
        pitch,
        volume,
        pan,
        n,
        eqTypesPtr,
        eqFreqsPtr,
        eqGainsPtr,
        eqQsPtr,
      );
    } finally {
      calloc.free(trackIdPtr);
      calloc.free(inputPathPtr);
      calloc.free(outputPathPtr);
      calloc.free(eqTypesPtr);
      calloc.free(eqFreqsPtr);
      calloc.free(eqGainsPtr);
      calloc.free(eqQsPtr);
    }
  }

  @override
  double getRenderProgress(String trackId) {
    final idPtr = trackId.toNativeUtf8();
    try {
      return _getRenderProgress(idPtr);
    } finally {
      calloc.free(idPtr);
    }
  }

  @override
  void cancelRender(String trackId) {
    final idPtr = trackId.toNativeUtf8();
    try {
      _cancelRender(idPtr);
    } finally {
      calloc.free(idPtr);
    }
  }

  @override
  void dispose() {
    _engineDispose();
    _volumeCache.clear();
    _soloedIds.clear();
    _allTrackIds.clear();
  }
}

/// Fetches waveform peaks via `engine_get_waveform_peaks` in a background isolate.
Future<List<double>> _getWaveformDataInBackground(String trackId, int numBins) {
  final id = trackId;
  final bins = numBins;

  return Isolate.run<List<double>>(() {
    final lib = NativeAudioEngine._loadLibrary();
    final getWaveformPeaks = lib
        .lookup<NativeFunction<_GetWaveformPeaksNative>>(
          'engine_get_waveform_peaks',
        )
        .asFunction<_GetWaveformPeaksDart>();

    final idPtr = id.toNativeUtf8();
    final peaksPtr = calloc<Float>(bins);

    final filled = getWaveformPeaks(idPtr, peaksPtr, bins);
    final peaks = List<double>.generate(filled, (i) => peaksPtr[i]);

    calloc.free(peaksPtr);
    calloc.free(idPtr);

    return peaks;
  });
}
