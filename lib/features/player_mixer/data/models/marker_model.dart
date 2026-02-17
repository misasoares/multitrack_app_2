import 'package:isar/isar.dart';
import '../../domain/entities/marker.dart';

part 'marker_model.g.dart';

@embedded
class MarkerModel {
  String? id;
  String? label;
  int? timestampMs; // Isar doesn't support Duration directly
  String? colorHex;

  MarkerModel({this.id, this.label, this.timestampMs, this.colorHex});

  factory MarkerModel.fromEntity(Marker marker) {
    return MarkerModel(
      id: marker.id,
      label: marker.label,
      timestampMs: marker.timestamp.inMilliseconds,
      colorHex: marker.colorHex,
    );
  }

  Marker toEntity() {
    return Marker(
      id: id ?? '',
      label: label ?? '',
      timestamp: Duration(milliseconds: timestampMs ?? 0),
      colorHex: colorHex ?? '#FFFFFF',
    );
  }
}
