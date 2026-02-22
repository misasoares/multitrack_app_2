import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';

class PreviewTimeline extends StatefulWidget {
  final Duration totalDuration;
  final Stream<Duration> positionStream;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final bool isPlaying;

  const PreviewTimeline({
    super.key,
    required this.totalDuration,
    required this.positionStream,
    required this.onPlayPause,
    required this.onSeek,
    required this.isPlaying,
  });

  @override
  State<PreviewTimeline> createState() => _PreviewTimelineState();
}

class _PreviewTimelineState extends State<PreviewTimeline> {
  StreamSubscription<Duration>? _subscription;
  double _currentPosition = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _subscribeToStream();
  }

  @override
  void didUpdateWidget(PreviewTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.positionStream != oldWidget.positionStream) {
      _subscription?.cancel();
      _subscribeToStream();
    }
  }

  void _subscribeToStream() {
    _subscription = widget.positionStream.listen(
      (position) {
        if (!_isDragging) {
          setState(() {
            _currentPosition = position.inMilliseconds.toDouble();
          });
        }
      },
      onError: (e) {
        debugPrint('PreviewTimeline stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.totalDuration.inMilliseconds.toDouble();
    // Ensure current position doesn't exceed max (unless max is 0)
    final value = max > 0 ? _currentPosition.clamp(0.0, max) : 0.0;

    return Row(
      children: [
        IconButton(
          onPressed: widget.onPlayPause,
          icon: Icon(
            widget.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: AppColors.primary,
            size: 32,
          ),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(Duration(milliseconds: value.toInt())),
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFF333333),
              thumbColor: Colors.white,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: max > 0 ? max : 1.0,
              onChanged: (val) {
                setState(() {
                  _isDragging = true;
                  _currentPosition = val;
                });
              },
              onChangeEnd: (val) {
                setState(() {
                  _isDragging = false;
                });
                widget.onSeek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),
        ),
        Text(
          _formatDuration(widget.totalDuration),
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
