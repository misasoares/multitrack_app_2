// Top-level entry for the offline render isolate. Runs on Android only;
// opens the native library and performs render + progress polling.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

// C function signatures (match bridge.h)
typedef _RenderNative = Void Function(
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
typedef _RenderDart = void Function(
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

typedef _GetProgressNative = Float Function(Pointer<Utf8> trackId);
typedef _GetProgressDart = double Function(Pointer<Utf8> trackId);

/// Message from main: map with keys trackId, inputPath, outputPath, tempo, pitch, volume, pan, eqBands.
/// eqBands: List<Map> with type, frequency, gainDb, q.
void offlineRenderIsolateEntry(SendPort mainSendPort) async {
  if (!Platform.isAndroid) {
    mainSendPort.send(['done', -1.0]);
    return;
  }

  final recv = ReceivePort();
  mainSendPort.send(recv.sendPort);

  DynamicLibrary? lib;
  _RenderDart? renderFn;
  _GetProgressDart? progressFn;

  try {
    lib = DynamicLibrary.open('libaudio_engine.so');
    renderFn = lib
        .lookup<NativeFunction<_RenderNative>>('engine_render_track_offline')
        .asFunction<_RenderDart>();
    progressFn = lib
        .lookup<NativeFunction<_GetProgressNative>>('engine_get_render_progress')
        .asFunction<_GetProgressDart>();
  } catch (_) {
    mainSendPort.send(['done', -1.0]);
    recv.close();
    return;
  }

  final task = await recv.first as Map<dynamic, dynamic>;
  recv.close();

  final trackId = task['trackId'] as String;
  final inputPath = task['inputPath'] as String;
  final outputPath = task['outputPath'] as String;
  final tempo = (task['tempo'] as num).toDouble();
  final pitch = (task['pitch'] as num).toDouble();
  final volume = (task['volume'] as num).toDouble();
  final pan = (task['pan'] as num).toDouble();
  final eqBandsList = task['eqBands'] as List<dynamic>;

  final n = eqBandsList.length;
  final trackIdPtr = trackId.toNativeUtf8();
  final inputPathPtr = inputPath.toNativeUtf8();
  final outputPathPtr = outputPath.toNativeUtf8();
  final eqTypesPtr = calloc<Int32>(n);
  final eqFreqsPtr = calloc<Float>(n);
  final eqGainsPtr = calloc<Float>(n);
  final eqQsPtr = calloc<Float>(n);
  for (var i = 0; i < n; i++) {
    final b = eqBandsList[i] as Map<dynamic, dynamic>;
    eqTypesPtr[i] = (b['type'] as num).toInt();
    eqFreqsPtr[i] = (b['frequency'] as num).toDouble();
    eqGainsPtr[i] = (b['gainDb'] as num).toDouble();
    eqQsPtr[i] = (b['q'] as num).toDouble();
  }

  try {
    renderFn(
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

  const pollInterval = Duration(milliseconds: 200);
  double p = 0.0;
  while (true) {
    await Future.delayed(pollInterval);
    final idPtr = trackId.toNativeUtf8();
    try {
      p = progressFn(idPtr);
    } finally {
      calloc.free(idPtr);
    }
    mainSendPort.send(['progress', p]);
    if (p >= 1.0 || p < 0) break;
  }
  mainSendPort.send(['done', p]);
}
