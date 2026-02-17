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

  const Music({
    required this.id,
    required this.title,
    this.artist = '',
    required this.bpm,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    this.key = '',
    this.tracks = const [],
    this.markers = const [],
  });

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
  ];
}
