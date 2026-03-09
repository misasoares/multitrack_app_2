import 'package:equatable/equatable.dart';
import 'eq_band_data.dart';

class Track extends Equatable {
  final String id;
  final String name;
  final String filePath;
  final double volume;
  final double pan; // -1.0 (Left 100%) to 1.0 (Right 100%), 0.0 = Center
  final bool isMuted;
  final bool isSolo;
  final bool isClick;
  final bool isClickTrack;
  final int order; // Position index in the UI list
  final Duration duration;
  final List<EqBandData> eqBands; // Parametric EQ state (persisted on save)
  final bool applyTranspose;
  final int octaveShift; // 0, 1, or -1
  /// Pre-computed waveform peak bins (e.g. from Render Show); null if not yet computed.
  final List<double>? waveformPeaks;

  /// True if this track is a utility track (click, metronome, guide voice, etc.)
  /// and should be excluded from the master waveform composition.
  bool get isUtilityTrack => checkIsUtility(name, isClick: isClick);

  /// Helper to check if a track name or flag indicates a utility track.
  static bool checkIsUtility(String name, {bool isClick = false}) {
    final lowerName = name.toLowerCase();
    // DEFENSIVE: Always treat as utility if name contains 'click' or 'guia',
    // or if the explicit database flag (isClick) is set.
    if (isClick ||
        lowerName.contains('click') ||
        lowerName.contains('guia') ||
        lowerName.contains('click track')) {
      return true;
    }
    // Broader regex for other utility keywords (optional/extra insurance)
    const extraPattern =
        r'\b(metronomo|metronome|guide|guias|voz guia|locucao)\b';
    return RegExp(extraPattern, caseSensitive: false).hasMatch(name);
  }

  /// Helper to check if a track name indicates it's a Click/Metronome.
  static bool checkIsClick(String name) {
    final lowerName = name.toLowerCase();
    return lowerName.contains('click') ||
        lowerName.contains('metronomo') ||
        lowerName.contains('metronome');
  }

  const Track({
    required this.id,
    required this.name,
    required this.filePath,
    this.volume = 1.0,
    this.pan = 1.0,
    this.isMuted = false,
    this.isSolo = false,
    this.isClick = false,
    this.isClickTrack = false,
    this.order = 0,
    this.duration = Duration.zero,
    this.eqBands = const [],
    this.applyTranspose = true,
    this.octaveShift = 0,
    this.waveformPeaks,
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
    bool? isClickTrack,
    int? order,
    Duration? duration,
    List<EqBandData>? eqBands,
    bool? applyTranspose,
    int? octaveShift,
    List<double>? waveformPeaks,
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
      isClickTrack: isClickTrack ?? this.isClickTrack,
      order: order ?? this.order,
      duration: duration ?? this.duration,
      eqBands: eqBands ?? this.eqBands,
      applyTranspose: applyTranspose ?? this.applyTranspose,
      octaveShift: octaveShift ?? this.octaveShift,
      waveformPeaks: waveformPeaks ?? this.waveformPeaks,
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
    isClickTrack,
    order,
    duration,
    eqBands,
    applyTranspose,
    octaveShift,
    waveformPeaks,
  ];
}
