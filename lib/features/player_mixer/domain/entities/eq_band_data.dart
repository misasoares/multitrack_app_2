import 'package:flutter/material.dart';

import '../../../../core/audio_engine/audio_dsp_service.dart';

/// Immutable data class representing a single parametric EQ band.
///
/// Used internally by the EQ dialog to store per-band state.
/// Each band has a center [frequency] (Hz), [gain] (dB), [q] factor,
/// and visual metadata ([label], [color], [frequencyRange]).
class EqBandData {
  /// Band index (0 = Low, 1 = Mid, 2 = High).
  final int bandIndex;

  /// Center frequency in Hz.
  final double frequency;

  /// Gain in dB (-24 to +24).
  final double gain;

  /// Quality factor (bandwidth).
  final double q;

  /// Display label (e.g. "Low", "Mid", "High").
  final String label;

  /// Node color for the EQ graph.
  final Color color;

  /// Allowed frequency range for this band (min, max) in Hz.
  final (double, double) frequencyRange;

  static const _bandColors = [
    Color(0xFF4CAF50), // Low  — green
    Color(0xFFF9AC06), // Mid  — amber
    Color(0xFF42A5F5), // High — blue
  ];

  const EqBandData({
    required this.bandIndex,
    required this.frequency,
    required this.gain,
    required this.q,
    required this.label,
    required this.color,
    required this.frequencyRange,
  });

  /// Reconstructs from persisted DSP-only data, rebuilding visual metadata.
  factory EqBandData.fromPersisted({
    required int bandIndex,
    required double frequency,
    required double gain,
    required double q,
  }) {
    return EqBandData(
      bandIndex: bandIndex,
      frequency: frequency,
      gain: gain,
      q: q,
      label: AudioDspService.bandLabels[bandIndex],
      color: _bandColors[bandIndex],
      frequencyRange: AudioDspService.bandFrequencyRanges[bandIndex],
    );
  }

  /// Creates a copy with selectively overridden fields.
  EqBandData copyWith({double? frequency, double? gain, double? q}) {
    return EqBandData(
      bandIndex: bandIndex,
      frequency: frequency ?? this.frequency,
      gain: gain ?? this.gain,
      q: q ?? this.q,
      label: label,
      color: color,
      frequencyRange: frequencyRange,
    );
  }
}
