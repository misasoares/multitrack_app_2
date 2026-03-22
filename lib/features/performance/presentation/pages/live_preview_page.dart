import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/audio_engine/iaudio_engine_service.dart';
import '../../../../core/presentation/widgets/shared_waveform_timeline.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../player_mixer/presentation/stores/create_music_store.dart';
import '../../../player_mixer/domain/entities/marker.dart';
import '../../../player_mixer/domain/entities/music.dart';

class LivePreviewPage extends StatefulWidget {
  final Music music;
  final List<double>? precalculatedPeaks;
  final CreateMusicStore store;

  const LivePreviewPage({
    super.key,
    required this.music,
    required this.store,
    this.precalculatedPeaks,
  });

  @override
  State<LivePreviewPage> createState() => _LivePreviewPageState();
}

class _LivePreviewPageState extends State<LivePreviewPage> {
  final _audioEngine = sl<IAudioEngineService>();

  Duration _duration = Duration.zero;
  final ValueNotifier<int> _currentPositionNotifier = ValueNotifier(0);

  final Map<String, List<double>> _waveformData = {};
  late List<double> _peaks;

  Marker? _currentPlayingMarker;
  Marker? _queuedMarker;

  StreamSubscription? _positionSub;

  final ScrollController _scrollController = ScrollController();
  double _zoomLevel = 1.0;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _duration = widget.music.tracks.fold<Duration>(
      Duration.zero,
      (maxDur, t) => t.duration > maxDur ? t.duration : maxDur,
    );
    if (_duration.inMilliseconds == 0) {
      _duration = const Duration(minutes: 5);
    }

    for (final t in widget.music.tracks) {
      if (t.waveformPeaks != null) {
        _waveformData[t.id] = t.waveformPeaks!;
      }
    }

    _peaks = widget.precalculatedPeaks ?? widget.music.masterWaveformPeaks;

    _initEngine();
  }

  Future<void> _initEngine() async {
    _positionSub = _audioEngine.onPreviewPosition.listen((p) {
      if (!mounted) return;
      _currentPositionNotifier.value = p.inMicroseconds;

      // Update current marker
      Marker? current;
      for (final m in widget.music.markers) {
        if (m.timestamp <= p) {
          if (current == null || m.timestamp > current.timestamp) {
            current = m;
          }
        }
      }

      if (_currentPlayingMarker?.id != current?.id) {
        setState(() {
          _currentPlayingMarker = current;
        });
      }

      // Check if we reached the target of a scheduled jump
      if (_queuedMarker != null) {
        // If playhead suddenly jumped to near the queued marker destination
        final diffToTarget = (p - _queuedMarker!.timestamp).inMilliseconds
            .abs();
        if (diffToTarget < 300) {
          // Within 300ms of jump target
          setState(() {
            _queuedMarker = null;
          });
        }
      }

      // Auto-scroll logic
      if (!_isUserScrolling &&
          _scrollController.hasClients &&
          _duration.inMicroseconds > 0) {
        final screenWidth = MediaQuery.of(context).size.width;
        final baseWidth = (screenWidth - 300) - 32.0;
        final zoomedWidth = baseWidth * _zoomLevel;

        final progress = p.inMicroseconds / _duration.inMicroseconds;
        final needlePixelPos = progress * zoomedWidth;

        final currentOffset = _scrollController.offset;
        final viewportWidth = _scrollController.position.viewportDimension;

        if (needlePixelPos > currentOffset + (viewportWidth * 0.85) ||
            needlePixelPos < currentOffset) {
          double targetOffset = needlePixelPos - (viewportWidth / 2);
          targetOffset = targetOffset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );

          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _currentPositionNotifier.dispose();
    _audioEngine.pausePreview();
    // Intentionally omitted clearAllTracks() to preserve CreateMusicPage audio cache
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (widget.store.isPlaying) {
      widget.store.pausePreview();
    } else {
      widget.store.playPreview();
    }
  }

  void _onMarkerQueued(Marker marker) {
    if (!widget.store.isPlaying) {
      // If not playing, just jump immediately and play
      _audioEngine.scheduleJump(null, marker.timestamp);
      widget.store.playPreview();
      setState(() {
        _queuedMarker = null;
      });
      return;
    }

    // Default to the end of the song if there is no next marker
    Duration targetTriggerTime = _duration;

    // Find the next marker chronologically AFTER the current position
    final currentPos = Duration(microseconds: _currentPositionNotifier.value);

    // Assuming widget.music.markers is sorted by timestamp
    for (final m in widget.music.markers) {
      if (m.timestamp > currentPos) {
        targetTriggerTime = m.timestamp;
        break;
      }
    }

    setState(() {
      _queuedMarker = marker;
    });

    // Triggers the C++ FFI schedule jump logic
    _audioEngine.scheduleJump(targetTriggerTime, marker.timestamp);
  }

  String _formatTimer(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final cs = (d.inMilliseconds.remainder(1000) / 10).round();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = (screenWidth - 300) - 32.0;
    final zoomedWidth = baseWidth * _zoomLevel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Test Drive: ${widget.music.title}',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT COLUMN (Main Viewer)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header (Play / Timer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A0A0A),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Observer(
                          builder: (_) => IconButton(
                            onPressed: _togglePlay,
                            icon: Icon(
                              widget.store.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: AppColors.primary,
                              size: 64,
                            ),
                            iconSize: 64,
                          ),
                        ),
                        const SizedBox(width: 24),
                        ValueListenableBuilder<int>(
                          valueListenable: _currentPositionNotifier,
                          builder: (context, microsecs, child) {
                            return Text(
                              _formatTimer(Duration(microseconds: microsecs)),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 1.0,
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        // Zoom controls
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.zoom_out,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(() {
                                _zoomLevel = (_zoomLevel - 0.2).clamp(0.5, 5.0);
                              }),
                            ),
                            Text(
                              '${(_zoomLevel * 100).toInt()}%',
                              style: AppTextStyles.trackLabel,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.zoom_in,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(() {
                                _zoomLevel = (_zoomLevel + 0.2).clamp(0.5, 5.0);
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Waveform Container
                  Expanded(
                    child: Container(
                      color: const Color(0xFF141414),
                      child: GestureDetector(
                        onPanDown: (_) => _isUserScrolling = true,
                        onPanCancel: () => _isUserScrolling = false,
                        onPanEnd: (_) {
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) _isUserScrolling = false;
                          });
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: SizedBox(
                              width: zoomedWidth,
                              child: Stack(
                                children: [
                                  ValueListenableBuilder<int>(
                                    valueListenable: _currentPositionNotifier,
                                    builder: (context, currentMicrosec, child) {
                                      final progress =
                                          _duration.inMicroseconds > 0
                                          ? currentMicrosec /
                                                _duration.inMicroseconds
                                          : 0.0;

                                      return SharedWaveformTimeline(
                                        peaks: _peaks,
                                        progress: progress,
                                        isPlaying: widget.store.isPlaying,
                                        duration: _duration,
                                        markers: widget.music.markers,
                                        onScrubStart: (pos) {
                                          _isUserScrolling = true;
                                          _currentPositionNotifier.value =
                                              pos.inMicroseconds;
                                          _audioEngine.seekTo(pos);
                                        },
                                        onScrubUpdate: (pos) {
                                          _currentPositionNotifier.value =
                                              pos.inMicroseconds;
                                          _audioEngine.seekTo(pos);
                                        },
                                        onScrubEnd: () {
                                          _isUserScrolling = false;
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT COLUMN (Markers Panel)
            Container(
              width: 300,
              decoration: const BoxDecoration(
                color: AppColors.rackDark,
                border: Border(left: BorderSide(color: Color(0xFF2A2A2A))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MARCADORES',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.music.markers.length,
                      itemBuilder: (context, index) {
                        final m = widget.music.markers[index];
                        final isCurrent = _currentPlayingMarker?.id == m.id;
                        final isQueued = _queuedMarker?.id == m.id;

                        final Color markerColor = m.colorHex == '#FFFFFF'
                            ? Colors.white
                            : Color(
                                int.parse(m.colorHex.replaceAll('#', '0xff')),
                              );

                        return InkWell(
                          onTap: () => _onMarkerQueued(m),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              border: Border(
                                bottom: const BorderSide(
                                  color: Color(0xFF2A2A2A),
                                ),
                                left: isCurrent
                                    ? const BorderSide(
                                        color: AppColors.primary,
                                        width: 4,
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: markerColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.label,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimer(m.timestamp),
                                        style: AppTextStyles.labelMuted,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isQueued)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                if (!isQueued && isCurrent)
                                  const Icon(
                                    Icons.volume_up,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
