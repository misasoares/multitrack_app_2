import 'package:isar/isar.dart';
import '../../domain/entities/marker.dart';

part 'marker_model.g.dart';

@embedded
class MarkerModel {
  String? id;
  String? label;
  int? timestampMicros; // Isar doesn't support Duration directly
  String? colorHex;

  MarkerModel({this.id, this.label, this.timestampMicros, this.colorHex});

  factory MarkerModel.fromEntity(Marker marker) {
    return MarkerModel(
      id: marker.id,
      label: marker.label,
      timestampMicros: marker.timestamp.inMicroseconds,
      colorHex: marker.colorHex,
    );
  }

  Marker toEntity() {
    return Marker(
      id: id ?? '',
      label: label ?? '',
      timestamp: Duration(microseconds: timestampMicros ?? 0),
      colorHex: colorHex ?? '#FFFFFF',
    );
  }
}
