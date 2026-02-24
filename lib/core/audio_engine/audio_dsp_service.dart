import 'iaudio_engine_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AudioDspService — Clean DSP façade over the raw FFI engine
// ─────────────────────────────────────────────────────────────────────────────

/// Injectable service that provides a high-level API for DSP operations.
///
/// Currently exposes 3-band parametric EQ control.
/// The service delegates to [IAudioEngineService] which handles the actual
/// FFI call to the C++ engine.
class AudioDspService {
  final IAudioEngineService _engine;

  AudioDspService(this._engine);

  // ── EQ Constants ──────────────────────────────────────────────────────────

  /// Number of parametric EQ bands.
  static const int bandCount = 5;

  /// Global frequency range for the EQ graph (Hz).
  static const double minFrequency = 20.0;
  static const double maxFrequency = 20000.0;

  /// Gain range in dB.
  static const double minGainDb = -24.0;
  static const double maxGainDb = 24.0;

  /// Default Q factor per band.
  static const double defaultQ = 1.0;

  /// Default center frequencies per band index.
  static const List<double> defaultFrequencies = [
    100.0, // Low Cut
    250.0, // Low
    1000.0, // Mid
    4000.0, // High
    10000.0, // High Cut
  ];

  /// Frequency range constraints per band (min, max) in Hz.
  /// These prevent bands from overlapping excessively.
  static const List<(double, double)> bandFrequencyRanges = [
    (20.0, 200.0), // Low Cut
    (100.0, 1000.0), // Low
    (500.0, 5000.0), // Mid
    (2000.0, 10000.0), // High
    (5000.0, 20000.0), // High Cut
  ];

  /// Band labels.
  static const List<String> bandLabels = [
    'Low Cut',
    'Low',
    'Mid',
    'High',
    'High Cut',
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Sets a parametric EQ band in real time on the native C++ engine.
  ///
  /// This is designed to be called at high frequency during gesture updates
  /// (e.g. 60 fps drag) — the underlying FFI call is synchronous and fast.
  void setBandEq({
    required String trackId,
    required int bandIndex,
    required int filterType,
    required double frequency,
    required double gain,
    required double q,
  }) {
    assert(bandIndex >= 0 && bandIndex < bandCount);
    assert(
      frequency >= minFrequency && frequency <= maxFrequency,
      'Frequency $frequency out of range [$minFrequency, $maxFrequency]',
    );
    assert(
      gain >= minGainDb && gain <= maxGainDb,
      'Gain $gain out of range [$minGainDb, $maxGainDb]',
    );

    if (trackId.startsWith('master')) {
      _engine.setMasterEq(
        bandIndex: bandIndex,
        filterType: filterType,
        frequency: frequency,
        gain: gain,
        q: q,
      );
    } else {
      _engine.setTrackEq(
        trackId: trackId,
        bandIndex: bandIndex,
        filterType: filterType,
        frequency: frequency,
        gain: gain,
        q: q,
      );
    }
  }

  /// Sets a parametric EQ band for the Master Output.
  void setMasterEq({
    required int bandIndex,
    required int filterType,
    required double frequency,
    required double gain,
    required double q,
  }) {
    assert(bandIndex >= 0 && bandIndex < bandCount);
    _engine.setMasterEq(
      bandIndex: bandIndex,
      filterType: filterType,
      frequency: frequency,
      gain: gain,
      q: q,
    );
  }
}
