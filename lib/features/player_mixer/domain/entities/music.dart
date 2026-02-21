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
    createdAt,
    updatedAt,
    updatedAt,
  ];

  Duration get duration {
    if (tracks.isEmpty) return Duration.zero;
    return tracks.map((t) => t.duration).reduce((a, b) => a > b ? a : b);
  }
}
