import 'package:isar/isar.dart';
import '../../domain/entities/setlist_item.dart';
import '../../domain/entities/music.dart';
import 'track_model.dart';
import 'marker_model.dart';
import 'eq_band_model.dart';

part 'setlist_item_model.g.dart';

@embedded
class SetlistItemModel {
  String? id;

  // Snapshot of Music fields
  String? originalMusicId;
  String? originalMusicTitle;
  String? originalMusicArtist;
  int? originalMusicBpm;
  int? originalMusicTimeSignatureNumerator;
  int? originalMusicTimeSignatureDenominator;
  String? originalMusicKey;
  List<TrackModel>? originalMusicTracks;
  List<MarkerModel>? originalMusicMarkers;
  DateTime? originalMusicCreatedAt;
  DateTime? originalMusicUpdatedAt;

  // Mastering fields
  double? volume;
  double? tempoFactor;
  int? transposeSemitones;
  List<EqBandModel>? masterEqBands;
  List<String>? transposableTrackIds;

  SetlistItemModel({
    this.id,
    this.originalMusicId,
    this.originalMusicTitle,
    this.originalMusicArtist,
    this.originalMusicBpm,
    this.originalMusicTimeSignatureNumerator,
    this.originalMusicTimeSignatureDenominator,
    this.originalMusicKey,
    this.originalMusicTracks,
    this.originalMusicMarkers,
    this.originalMusicCreatedAt,
    this.originalMusicUpdatedAt,
    this.volume,
    this.tempoFactor,
    this.transposeSemitones,
    this.masterEqBands,
    this.transposableTrackIds,
  });

  factory SetlistItemModel.fromEntity(SetlistItem item) {
    return SetlistItemModel(
      id: item.id,
      originalMusicId: item.originalMusic.id,
      originalMusicTitle: item.originalMusic.title,
      originalMusicArtist: item.originalMusic.artist,
      originalMusicBpm: item.originalMusic.bpm,
      originalMusicTimeSignatureNumerator:
          item.originalMusic.timeSignatureNumerator,
      originalMusicTimeSignatureDenominator:
          item.originalMusic.timeSignatureDenominator,
      originalMusicKey: item.originalMusic.key,
      originalMusicTracks: item.originalMusic.tracks
          .map((t) => TrackModel.fromEntity(t))
          .toList(),
      originalMusicMarkers: item.originalMusic.markers
          .map((m) => MarkerModel.fromEntity(m))
          .toList(),
      originalMusicCreatedAt: item.originalMusic.createdAt,
      originalMusicUpdatedAt: item.originalMusic.updatedAt,
      volume: item.volume,
      tempoFactor: item.tempoFactor,
      transposeSemitones: item.transposeSemitones,
      masterEqBands: item.masterEqBands
          .map((e) => EqBandModel.fromEntity(e))
          .toList(),
      transposableTrackIds: item.transposableTrackIds,
    );
  }

  SetlistItem toEntity() {
    return SetlistItem(
      id: id ?? '',
      originalMusic: Music(
        id: originalMusicId ?? '',
        title: originalMusicTitle ?? '',
        artist: originalMusicArtist ?? '',
        bpm: originalMusicBpm ?? 120,
        timeSignatureNumerator: originalMusicTimeSignatureNumerator ?? 4,
        timeSignatureDenominator: originalMusicTimeSignatureDenominator ?? 4,
        key: originalMusicKey ?? '',
        tracks: originalMusicTracks?.map((t) => t.toEntity()).toList() ?? [],
        markers: originalMusicMarkers?.map((m) => m.toEntity()).toList() ?? [],
        createdAt: originalMusicCreatedAt,
        updatedAt: originalMusicUpdatedAt,
      ),
      volume: volume ?? 1.0,
      tempoFactor: tempoFactor ?? 1.0,
      transposeSemitones: transposeSemitones ?? 0,
      masterEqBands: masterEqBands?.map((e) => e.toEntity()).toList() ?? [],
      transposableTrackIds: transposableTrackIds ?? [],
    );
  }
}
