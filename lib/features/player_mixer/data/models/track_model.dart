import 'package:isar/isar.dart';
import '../../domain/entities/track.dart';

part 'track_model.g.dart';

@embedded
class TrackModel {
  String? id;
  String? name;
  String? filePath;
  double? volume;
  bool? isMuted;
  bool? isSolo;
  bool? isClick;

  TrackModel({
    this.id,
    this.name,
    this.filePath,
    this.volume,
    this.isMuted,
    this.isSolo,
    this.isClick,
  });

  factory TrackModel.fromEntity(Track track) {
    return TrackModel(
      id: track.id,
      name: track.name,
      filePath: track.filePath,
      volume: track.volume,
      isMuted: track.isMuted,
      isSolo: track.isSolo,
      isClick: track.isClick,
    );
  }

  Track toEntity() {
    return Track(
      id: id ?? '',
      name: name ?? '',
      filePath: filePath ?? '',
      volume: volume ?? 1.0,
      isMuted: isMuted ?? false,
      isSolo: isSolo ?? false,
      isClick: isClick ?? false,
    );
  }
}
