import 'package:isar/isar.dart';
import '../../domain/entities/track.dart';

part 'track_model.g.dart';

@embedded
class TrackModel {
  String? id;
  String? name;
  String? filePath;
  double? volume;
  double? pan;
  bool? isMuted;
  bool? isSolo;
  bool? isClick;
  int? order;

  TrackModel({
    this.id,
    this.name,
    this.filePath,
    this.volume,
    this.pan,
    this.isMuted,
    this.isSolo,
    this.isClick,
    this.order,
  });

  factory TrackModel.fromEntity(Track track) {
    return TrackModel(
      id: track.id,
      name: track.name,
      filePath: track.filePath,
      volume: track.volume,
      pan: track.pan,
      isMuted: track.isMuted,
      isSolo: track.isSolo,
      isClick: track.isClick,
      order: track.order,
    );
  }

  Track toEntity() {
    return Track(
      id: id ?? '',
      name: name ?? '',
      filePath: filePath ?? '',
      volume: volume ?? 1.0,
      pan: pan ?? 0.0,
      isMuted: isMuted ?? false,
      isSolo: isSolo ?? false,
      isClick: isClick ?? false,
      order: order ?? 0,
    );
  }
}
