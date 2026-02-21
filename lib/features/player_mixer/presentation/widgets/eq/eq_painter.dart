import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../domain/entities/eq_band_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EqPainter — CustomPainter for the parametric EQ frequency response graph
// ─────────────────────────────────────────────────────────────────────────────

/// Draws a professional EQ frequency-response graph with:
/// - Log-scaled frequency grid (X axis)
/// - Linear gain grid (Y axis) with a 0 dB reference line
/// - Smooth bézier curve through the 3 band nodes
/// - Draggable node circles with glow effects
///
/// Repaints only when any of the [bandNotifiers] fires, keeping 60 fps
/// during gesture-driven updates.
class EqPainter extends CustomPainter {
  final List<ValueNotifier<EqBandData>> bandNotifiers;
  final int? activeBandIndex;

  // ── Frequency / Gain constants ────────────────────────────────────────────

  static const double _minFreq = 20.0;
  static const double _maxFreq = 20000.0;
  static const double _minGain = -24.0;
  static const double _maxGain = 24.0;

  // ── Grid label frequencies ────────────────────────────────────────────────
  static const List<double> _gridFrequencies = [
    50,
    100,
    200,
    500,
    1000,
    2000,
    5000,
    10000,
  ];

  // ── Grid gain lines (dB) ──────────────────────────────────────────────────
  static const List<double> _gridGains = [-18, -12, -6, 0, 6, 12, 18];

  EqPainter({required this.bandNotifiers, this.activeBandIndex})
    : super(repaint: Listenable.merge(bandNotifiers));

  // ── Coordinate Conversion ─────────────────────────────────────────────────

  /// Converts a frequency in Hz to a pixel X position (log scale).
  ///
  /// Formula: x(f) = width * log(f / fMin) / log(fMax / fMin)
  double _freqToX(double freq, double width) {
    return width * log(freq / _minFreq) / log(_maxFreq / _minFreq);
  }

  /// Converts a gain in dB to a pixel Y position (linear, inverted).
  double _gainToY(double gain, double height) {
    // Map [-24, +24] → [height, 0] (top = positive gain)
    final normalized = (gain - _minGain) / (_maxGain - _minGain); // 0..1
    return height * (1.0 - normalized);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawGrid(canvas, w, h);
    _drawCurve(canvas, w, h);
    _drawNodes(canvas, w, h);
  }

  // ── Grid ───────────────────────────────────────────────────────────────────

  void _drawGrid(Canvas canvas, double w, double h) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 0.5;

    final zeroLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.35),
      fontSize: 9,
    );

    // ── Frequency grid (vertical lines) ──
    for (final freq in _gridFrequencies) {
      final x = _freqToX(freq, w);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);

      // Label
      final label = freq >= 1000
          ? '${(freq / 1000).toStringAsFixed(0)}k'
          : '${freq.toInt()}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, h - tp.height - 2));
    }

    // ── Gain grid (horizontal lines) ──
    for (final gain in _gridGains) {
      final y = _gainToY(gain, h);
      final isZero = gain == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        isZero ? zeroLinePaint : gridPaint,
      );

      // Label
      final label = '${gain > 0 ? '+' : ''}${gain.toInt()}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle.copyWith(
            color: isZero
                ? Colors.white.withValues(alpha: 0.5)
                : textStyle.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, y - tp.height / 2));
    }
  }

  // ── Smooth Bézier Curve ────────────────────────────────────────────────────

  void _drawCurve(Canvas canvas, double w, double h) {
    final bands = bandNotifiers.map((n) => n.value).toList();

    // Build control points: start at left edge, go through each band, end at right.
    final points = <Offset>[
      Offset(0, _gainToY(bands[0].gain * 0.3, h)), // left edge fades to ~0
      ...bands.map(
        (b) => Offset(_freqToX(b.frequency, w), _gainToY(b.gain, h)),
      ),
      Offset(w, _gainToY(bands[2].gain * 0.3, h)), // right edge fades to ~0
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    // Catmull-Rom-style cubic through each segment
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // Fill area under curve with gradient
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF9AC06).withValues(alpha: 0.15),
          const Color(0xFFF9AC06).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke the curve itself
    final curvePaint = Paint()
      ..color = const Color(0xFFF9AC06)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(path, curvePaint);
  }

  // ── Draggable Nodes ────────────────────────────────────────────────────────

  void _drawNodes(Canvas canvas, double w, double h) {
    for (var i = 0; i < bandNotifiers.length; i++) {
      final band = bandNotifiers[i].value;
      final x = _freqToX(band.frequency, w);
      final y = _gainToY(band.gain, h);
      final isActive = activeBandIndex == i;
      final radius = isActive ? 14.0 : 10.0;

      // Outer glow
      if (isActive) {
        canvas.drawCircle(
          Offset(x, y),
          radius + 8,
          Paint()
            ..color = band.color.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      // Outer ring
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = band.color.withValues(alpha: isActive ? 0.4 : 0.2)
          ..style = PaintingStyle.fill,
      );

      // Inner fill
      canvas.drawCircle(
        Offset(x, y),
        radius * 0.6,
        Paint()
          ..color = band.color
          ..style = PaintingStyle.fill,
      );

      // Label below node
      final tp = TextPainter(
        text: TextSpan(
          text: band.label,
          style: TextStyle(
            color: band.color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y + radius + 4));
    }
  }

  @override
  bool shouldRepaint(covariant EqPainter oldDelegate) {
    return activeBandIndex != oldDelegate.activeBandIndex;
  }
}
