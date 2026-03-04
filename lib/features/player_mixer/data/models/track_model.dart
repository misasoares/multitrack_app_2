import 'package:isar/isar.dart';
import '../../domain/entities/track.dart';
import 'eq_band_model.dart';

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
  bool? isClickTrack;
  int? order;
  int? durationInMilliseconds;
  List<EqBandModel>? eqBands;
  bool? applyTranspose;
  int? octaveShift;

  /// Pre-computed waveform peak bins (from Render Show); persisted in Isar.
  List<double>? waveformPeaks;

  TrackModel({
    this.id,
    this.name,
    this.filePath,
    this.volume,
    this.pan,
    this.isMuted,
    this.isSolo,
    this.isClick,
    this.isClickTrack,
    this.order,
    this.durationInMilliseconds,
    this.eqBands,
    this.applyTranspose,
    this.octaveShift,
    this.waveformPeaks,
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
      isClickTrack: track.isClickTrack,
      order: track.order,
      durationInMilliseconds: track.duration.inMilliseconds,
      eqBands: track.eqBands.isNotEmpty
          ? track.eqBands.map((b) => EqBandModel.fromEntity(b)).toList()
          : null,
      applyTranspose: track.applyTranspose,
      octaveShift: track.octaveShift,
      waveformPeaks: track.waveformPeaks,
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
      isClickTrack: isClickTrack ?? false,
      order: order ?? 0,
      duration: Duration(milliseconds: durationInMilliseconds ?? 0),
      eqBands: eqBands?.map((b) => b.toEntity()).toList() ?? const [],
      applyTranspose: applyTranspose ?? true,
      octaveShift: octaveShift ?? 0,
      waveformPeaks: waveformPeaks,
    );
  }
}
