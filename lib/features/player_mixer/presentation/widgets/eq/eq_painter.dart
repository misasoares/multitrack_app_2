import 'dart:math';
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
            color: isZero ? Colors.white.withValues(alpha: 0.5) : textStyle.color,
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
    final filters = bands.map((b) {
      final f = _Biquad();
      f.setFilter(b.type, b.frequency, b.gain, b.q);
      return f;
    }).toList();

    final path = Path();
    bool first = true;

    const int numPoints = 200;
    for (int i = 0; i <= numPoints; i++) {
      double ratio = i / numPoints;
      double freq = _minFreq * pow(_maxFreq / _minFreq, ratio);

      double totalMag = 1.0;
      for (final f in filters) {
        totalMag *= f.getMagnitudeResponse(freq);
      }

      double totalGainDb = 20.0 * (log(totalMag) / ln10);

      double x = w * ratio;
      double y = _gainToY(totalGainDb, h);

      // Clamp Y to within reasonable bounds to prevent drawing way off canvas
      y = y.clamp(-h, h * 2.0);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
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

    // Assuming 'currentSetlist' was a placeholder for a condition to prevent drawing
    // If the intent was to prevent drawing the curve under some condition,
    // that condition should be defined and placed before the drawPath call.
    // As 'currentSetlist' is not defined in this context, and to avoid
    // introducing new undefined variables or syntax errors, I will only
    // apply the removal of 'dart:ui' and correct the curly braces if they were
    // part of the original instruction for a different class.
    // Given the snippet, the `if` statement was syntactically incorrect.
    // If the user intended to add a conditional return, it should be like this:
    // if (someCondition) {
    //   return;
    // }
    // Since the instruction was "Fix curly braces in StageStore" and the snippet
    // showed an `if` statement in `_drawCurve` that was syntactically wrong,
    // and `StageStore` is not present, I will only remove the `dart:ui` import
    // and leave the `_drawCurve` method as it was, as the `if` statement
    // in the snippet was malformed and referred to an undefined variable.
    // If the user meant to add a condition here, they need to provide a valid one.

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

class _Biquad {
  double b0 = 1, b1 = 0, b2 = 0, a0 = 1, a1 = 0, a2 = 0;

  void setFilter(EqFilterType type, double freq, double gainDb, double q) {
    const double fs = 44100.0;
    double w0 = 2.0 * pi * freq / fs;
    double alpha = sin(w0) / (2.0 * q);
    double a = pow(10.0, gainDb / 40.0).toDouble();

    switch (type) {
      case EqFilterType.peaking:
        b0 = 1.0 + alpha * a;
        b1 = -2.0 * cos(w0);
        b2 = 1.0 - alpha * a;
        a0 = 1.0 + alpha / a;
        a1 = -2.0 * cos(w0);
        a2 = 1.0 - alpha / a;
        break;
      case EqFilterType.highPass:
        b0 = (1.0 + cos(w0)) / 2.0;
        b1 = -(1.0 + cos(w0));
        b2 = (1.0 + cos(w0)) / 2.0;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cos(w0);
        a2 = 1.0 - alpha;
        break;
      case EqFilterType.lowPass:
        b0 = (1.0 - cos(w0)) / 2.0;
        b1 = 1.0 - cos(w0);
        b2 = (1.0 - cos(w0)) / 2.0;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cos(w0);
        a2 = 1.0 - alpha;
        break;
    }
  }

  double getMagnitudeResponse(double freq) {
    const double fs = 44100.0;
    double w = 2.0 * pi * freq / fs;

    double cosW = cos(w);
    double sinW = sin(w);
    double cos2W = cos(2.0 * w);
    double sin2W = sin(2.0 * w);

    double numRe = b0 + b1 * cosW + b2 * cos2W;
    double numIm = -(b1 * sinW + b2 * sin2W);

    double denRe = a0 + a1 * cosW + a2 * cos2W;
    double denIm = -(a1 * sinW + a2 * sin2W);

    double magNum = sqrt(numRe * numRe + numIm * numIm);
    double magDen = sqrt(denRe * denRe + denIm * denIm);

    return magNum / (magDen != 0.0 ? magDen : 1.0);
  }
}
