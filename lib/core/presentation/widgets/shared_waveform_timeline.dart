import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../../features/player_mixer/domain/entities/marker.dart';

class SharedWaveformTimeline extends StatelessWidget {
  final List<double> peaks;
  final double progress; // 0.0 to 1.0
  final bool isPlaying;
  final Duration duration;
  final List<Marker> markers;

  // Callbacks for scrubbing
  final void Function(Duration newPosition)? onScrubStart;
  final void Function(Duration newPosition)? onScrubUpdate;
  final void Function()? onScrubEnd;

  const SharedWaveformTimeline({
    super.key,
    required this.peaks,
    required this.progress,
    required this.isPlaying,
    required this.duration,
    this.markers = const [],
    this.onScrubStart,
    this.onScrubUpdate,
    this.onScrubEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (peaks.isEmpty) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white12,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Desenhando onda...',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        void handleScrub(
          Offset localPosition,
          void Function(Duration)? callback,
        ) {
          if (isPlaying || callback == null) return;
          final percentage = (localPosition.dx / width).clamp(0.0, 1.0);
          final totalMicroseconds = duration.inMicroseconds;
          final newPosition = Duration(
            microseconds: (totalMicroseconds * percentage).round(),
          );
          callback(newPosition);
        }

        final gestureChild = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) =>
              handleScrub(details.localPosition, onScrubStart),
          onHorizontalDragUpdate: (details) =>
              handleScrub(details.localPosition, onScrubUpdate),
          onHorizontalDragEnd: (_) => onScrubEnd?.call(),
          onHorizontalDragCancel: () => onScrubEnd?.call(),
          onTapDown: (details) =>
              handleScrub(details.localPosition, onScrubStart),
          onTapUp: (_) => onScrubEnd?.call(),
          onTapCancel: () => onScrubEnd?.call(),
          child: Container(
            color:
                Colors.transparent, // Ensure 100% transparency for background
            child: CustomPaint(
              painter: SharedWaveformPainter(
                peaks: peaks,
                progress: progress,
                markers: markers,
                duration: duration,
              ),
              size: Size(width, height),
            ),
          ),
        );

        if (isPlaying) {
          return AbsorbPointer(child: gestureChild);
        }
        return gestureChild;
      },
    );
  }
}

class SharedWaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;
  final List<Marker> markers;
  final Duration duration;

  SharedWaveformPainter({
    required this.peaks,
    required this.progress,
    required this.markers,
    required this.duration,
  });

  static const double _maxBarWidth = 4.0;
  static const double _minGap = 0.0; // Let bins glue together if very dense
  static const double _playheadWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final halfHeight = size.height / 2;
    final slotWidth = size.width / peaks.length;
    // Allow bars to be contiguous if slotWidth is small, else clamp up to max width
    final barWidth = (slotWidth - _minGap).clamp(1.0, _maxBarWidth);
    final playheadX = progress.clamp(0.0, 1.0) * size.width;

    const colorPlayed = AppColors.primary; // Amber
    const colorToCome = Color(0xFF404040);

    // Draw waveform peaks
    for (var i = 0; i < peaks.length; i++) {
      final x = i * slotWidth + slotWidth / 2;
      final peak = peaks[i].clamp(0.0, 1.0);
      final barHeight = peak * halfHeight * 0.9;
      if (barHeight < 0.5) continue;

      final isPlayed = x <= playheadX;
      final color = isPlayed ? colorPlayed : colorToCome;

      final rect = Rect.fromCenter(
        center: Offset(x, halfHeight),
        width: barWidth,
        height: barHeight,
      );
      final radius = Radius.circular(barWidth / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = color,
      );
    }

    // Draw Markers (vertical dashed lines or solid lines indicating a marker)
    final durationSec = duration.inMicroseconds > 0
        ? duration.inMicroseconds / 1000000.0
        : 1.0;

    for (final marker in markers) {
      final t = marker.timestamp.inMicroseconds / 1000000.0 / durationSec;
      if (t >= 0 && t <= 1) {
        final markerX = t * size.width;

        // Parse color
        Color markerColor = Colors.white;
        try {
          if (marker.colorHex.isNotEmpty) {
            String hex = marker.colorHex.replaceAll('#', '');
            if (hex.length == 6) {
              hex = 'FF$hex';
            }
            markerColor = Color(int.parse(hex, radix: 16));
          }
        } catch (_) {}

        final markerPaint = Paint()
          ..color = markerColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        // Simple vertical line for marker
        canvas.drawLine(
          Offset(markerX, 0),
          Offset(markerX, size.height),
          markerPaint,
        );
      }
    }

    // Draw playhead
    canvas.drawRect(
      Rect.fromLTWH(
        playheadX - _playheadWidth / 2,
        0,
        _playheadWidth,
        size.height,
      ),
      Paint()..color = colorPlayed,
    );
  }

  @override
  bool shouldRepaint(SharedWaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.peaks != peaks ||
      oldDelegate.markers != markers ||
      oldDelegate.duration != duration;
}
