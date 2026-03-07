import 'package:equatable/equatable.dart';

class Marker extends Equatable {
  final String id;
  final String label; // e.g., "Verse 1", "Chorus"
  final Duration timestamp;
  final String colorHex; // For UI visualization

  const Marker({
    required this.id,
    required this.label,
    required this.timestamp,
    required this.colorHex,
  });

  Marker copyWith({
    String? id,
    String? label,
    Duration? timestamp,
    String? colorHex,
  }) {
    return Marker(
      id: id ?? this.id,
      label: label ?? this.label,
      timestamp: timestamp ?? this.timestamp,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [id, label, timestamp, colorHex];
}
