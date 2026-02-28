import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multitracks_df_pro/core/audio_engine/iaudio_engine_service.dart';
import 'package:multitracks_df_pro/core/audio_engine/mixer_level_controller.dart';
import 'package:multitracks_df_pro/core/theme/app_colors.dart';
import 'package:multitracks_df_pro/core/theme/app_text_styles.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/setlist.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/track.dart';
import 'package:multitracks_df_pro/injection_container.dart';
import '../stores/live_performance_store.dart';

/// Live Performance (stage) page: pre-rendered playback, setlist ribbon, waveform, ephemeral mixer.
class LivePerformancePage extends StatefulWidget {
  final Setlist setlist;

  const LivePerformancePage({super.key, required this.setlist});

  @override
  State<LivePerformancePage> createState() => _LivePerformancePageState();
}

class _LivePerformancePageState extends State<LivePerformancePage> {
  late final LivePerformanceStore _store;
  late final IAudioEngineService _audioEngine;
  MixerLevelController? _levelController;

  @override
  void initState() {
    super.initState();
    _store = sl<LivePerformanceStore>();
    _audioEngine = sl<IAudioEngineService>();
    _store.loadSetlist(widget.setlist);
  }

  @override
  void dispose() {
    _levelController?.dispose();
    _store.dispose();
    super.dispose();
  }

  void _ensureLevelController() {
    final trackIds = _store.currentTracks.map((t) => t.id).toList();
    if (trackIds.isEmpty) return;
    _levelController?.dispose();
    _levelController = MixerLevelController(_audioEngine, trackIds);
    _levelController!.start();
  }

  static String _formatTimer(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final cs = (d.inMilliseconds.remainder(1000) / 10).round();
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.setlist.name,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LiveHeader(store: _store, formatTimer: _formatTimer),
            const SizedBox(height: 8),
            _SetlistRibbon(store: _store),
            const SizedBox(height: 12),
            Expanded(
              flex: 2,
              child: _WaveformSection(store: _store),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 3,
              child: Observer(
                builder: (_) {
                  if (_store.currentTracks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tracks',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }
                  _ensureLevelController();
                  return _MixerSection(
                    store: _store,
                    audioEngine: _audioEngine,
                    levelController: _levelController!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveHeader extends StatelessWidget {
  final LivePerformanceStore store;
  final String Function(Duration) formatTimer;

  const _LiveHeader({required this.store, required this.formatTimer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STAGE COMMANDER',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'LIVE VIEW V1.0',
                style: AppTextStyles.labelMuted.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Observer(
              builder: (_) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatTimer(store.currentPosition),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  if (store.isLoadingSong) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Observer(
                builder: (_) => IconButton(
                  onPressed: store.isLoadingSong ? null : () => store.prevSong(),
                  icon: Icon(
                    Icons.skip_previous,
                    color: store.isLoadingSong ? AppColors.textMuted : AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
              Observer(
                builder: (_) => IconButton(
                  onPressed: store.isLoadingSong
                      ? null
                      : (store.currentSetlist != null ? () => store.togglePlay() : null),
                  icon: Icon(
                    store.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: store.isLoadingSong ? AppColors.textMuted : AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
              Observer(
                builder: (_) => IconButton(
                  onPressed: store.isLoadingSong ? null : () => store.nextSong(),
                  icon: Icon(
                    Icons.skip_next,
                    color: store.isLoadingSong ? AppColors.textMuted : AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetlistRibbon extends StatelessWidget {
  final LivePerformanceStore store;

  const _SetlistRibbon({required this.store});

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Observer(
        builder: (_) {
          final setlist = store.currentSetlist;
          if (setlist == null || setlist.items.isEmpty) {
            return const Center(child: Text('No songs', style: TextStyle(color: AppColors.textMuted)));
          }
          final loading = store.isLoadingSong;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: setlist.items.length,
            itemBuilder: (context, index) {
              final item = setlist.items[index];
              final music = item.originalMusic;
              final isActive = index == store.activeSongIndex;
              final duration = music.duration;
              final keyStr = music.key.isNotEmpty ? music.key : '';
              final bpmStr = music.bpm > 0 ? '${music.bpm}bpm' : '';
              final meta = [keyStr, bpmStr].where((s) => s.isNotEmpty).join(' / ');
              return GestureDetector(
                onTap: loading ? null : () => store.goToSong(index),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withValues(alpha: 0.25) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? AppColors.primary : const Color(0xFF2A2A2A),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(index + 1).toString().padLeft(2, '0')} ${music.title}${isActive ? ' (Active)' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDuration(duration)}${meta.isNotEmpty ? ' / $meta' : ''}',
                        style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WaveformSection extends StatelessWidget {
  final LivePerformanceStore store;

  const _WaveformSection({required this.store});

  /// Builds master waveform peaks from current item's tracks (pre-computed in DB).
  /// Uses first non-muted track with waveformPeaks, or combines bins from non-muted tracks.
  static List<double> _masterPeaksFromTracks(List<Track> tracks, int numBins) {
    final withPeaks = tracks.where((t) => !t.isMuted && t.waveformPeaks != null && t.waveformPeaks!.isNotEmpty).toList();
    if (withPeaks.isEmpty) return [];
    if (withPeaks.length == 1) {
      final p = withPeaks.first.waveformPeaks!;
      if (p.length != numBins) {
        return _resamplePeaks(p, numBins);
      }
      return p.map((v) => v.clamp(0.0, 1.0)).toList();
    }
    // Combine: average of peaks per bin (simple mix visualization).
    final combined = List<double>.filled(numBins, 0.0);
    int count = 0;
    for (final t in withPeaks) {
      final p = t.waveformPeaks!;
      final resampled = p.length == numBins ? p : _resamplePeaks(p, numBins);
      for (var i = 0; i < numBins; i++) {
        combined[i] += resampled[i];
      }
      count++;
    }
    if (count == 0) return [];
    final maxVal = combined.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return combined;
    return combined.map((v) => (v / count).clamp(0.0, 1.0)).toList();
  }

  static List<double> _resamplePeaks(List<double> src, int targetBins) {
    if (src.isEmpty) return List.filled(targetBins, 0.0);
    if (src.length == targetBins) return List.from(src);
    if (targetBins <= 1) return [src.reduce((a, b) => a > b ? a : b)];
    final result = <double>[];
    for (var i = 0; i < targetBins; i++) {
      final srcIndex = (i * (src.length - 1)) / (targetBins - 1);
      final idx = srcIndex.floor().clamp(0, src.length - 1);
      final next = (idx + 1).clamp(0, src.length - 1);
      final frac = srcIndex - idx;
      result.add(src[idx] * (1 - frac) + src[next] * frac);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final item = store.currentItem;
        final tracks = store.currentTracks;
        final position = store.currentPosition;
        if (item == null || tracks.isEmpty) {
          return Container(
            color: const Color(0xFF0D0D0D),
            child: const Center(
              child: Text('No waveform', style: TextStyle(color: AppColors.textMuted)),
            ),
          );
        }
        final duration = item.originalMusic.duration;
        final durationSec = duration.inMicroseconds > 0
            ? duration.inMicroseconds / 1000000.0
            : 1.0;
        final progress = durationSec > 0
            ? (position.inMicroseconds / 1000000.0 / durationSec).clamp(0.0, 1.0)
            : 0.0;

        const numBins = 80;
        final peaks = _masterPeaksFromTracks(tracks, numBins);

        return Container(
          color: const Color(0xFF0D0D0D),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: peaks.isEmpty
                    ? CustomPaint(
                        painter: _WaveformPainter(peaks: const [], progress: progress),
                        size: Size.infinite,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return CustomPaint(
                            painter: _WaveformPainter(peaks: peaks, progress: progress),
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (item.originalMusic.markers.isNotEmpty)
                    ...item.originalMusic.markers.take(6).map((m) {
                      final t = m.timestamp.inMicroseconds / 1000000.0 / durationSec;
                      final inRange = t >= 0 && t <= 1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          m.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: inRange
                                ? (progress >= t ? AppColors.primary : AppColors.textMuted)
                                : AppColors.textMuted,
                          ),
                        ),
                      );
                    }),
                  const Spacer(),
                  Text(
                    'LR-Stereo Mix',
                    style: AppTextStyles.labelMuted.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;

  _WaveformPainter({required this.peaks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;
    final barWidth = size.width / peaks.length;
    final halfHeight = size.height / 2;
    const radius = 2.0;
    for (var i = 0; i < peaks.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final peak = peaks[i].clamp(0.0, 1.0);
      final barHeight = peak * halfHeight;
      final isPlayed = (i / peaks.length) <= progress;
      final color = isPlayed
          ? AppColors.primary
          : AppColors.textMuted.withValues(alpha: 0.5);
      final rect = Rect.fromCenter(
        center: Offset(x, halfHeight),
        width: math.max(2, barWidth - 1),
        height: barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = color,
      );
    }
    final playheadX = progress * size.width;
    canvas.drawRect(
      Rect.fromLTWH(playheadX - 1, 0, 2, size.height),
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.peaks != peaks;
}

class _MixerSection extends StatelessWidget {
  final LivePerformanceStore store;
  final IAudioEngineService audioEngine;
  final MixerLevelController levelController;

  const _MixerSection({
    required this.store,
    required this.audioEngine,
    required this.levelController,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final tracks = store.currentTracks;
        return Container(
          color: const Color(0xFF080808),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _TrackFaderStrip(
                track: track,
                store: store,
                audioEngine: audioEngine,
                levelController: levelController,
              );
            },
          ),
        );
      },
    );
  }
}

class _TrackFaderStrip extends StatelessWidget {
  final Track track;
  final LivePerformanceStore store;
  final IAudioEngineService audioEngine;
  final MixerLevelController levelController;

  const _TrackFaderStrip({
    required this.track,
    required this.store,
    required this.audioEngine,
    required this.levelController,
  });

  static double _linearToDb(double lin) {
    if (lin <= 0.00001) return -60.0;
    return 20.0 * (math.log(lin) / math.ln10);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Text(
            track.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.trackLabel.copyWith(fontSize: 9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MuteSoloButton(
                label: 'M',
                isActive: track.isMuted,
                activeColor: AppColors.alert,
                onPressed: () => store.setTrackMute(track.id, !track.isMuted),
              ),
              const SizedBox(width: 4),
              _MuteSoloButton(
                label: 'S',
                isActive: track.isSolo,
                activeColor: AppColors.solo,
                onPressed: () => store.setTrackSolo(track.id, !track.isSolo),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 16,
            height: 80,
            child: Observer(
              builder: (_) {
                final db = levelController.trackLevels[track.id] ?? -60.0;
                return CustomPaint(
                  painter: _VuBarPainter(db: db),
                  size: const Size(16, 80),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 100,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.textMuted.withValues(alpha: 0.3),
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: _linearToDb(track.volume).clamp(-60.0, 6.0),
                  min: -60.0,
                  max: 6.0,
                  onChanged: (db) {
                    final lin = db <= -59.9 ? 0.0 : math.pow(10.0, db / 20.0).toDouble();
                    store.setTrackVolume(track.id, lin);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _linearToDb(track.volume) > -59.9
                ? '${_linearToDb(track.volume).toStringAsFixed(1)}'
                : '-INF',
            style: AppTextStyles.trackLabel.copyWith(
              fontSize: 10,
              color: (track.volume - 1.0).abs() < 0.01 ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuteSoloButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;

  const _MuteSoloButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeColor.withValues(alpha: 0.3) : const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? activeColor : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VuBarPainter extends CustomPainter {
  final double db;

  _VuBarPainter({required this.db});

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 12;
    final segmentHeight = size.height / segments;
    final active = ((db + 60) / 60 * segments).clamp(0.0, segments.toDouble());
    for (var i = 0; i < segments; i++) {
      final y = size.height - (i + 1) * segmentHeight;
      Color color;
      if (i < active) {
        if (i < 8) {
          color = const Color(0xFF059669);
        } else if (i < 10) {
          color = AppColors.primary;
        } else {
          color = AppColors.alert;
        }
      } else {
        color = const Color(0xFF1A1A1A);
      }
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, segmentHeight - 1),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_VuBarPainter old) => old.db != db;
}
