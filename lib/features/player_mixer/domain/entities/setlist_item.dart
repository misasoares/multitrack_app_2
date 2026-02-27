import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'music.dart';
import 'eq_band_data.dart';

class SetlistItem extends Equatable {
  final String id;
  final Music originalMusic;
  final double volume; // 1.0 = 100%
  final double tempoFactor; // 1.0 = 100%
  final int transposeSemitones;
  final List<EqBandData> masterEqBands;
  final List<String> transposableTrackIds;
  /// Path to this item's exported folder (e.g. shows/{setlistId}/{itemId}).
  final String? exportedItemDirectory;

  const SetlistItem({
    required this.id,
    required this.originalMusic,
    this.volume = 1.0,
    this.tempoFactor = 1.0,
    this.transposeSemitones = 0,
    this.masterEqBands = const [],
    this.transposableTrackIds = const [],
    this.exportedItemDirectory,
  });

  factory SetlistItem.fromMusic(Music music) {
    return SetlistItem(id: const Uuid().v4(), originalMusic: music);
  }

  SetlistItem copyWith({
    String? id,
    Music? originalMusic,
    double? volume,
    double? tempoFactor,
    int? transposeSemitones,
    List<EqBandData>? masterEqBands,
    List<String>? transposableTrackIds,
    String? exportedItemDirectory,
  }) {
    return SetlistItem(
      id: id ?? this.id,
      originalMusic: originalMusic ?? this.originalMusic,
      volume: volume ?? this.volume,
      tempoFactor: tempoFactor ?? this.tempoFactor,
      transposeSemitones: transposeSemitones ?? this.transposeSemitones,
      masterEqBands: masterEqBands ?? this.masterEqBands,
      transposableTrackIds: transposableTrackIds ?? this.transposableTrackIds,
      exportedItemDirectory: exportedItemDirectory ?? this.exportedItemDirectory,
    );
  }

  @override
  List<Object?> get props => [
    id,
    originalMusic,
    volume,
    tempoFactor,
    transposeSemitones,
    masterEqBands,
    transposableTrackIds,
    exportedItemDirectory,
  ];
}
