import 'package:equatable/equatable.dart';
import 'track.dart';
import 'marker.dart';

class Music extends Equatable {
  final String id;
  final String title;
  final String artist;
  final int bpm;
  final int timeSignatureNumerator;
  final int timeSignatureDenominator;
  final String key; // e.g., "C", "Am"
  final List<Track> tracks;
  final List<Marker> markers;
  final List<int> clickMap;
  final DateTime createdAt;
  final DateTime updatedAt;

  Music({
    required this.id,
    required this.title,
    this.artist = '',
    required this.bpm,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    this.key = '',
    this.tracks = const [],
    this.markers = const [],
    this.clickMap = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt =
           createdAt ??
           DateTime.fromMicrosecondsSinceEpoch(0), // Default for existing
       updatedAt = updatedAt ?? DateTime.fromMicrosecondsSinceEpoch(0);

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    bpm,
    timeSignatureNumerator,
    timeSignatureDenominator,
    key,
    tracks,
    markers,
    clickMap,
    createdAt,
    updatedAt,
  ];

  Duration get duration {
    if (tracks.isEmpty) return Duration.zero;
    return tracks.map((t) => t.duration).reduce((a, b) => a > b ? a : b);
  }

  /// Master waveform peaks composed only from musical tracks (excludes click, metronome, guide).
  /// Filters: has waveformPeaks, not muted, not utility; sums bins then normalizes max to 1.0.
  /// Master waveform: 400 bins for high-density display (handles legacy 150 bins in UI).
  static const int _masterWaveformBins = 400;

  List<double> get masterWaveformPeaks =>
      computeMasterWaveformPeaks(tracks, numBins: _masterWaveformBins);

  /// Shared composition logic: musical tracks only, sum then normalize.
  /// Used by Music, SetlistItem (via originalMusic), and CreateMusicStore.
  /// [getPeaks] optional: e.g. (t) => t.waveformPeaks ?? store.waveformData[t.id]
  static List<double> computeMasterWaveformPeaks(
    List<Track> tracks, {
    int numBins = 400,
    List<double>? Function(Track t)? getPeaks,
  }) {
    if (tracks.isEmpty) return [];

    List<double>? peaksFor(Track t) =>
        getPeaks != null ? getPeaks(t) : t.waveformPeaks;

    final withPeaks = tracks.where((t) {
      final p = peaksFor(t);
      final hasPeaks = p != null && p.isNotEmpty;
      return hasPeaks && !t.isMuted && !t.isUtilityTrack;
    }).toList();

    if (withPeaks.isEmpty) {
      final fallback = tracks.where((t) {
        final p = peaksFor(t);
        return p != null && p.isNotEmpty && !t.isMuted;
      }).toList();
      if (fallback.isEmpty) return [];
      return _sumAndNormalize(fallback, numBins, peaksFor);
    }

    return _sumAndNormalize(withPeaks, numBins, peaksFor);
  }

  static List<double> _sumAndNormalize(
    List<Track> tracks,
    int numBins,
    List<double>? Function(Track t) getPeaks,
  ) {
    final result = List<double>.filled(numBins, 0.0);
    for (final t in tracks) {
      final p = getPeaks(t)!;
      if (p.isEmpty) continue;
      if (p.length == numBins) {
        for (var i = 0; i < numBins; i++) {
          result[i] += p[i].clamp(0.0, 1.0);
        }
      } else {
        for (var i = 0; i < numBins; i++) {
          final srcIdx = numBins <= 1
              ? 0.0
              : (i * (p.length - 1)) / (numBins - 1);
          final idx = srcIdx.floor().clamp(0, p.length - 1);
          final next = (idx + 1).clamp(0, p.length - 1);
          final frac = srcIdx - idx;
          final v = p[idx] * (1 - frac) + p[next] * frac;
          result[i] += v.clamp(0.0, 1.0);
        }
      }
    }
    final maxVal = result.isEmpty
        ? 0.0
        : result.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return result;
    return result.map((v) => v / maxVal).toList();
  }

  Music copyWith({
    String? id,
    String? title,
    String? artist,
    int? bpm,
    int? timeSignatureNumerator,
    int? timeSignatureDenominator,
    String? key,
    List<Track>? tracks,
    List<Marker>? markers,
    List<int>? clickMap,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Music(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      bpm: bpm ?? this.bpm,
      timeSignatureNumerator:
          timeSignatureNumerator ?? this.timeSignatureNumerator,
      timeSignatureDenominator:
          timeSignatureDenominator ?? this.timeSignatureDenominator,
      key: key ?? this.key,
      tracks: tracks ?? this.tracks,
      markers: markers ?? this.markers,
      clickMap: clickMap ?? this.clickMap,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
