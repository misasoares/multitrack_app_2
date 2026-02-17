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

  @override
  List<Object?> get props => [id, label, timestamp, colorHex];
}
