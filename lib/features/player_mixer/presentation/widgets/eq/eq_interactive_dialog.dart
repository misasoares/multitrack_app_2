import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../../core/audio_engine/audio_dsp_service.dart';
import '../../../domain/entities/eq_band_data.dart';
import 'eq_painter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EqInteractiveDialog — 3-Band Parametric EQ with real-time DSP control
// ─────────────────────────────────────────────────────────────────────────────

/// Opens a full-featured parametric EQ dialog for a given [trackId].
///
/// The dialog draws 3 draggable band nodes (Low, Mid, High) over a
/// frequency-response graph. Dragging updates the native C++ engine
/// in real time via [AudioDspService].
///
/// [initialBands] — EQ state from memory (restores node positions).
/// [onBandChanged] — callback to sync band state back to the Store.
class EqInteractiveDialog extends StatefulWidget {
  final String trackId;
  final AudioDspService dspService;
  final List<EqBandData> initialBands;
  final ValueChanged<EqBandData>? onBandChanged;

  const EqInteractiveDialog({
    super.key,
    required this.trackId,
    required this.dspService,
    this.initialBands = const [],
    this.onBandChanged,
  });

  @override
  State<EqInteractiveDialog> createState() => _EqInteractiveDialogState();
}

class _EqInteractiveDialogState extends State<EqInteractiveDialog> {
  // ── Band state (ValueNotifier for surgical rebuilds → 60 fps) ─────────

  static const _bandColors = [
    Color(0xFFE53935), // Low Cut — red
    Color(0xFF4CAF50), // Low  — green
    Color(0xFFF9AC06), // Mid  — amber (primary)
    Color(0xFF42A5F5), // High — blue
    Color(0xFF8E24AA), // High Cut - purple
  ];

  late final List<ValueNotifier<EqBandData>> _bands;
  int? _activeBandIndex;

  // Cached paint size for coordinate conversion during gestures.
  Size _paintSize = Size.zero;

  @override
  void initState() {
    super.initState();

    _bands = List.generate(AudioDspService.bandCount, (i) {
      // Restore from in-memory state if available, otherwise use defaults.
      final saved = widget.initialBands.where((b) => b.bandIndex == i);
      if (saved.isNotEmpty) {
        return ValueNotifier(saved.first);
      }
      return ValueNotifier(
        EqBandData(
          bandIndex: i,
          type: i == 0
              ? EqFilterType.highPass
              : (i == AudioDspService.bandCount - 1
                    ? EqFilterType.lowPass
                    : EqFilterType.peaking),
          frequency: AudioDspService.defaultFrequencies[i],
          gain: 0.0,
          q: AudioDspService.defaultQ,
          label: AudioDspService.bandLabels[i],
          color: _bandColors[i],
          frequencyRange: AudioDspService.bandFrequencyRanges[i],
        ),
      );
    });
  }

  @override
  void dispose() {
    for (final n in _bands) {
      n.dispose();
    }
    super.dispose();
  }

  // ── Coordinate Conversion ─────────────────────────────────────────────────

  static const double _minFreq = 20.0;
  static const double _maxFreq = 20000.0;
  static const double _minGain = -24.0;
  static const double _maxGain = 24.0;

  /// Converts pixel X to frequency (Hz) using log scale.
  double _xToFreq(double x) {
    final ratio = x / _paintSize.width;
    return _minFreq * pow(_maxFreq / _minFreq, ratio);
  }

  /// Converts pixel Y to gain (dB) using linear scale (inverted Y axis).
  double _yToGain(double y) {
    final normalized = 1.0 - (y / _paintSize.height);
    return _minGain + normalized * (_maxGain - _minGain);
  }

  /// Converts frequency (Hz) to pixel X (for hit-testing).
  double _freqToX(double freq) {
    return _paintSize.width * log(freq / _minFreq) / log(_maxFreq / _minFreq);
  }

  /// Converts gain (dB) to pixel Y (for hit-testing).
  double _gainToY(double gain) {
    final normalized = (gain - _minGain) / (_maxGain - _minGain);
    return _paintSize.height * (1.0 - normalized);
  }

  // ── Gesture Handling ──────────────────────────────────────────────────────

  /// Hit-test: find which band node the user touched (within threshold).
  int? _hitTest(Offset position) {
    const hitRadius = 30.0;
    for (var i = 0; i < _bands.length; i++) {
      final band = _bands[i].value;
      final nodeX = _freqToX(band.frequency);
      final nodeY = _gainToY(band.gain);
      final distance = (position - Offset(nodeX, nodeY)).distance;
      if (distance <= hitRadius) return i;
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    final idx = _hitTest(details.localPosition);
    setState(() => _activeBandIndex = idx);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final idx = _activeBandIndex;
    if (idx == null) return;

    final pos = details.localPosition;
    final band = _bands[idx].value;

    // Convert pixel position to frequency and gain.
    var newFreq = _xToFreq(pos.dx);
    var newGain = _yToGain(pos.dy);

    // Clamp to band's frequency range.
    final (fMin, fMax) = band.frequencyRange;
    newFreq = newFreq.clamp(fMin, fMax);
    if (band.type == EqFilterType.highPass ||
        band.type == EqFilterType.lowPass) {
      newGain = 0.0; // Cut filters don't have gain in this implementation
    } else {
      newGain = newGain.clamp(_minGain, _maxGain);
    }

    // Update the ValueNotifier (triggers CustomPainter repaint only).
    final updated = band.copyWith(frequency: newFreq, gain: newGain);
    _bands[idx].value = updated;

    // Send to C++ engine in real time.
    widget.dspService.setBandEq(
      trackId: widget.trackId,
      bandIndex: idx,
      filterType: band.type.index,
      frequency: newFreq,
      gain: newGain,
      q: band.q,
    );

    // Sync state back to the Store (memory only).
    widget.onBandChanged?.call(updated);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _activeBandIndex = null);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _resetAllBands() {
    for (var i = 0; i < _bands.length; i++) {
      final band = _bands[i].value;
      final reset = band.copyWith(
        frequency: AudioDspService.defaultFrequencies[i],
        gain: 0.0,
        q: AudioDspService.defaultQ,
      );
      _bands[i].value = reset;

      // Reset on C++ engine too.
      widget.dspService.setBandEq(
        trackId: widget.trackId,
        bandIndex: i,
        filterType: reset.type.index,
        frequency: AudioDspService.defaultFrequencies[i],
        gain: 0.0,
        q: AudioDspService.defaultQ,
      );

      // Sync reset state to Store.
      widget.onBandChanged?.call(reset);
    }
    setState(() => _activeBandIndex = null);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildEqGraph(),
                const SizedBox(height: 12),
                _buildBandReadouts(),
                const SizedBox(height: 8),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.equalizer_rounded, color: Color(0xFFF9AC06), size: 22),
        const SizedBox(width: 8),
        const Text(
          'Parametric EQ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildEqGraph() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _paintSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                size: _paintSize,
                painter: EqPainter(
                  bandNotifiers: _bands,
                  activeBandIndex: _activeBandIndex,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBandReadouts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(AudioDspService.bandCount, (i) {
        return ValueListenableBuilder<EqBandData>(
          valueListenable: _bands[i],
          builder: (context, band, _) {
            final freqLabel = band.frequency >= 1000
                ? '${(band.frequency / 1000).toStringAsFixed(1)}kHz'
                : '${band.frequency.toInt()}Hz';
            final gainLabel =
                '${band.gain >= 0 ? '+' : ''}${band.gain.toStringAsFixed(1)}dB';

            return Column(
              children: [
                Text(
                  band.label,
                  style: TextStyle(
                    color: band.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  freqLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  gainLabel,
                  style: TextStyle(
                    color: band.gain.abs() > 0.5
                        ? band.color
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _resetAllBands,
          icon: const Icon(Icons.restart_alt_rounded, size: 16),
          label: const Text('Reset'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white54,
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
