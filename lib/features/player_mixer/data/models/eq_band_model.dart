import 'package:isar/isar.dart';
import '../../domain/entities/eq_band_data.dart';

part 'eq_band_model.g.dart';

/// Isar embedded object for persisting a single EQ band.
///
/// Stores only the DSP-relevant data (bandIndex, frequency, gain, q).
/// Visual metadata (color, label, frequencyRange) is reconstructed at runtime
/// from [AudioDspService] constants.
@embedded
class EqBandModel {
  int? bandIndex;
  double? frequency;
  double? gainDb;
  double? q;

  EqBandModel({this.bandIndex, this.frequency, this.gainDb, this.q});

  factory EqBandModel.fromEntity(EqBandData band) {
    return EqBandModel(
      bandIndex: band.bandIndex,
      frequency: band.frequency,
      gainDb: band.gain,
      q: band.q,
    );
  }

  EqBandData toEntity() {
    return EqBandData.fromPersisted(
      bandIndex: bandIndex ?? 0,
      frequency: frequency ?? 1000.0,
      gain: gainDb ?? 0.0,
      q: q ?? 1.0,
    );
  }
}
