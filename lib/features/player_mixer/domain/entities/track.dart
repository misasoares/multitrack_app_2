import 'package:equatable/equatable.dart';

class Track extends Equatable {
  final String id;
  final String name;
  final String filePath;
  final double volume;
  final double pan; // -1.0 (Left 100%) to 1.0 (Right 100%), 0.0 = Center
  final bool isMuted;
  final bool isSolo;
  final bool isClick;
  final int order; // Position index in the UI list
  final Duration duration;

  const Track({
    required this.id,
    required this.name,
    required this.filePath,
    this.volume = 1.0,
    this.pan = 1.0,
    this.isMuted = false,
    this.isSolo = false,
    this.isClick = false,
    this.order = 0,
    this.duration = Duration.zero,
  });

  Track copyWith({
    String? id,
    String? name,
    String? filePath,
    double? volume,
    double? pan,
    bool? isMuted,
    bool? isSolo,
    bool? isClick,
    int? order,
    Duration? duration,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      isClick: isClick ?? this.isClick,
      order: order ?? this.order,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    filePath,
    volume,
    pan,
    isMuted,
    isSolo,
    isClick,
    order,
    duration,
  ];
}
