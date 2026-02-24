import 'package:flutter/material.dart';

import '../../../../core/audio_engine/audio_dsp_service.dart';

/// Supported filter types for the Parametric EQ.
enum EqFilterType { highPass, peaking, lowPass }

/// Immutable data class representing a single parametric EQ band.
///
/// Used internally by the EQ dialog to store per-band state.
/// Each band has a center [frequency] (Hz), [gain] (dB), [q] factor,
/// and visual metadata ([label], [color], [frequencyRange]).
class EqBandData {
  /// Band index (0 = Low Cut, 1 = Low, ..., 4 = High Cut).
  final int bandIndex;

  /// The type of filter this band represents.
  final EqFilterType type;

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
    Color(0xFFE53935), // Low Cut — red
    Color(0xFF4CAF50), // Low  — green
    Color(0xFFF9AC06), // Mid  — amber
    Color(0xFF42A5F5), // High — blue
    Color(0xFF8E24AA), // High Cut - purple
  ];

  const EqBandData({
    required this.bandIndex,
    required this.type,
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
    required EqFilterType type,
    required double frequency,
    required double gain,
    required double q,
  }) {
    return EqBandData(
      bandIndex: bandIndex,
      type: type,
      frequency: frequency,
      gain: gain,
      q: q,
      label: AudioDspService.bandLabels[bandIndex],
      color: _bandColors[bandIndex],
      frequencyRange: AudioDspService.bandFrequencyRanges[bandIndex],
    );
  }

  /// Creates a copy with selectively overridden fields.
  EqBandData copyWith({
    EqFilterType? type,
    double? frequency,
    double? gain,
    double? q,
  }) {
    return EqBandData(
      bandIndex: bandIndex,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      gain: gain ?? this.gain,
      q: q ?? this.q,
      label: label,
      color: color,
      frequencyRange: frequencyRange,
    );
  }
}
