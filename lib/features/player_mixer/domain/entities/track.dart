import 'package:equatable/equatable.dart';

class Track extends Equatable {
  final String id;
  final String name;
  final String filePath;
  final double volume;
  final bool isMuted;
  final bool isSolo;
  final bool isClick; // Metronome/Click track

  const Track({
    required this.id,
    required this.name,
    required this.filePath,
    this.volume = 1.0,
    this.isMuted = false,
    this.isSolo = false,
    this.isClick = false,
  });

  Track copyWith({
    String? id,
    String? name,
    String? filePath,
    double? volume,
    bool? isMuted,
    bool? isSolo,
    bool? isClick,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      isClick: isClick ?? this.isClick,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    filePath,
    volume,
    isMuted,
    isSolo,
    isClick,
  ];
}
