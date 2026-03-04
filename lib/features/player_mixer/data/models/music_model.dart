import 'package:isar/isar.dart';
import '../../domain/entities/music.dart';
import 'track_model.dart';
import 'eq_band_model.dart';
import 'marker_model.dart';

part 'music_model.g.dart';

@collection
class MusicModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? domainId;

  String? title;
  String? artist;
  int? bpm;
  int? timeSignatureNumerator;
  int? timeSignatureDenominator;
  String? key;

  List<TrackModel>? tracks;
  List<MarkerModel>? markers;
  List<int>? clickMap;

  DateTime? createdAt;
  DateTime? updatedAt;

  MusicModel({
    this.domainId,
    this.title,
    this.artist,
    this.bpm,
    this.timeSignatureNumerator,
    this.timeSignatureDenominator,
    this.key,
    this.tracks,
    this.markers,
    this.clickMap,
    this.createdAt,
    this.updatedAt,
  });

  factory MusicModel.fromEntity(Music music) {
    return MusicModel(
      domainId: music.id,
      title: music.title,
      artist: music.artist,
      bpm: music.bpm,
      timeSignatureNumerator: music.timeSignatureNumerator,
      timeSignatureDenominator: music.timeSignatureDenominator,
      key: music.key,
      tracks: music.tracks.map((t) => TrackModel.fromEntity(t)).toList(),
      markers: music.markers.map((m) => MarkerModel.fromEntity(m)).toList(),
      clickMap: music.clickMap.isNotEmpty ? music.clickMap : null,
      createdAt: music.createdAt,
      updatedAt: music.updatedAt,
    );
  }

  Music toEntity() {
    return Music(
      id: domainId ?? '',
      title: title ?? '',
      artist: artist ?? '',
      bpm: bpm ?? 0,
      timeSignatureNumerator: timeSignatureNumerator ?? 4,
      timeSignatureDenominator: timeSignatureDenominator ?? 4,
      key: key ?? '',
      tracks: tracks?.map((t) => t.toEntity()).toList() ?? [],
      markers: markers?.map((m) => m.toEntity()).toList() ?? [],
      clickMap: clickMap ?? const [],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
