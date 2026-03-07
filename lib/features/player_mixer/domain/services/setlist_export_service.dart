import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../entities/eq_band_data.dart';
import '../entities/setlist.dart';
import '../entities/setlist_item.dart';
import '../entities/track.dart';
import 'offline_render_isolate.dart';

import '../../../../core/audio_engine/iaudio_engine_service.dart';
import 'package:ffi/ffi.dart';

// ── LUFS Analysis FFI typedefs (must be top-level in Dart) ──
typedef _AnalyzeLufsNative =
    Double Function(
      Pointer<Pointer<Utf8>> trackPaths,
      Int32 numTracks,
      Float targetLufs,
    );
typedef _AnalyzeLufsDart =
    double Function(
      Pointer<Pointer<Utf8>> trackPaths,
      int numTracks,
      double targetLufs,
    );

/// Progress reported during setlist export (one track at a time).
class ExportProgress {
  const ExportProgress({
    required this.totalTracks,
    required this.completedTracks,
    this.currentMusicTitle,
    this.currentTrackName,
    this.trackProgress = 0.0,
    this.isBypass = false,
  });
  final int totalTracks;
  final int completedTracks;
  final String? currentMusicTitle;
  final String? currentTrackName;
  final double trackProgress;
  final bool isBypass;

  double get globalPercent =>
      totalTracks == 0 ? 0.0 : (completedTracks + trackProgress) / totalTracks;
}

/// Orchestrates offline export of a setlist: Smart Bypass (copy) or C++ render per track,
/// then extracts waveform peaks from each exported file and attaches them to tracks.
/// Returns the [Setlist] with [exportedShowDirectory], each item's [exportedItemDirectory],
/// and each track's [waveformPeaks] filled.
class SetlistExportService {
  SetlistExportService(this._audioEngine);

  final IAudioEngineService _audioEngine;

  static const int _waveformBins = 400;

  /// Exports the setlist to disk. Processes one track at a time (bypass = copy, else native render).
  /// [onProgress] is called from the main isolate with progress updates.
  /// Returns the [Setlist] with directories set, ready to be saved to Isar by the Store.
  Future<Setlist> exportSetlist(
    Setlist setlist, {
    void Function(ExportProgress)? onProgress,
  }) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final showDir = path.join(baseDir.path, 'shows', setlist.id);
    final totalTracks = setlist.items.fold<int>(
      0,
      (sum, item) =>
          sum + item.originalMusic.tracks.where((t) => !t.isMuted).length,
    );
    if (totalTracks == 0) {
      return setlist.copyWith(exportedShowDirectory: showDir);
    }

    int completedTracks = 0;
    void report({
      String? musicTitle,
      String? trackName,
      double trackProgress = 0.0,
      bool isBypass = false,
    }) {
      onProgress?.call(
        ExportProgress(
          totalTracks: totalTracks,
          completedTracks: completedTracks,
          currentMusicTitle: musicTitle,
          currentTrackName: trackName,
          trackProgress: trackProgress,
          isBypass: isBypass,
        ),
      );
    }

    final updatedItems = <SetlistItem>[];

    for (final item in setlist.items) {
      final itemDir = path.join(showDir, item.id);
      final dir = Directory(itemDir);
      if (!await dir.exists()) await dir.create(recursive: true);

      final updatedTracks = <Track>[];

      for (final track in item.originalMusic.tracks) {
        if (track.isMuted) continue;
        final isBypass = shouldBypassRender(item, track);
        final destFileName = isBypass
            ? '${track.id}${path.extension(track.filePath)}'
            : '${track.id}.wav';
        final destPath = path.join(itemDir, destFileName);
        final sourceFile = File(track.filePath);

        if (isBypass) {
          report(
            musicTitle: item.originalMusic.title,
            trackName: track.name,
            trackProgress: 1.0,
            isBypass: true,
          );
          if (await sourceFile.exists()) {
            await sourceFile.copy(destPath);
          }
        } else {
          report(
            musicTitle: item.originalMusic.title,
            trackName: track.name,
            trackProgress: 0.0,
            isBypass: false,
          );
          final success = await _runNativeRenderInIsolate(
            trackId: track.id,
            inputPath: track.filePath,
            outputPath: destPath,
            tempo: item.tempoFactor,
            pitch: _effectivePitchSemitones(item, track),
            volume: (item.volume * track.volume).toDouble(),
            pan: track.pan,
            trackEqBands: track.eqBands,
            masterEqBands: item.masterEqBands,
            onProgress: (p) => report(
              musicTitle: item.originalMusic.title,
              trackName: track.name,
              trackProgress: p,
              isBypass: false,
            ),
          );
          if (!success) {
            throw Exception(
              'Offline render failed for ${item.originalMusic.title} - ${track.name}',
            );
          }
        }

        // Pre-compute waveform peaks from the exported file (low RAM, chunked read).
        List<double>? waveformPeaks;
        final destFile = File(destPath);
        if (await destFile.exists()) {
          try {
            final peaks = await _audioEngine.extractWaveformPeaksFromFile(
              destPath,
              _waveformBins,
            );
            if (peaks.isNotEmpty) {
              waveformPeaks = peaks;
            }
          } catch (_) {
            // Non-fatal; track will have null waveformPeaks
          }
        }

        updatedTracks.add(track.copyWith(waveformPeaks: waveformPeaks));

        completedTracks++;
        report(
          musicTitle: item.originalMusic.title,
          trackName: track.name,
          trackProgress: 1.0,
          isBypass: isBypass,
        );
      }

      // ── LUFS Analysis: compute normalization gain after all tracks are rendered ──
      // Filter out utility tracks (Click, Guide, etc.) from LUFS analysis
      // to avoid transients affecting the master loudness calculation.
      final renderedPaths = updatedTracks
          .where((t) => !t.isUtilityTrack)
          .map((t) => path.join(itemDir, '${t.id}.wav'))
          .where((p) => File(p).existsSync())
          .toList();

      double normGain = 1.0;
      if (renderedPaths.isNotEmpty) {
        try {
          normGain = await _analyzeLufsInIsolate(renderedPaths, -14.0);
        } catch (e) {
          print('LUFS analysis error for ${item.originalMusic.title}: $e');
        }
      }

      updatedItems.add(
        item.copyWith(
          exportedItemDirectory: itemDir,
          originalMusic: item.originalMusic.copyWith(tracks: updatedTracks),
          normalizationGain: normGain,
        ),
      );
    }

    return setlist.copyWith(
      exportedShowDirectory: showDir,
      items: updatedItems,
    );
  }

  /// Returns true if the track needs no DSP (copy only).
  bool shouldBypassRender(SetlistItem item, Track track) {
    if (item.tempoFactor != 1.0) return false;
    if (item.transposeSemitones != 0) {
      if (item.transposableTrackIds.contains(track.id)) return false;
      if ((track.octaveShift) != 0) return false;
    }
    if (item.volume != 1.0) return false;
    if (!_isEqFlat(item.masterEqBands)) return false;

    if (track.volume != 1.0) return false;
    if (track.pan != 0.0) return false;
    if (track.isMuted) return false;
    if (!_isEqFlat(track.eqBands)) return false;
    if (track.applyTranspose && item.transposeSemitones != 0) return false;
    if (track.octaveShift != 0) return false;

    return true;
  }

  bool _isEqFlat(List<EqBandData>? bands) {
    if (bands == null || bands.isEmpty) return true;
    return bands.every((b) => b.gain == 0.0);
  }

  int _effectivePitchSemitones(SetlistItem item, Track track) {
    if (item.transposeSemitones == 0) return track.octaveShift * 12;
    if (!track.applyTranspose) return track.octaveShift * 12;
    return item.transposeSemitones + track.octaveShift * 12;
  }

  /// Runs native render in a separate isolate and polls progress; returns true if finished with success (p >= 1).
  Future<bool> _runNativeRenderInIsolate({
    required String trackId,
    required String inputPath,
    required String outputPath,
    required double tempo,
    required int pitch,
    required double volume,
    required double pan,
    required List<EqBandData> trackEqBands,
    required List<EqBandData> masterEqBands,
    required void Function(double) onProgress,
  }) async {
    final eqBands = _toRenderEqBandMaps([...trackEqBands, ...masterEqBands]);
    final mainRecv = ReceivePort();
    final doneCompleter = Completer<double>();
    final workerPortCompleter = Completer<SendPort>();

    mainRecv.listen((message) {
      if (message is SendPort) {
        if (!workerPortCompleter.isCompleted) {
          workerPortCompleter.complete(message);
        }
        return;
      }
      if (message is List && message.length >= 2) {
        if (message[0] == 'progress') {
          onProgress((message[1] as num).toDouble());
        } else if (message[0] == 'done') {
          doneCompleter.complete((message[1] as num).toDouble());
        }
      }
    });

    await Isolate.spawn(offlineRenderIsolateEntry, mainRecv.sendPort);

    final workerPort = await workerPortCompleter.future;
    workerPort.send({
      'trackId': trackId,
      'inputPath': inputPath,
      'outputPath': outputPath,
      'tempo': tempo,
      'pitch': pitch.toDouble(),
      'volume': volume,
      'pan': pan,
      'eqBands': eqBands,
    });

    final result = await doneCompleter.future;
    mainRecv.close();
    return result >= 1.0;
  }

  List<Map<String, dynamic>> _toRenderEqBandMaps(List<EqBandData> bands) {
    return bands
        .map(
          (b) => {
            'type': b.type.index,
            'frequency': b.frequency,
            'gainDb': b.gain,
            'q': b.q,
          },
        )
        .toList();
  }

  /// Runs LUFS analysis in a background isolate to avoid blocking the UI.
  Future<double> _analyzeLufsInIsolate(
    List<String> renderedPaths,
    double targetLufs,
  ) async {
    return Isolate.run<double>(() {
      if (!Platform.isAndroid) return 1.0;

      final lib = DynamicLibrary.open('libaudio_engine.so');
      final analyzeFn = lib
          .lookup<NativeFunction<_AnalyzeLufsNative>>('engine_analyze_lufs')
          .asFunction<_AnalyzeLufsDart>();

      final numTracks = renderedPaths.length;
      final pathPtrs = calloc<Pointer<Utf8>>(numTracks);
      final allocatedPtrs = <Pointer<Utf8>>[];

      try {
        for (int i = 0; i < numTracks; i++) {
          final ptr = renderedPaths[i].toNativeUtf8();
          allocatedPtrs.add(ptr);
          pathPtrs[i] = ptr;
        }

        final result = analyzeFn(pathPtrs, numTracks, targetLufs);
        return result;
      } finally {
        for (final ptr in allocatedPtrs) {
          calloc.free(ptr);
        }
        calloc.free(pathPtrs);
      }
    });
  }
}
