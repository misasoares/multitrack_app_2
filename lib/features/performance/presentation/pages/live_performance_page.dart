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
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _WaveformSection(store: _store),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: IconButton.filled(
                      onPressed: () => _store.toggleMixerVisible(),
                      icon: Icon(
                        _store.isMixerVisible ? Icons.tune : Icons.tune_outlined,
                        color: AppColors.primary,
                        size: 40,
                      ),
                      iconSize: 40,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(56, 56),
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Mixer',
                    ),
                  ),
                ],
              ),
            ),
            Observer(
              builder: (_) {
                if (!_store.isMixerVisible) return const SizedBox.shrink();
                if (_store.currentTracks.isNotEmpty) _ensureLevelController();
                return _SuperMixerPanel(
                  store: _store,
                  audioEngine: _audioEngine,
                  levelController: _levelController,
                );
              },
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
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
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
                  const SizedBox(height: 6),
                  Observer(
                    builder: (_) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatTimer(store.currentPosition),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (store.isLoadingSong) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Observer(
                builder: (_) => IconButton(
                  onPressed: store.isLoadingSong
                      ? null
                      : (store.currentSetlist != null ? () => store.togglePlay() : null),
                  icon: Icon(
                    store.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: store.isLoadingSong ? AppColors.textMuted : AppColors.primary,
                    size: 128,
                  ),
                  iconSize: 128,
                ),
              ),
            ],
          ),
          const Expanded(child: SizedBox.shrink()),
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

  static const double cardWidth = 280;
  static const double cardHeight = 128;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight + 8,
      child: Observer(
        builder: (_) {
          final setlist = store.currentSetlist;
          if (setlist == null || setlist.items.isEmpty) {
            return const Center(child: Text('No songs', style: TextStyle(color: AppColors.textMuted)));
          }
          final loading = store.isLoadingSong;
          final playing = store.isPlaying;
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
              final canTap = !loading && !playing;
              return GestureDetector(
                onTap: canTap ? () => store.goToSong(index) : null,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${(index + 1).toString().padLeft(2, '0')} ${music.title}${isActive ? ' (Active)' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDuration(duration)}${meta.isNotEmpty ? ' / $meta' : ''}',
                          style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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

        final peaks = item.masterWaveformPeaks;

        return Container(
          color: const Color(0xFF0D0D0D),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: peaks.isEmpty
                    ? Center(
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
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final height = constraints.maxHeight;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragStart: (details) {
                              if (store.isPlaying) return;
                              store.startScrubbing();
                              final percentage =
                                  (details.localPosition.dx / width).clamp(0.0, 1.0);
                              final totalMicroseconds = duration.inMicroseconds;
                              final newPosition = Duration(
                                microseconds: (totalMicroseconds * percentage).round(),
                              );
                              store.updateScrubPosition(newPosition);
                            },
                            onHorizontalDragUpdate: (details) {
                              if (store.isPlaying) return;
                              final percentage =
                                  (details.localPosition.dx / width).clamp(0.0, 1.0);
                              final totalMicroseconds = duration.inMicroseconds;
                              final newPosition = Duration(
                                microseconds: (totalMicroseconds * percentage).round(),
                              );
                              store.updateScrubPosition(newPosition);
                            },
                            onHorizontalDragEnd: (_) => store.endScrubbing(),
                            onHorizontalDragCancel: () => store.endScrubbing(),
                            child: CustomPaint(
                              painter: _WaveformPainter(
                                peaks: peaks,
                                progress: progress,
                              ),
                              size: Size(width, height),
                            ),
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

  static const double _maxBarWidth = 2.0;
  static const double _minGap = 0.5;
  static const double _playheadWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;
    final halfHeight = size.height / 2;
    final slotWidth = size.width / peaks.length;
    final barWidth = (slotWidth - _minGap).clamp(1.0, _maxBarWidth);
    final playheadX = progress.clamp(0.0, 1.0) * size.width;
    const colorPlayed = AppColors.primary; // Amber
    const colorToCome = Color(0xFF404040);

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

    canvas.drawRect(
      Rect.fromLTWH(playheadX - _playheadWidth / 2, 0, _playheadWidth, size.height),
      Paint()..color = colorPlayed,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.peaks != peaks;
}

/// Bottom panel (height 280): Metronome | Tracks | Master. Dark/Amber.
class _SuperMixerPanel extends StatelessWidget {
  final LivePerformanceStore store;
  final IAudioEngineService audioEngine;
  final MixerLevelController? levelController;

  const _SuperMixerPanel({
    required this.store,
    required this.audioEngine,
    required this.levelController,
  });

  static const double _stripWidth = 86.0;
  static const double _panelHeight = 280;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _panelHeight,
      color: const Color(0xFF080808),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetronomeSection(store: store),
          const SizedBox(width: 16),
          Expanded(
            child: Observer(
              builder: (_) {
                final tracks = store.currentTracks;
                if (tracks.isEmpty) {
                  return const Center(
                    child: Text('No tracks', style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                final lc = levelController;
                if (lc == null) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tracks.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        SizedBox(
                          width: _stripWidth,
                          height: _panelHeight - 20,
                          child: _TrackFaderStrip(
                            track: tracks[i],
                            store: store,
                            audioEngine: audioEngine,
                            levelController: lc,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          _MasterStrip(store: store),
        ],
      ),
    );
  }
}

/// Left section: BPM display, TAP button, click Play/Stop, volume slider, pan slider.
class _MetronomeSection extends StatelessWidget {
  final LivePerformanceStore store;

  const _MetronomeSection({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CLICK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Observer(
            builder: (_) => Text(
              '${store.metronomeBpm.round()} BPM',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Observer(
            builder: (_) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => store.tapTempo(),
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Center(
                    child: Text('TAP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Observer(
            builder: (_) => IconButton(
              onPressed: () => store.setMetronomePlaying(!store.isMetronomePlaying),
              icon: Icon(
                store.isMetronomePlaying ? Icons.stop_circle : Icons.play_circle_outline,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Vol', style: AppTextStyles.labelMuted.copyWith(fontSize: 9)),
          Observer(
            builder: (_) => SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                value: store.metronomeVolume,
                onChanged: (v) => store.setMetronomeVolume(v),
              ),
            ),
          ),
          Text('Pan L/R', style: AppTextStyles.labelMuted.copyWith(fontSize: 9)),
          Observer(
            builder: (_) => SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                value: (store.metronomePan + 1) / 2,
                onChanged: (v) => store.setMetronomePan(v * 2 - 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Right section: Master fader and "VS OUT" label.
class _MasterStrip extends StatelessWidget {
  final LivePerformanceStore store;

  const _MasterStrip({required this.store});

  static const double _masterStripWidth = 86.0;

  static double _linearToDb(double lin) {
    if (lin <= 0.00001) return -60.0;
    return 20.0 * (math.log(lin) / math.ln10);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _masterStripWidth,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MASTER',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'VS OUT',
            style: AppTextStyles.labelMuted.copyWith(fontSize: 8),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Observer(
              builder: (_) => LayoutBuilder(
                builder: (context, constraints) {
                  return RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 8.0,
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.6),
                        inactiveTrackColor: const Color(0xFF0A0A0A),
                        thumbShape: const _RectangularSliderThumbShape(),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                        thumbColor: Colors.transparent,
                      ),
                      child: Slider(
                        value: _linearToDb(store.masterVolume).clamp(-60.0, 6.0),
                        min: -60.0,
                        max: 6.0,
                        onChanged: (db) {
                          final lin = db <= -59.9
                              ? 0.0
                              : math.pow(10.0, db / 20.0).toDouble();
                          store.setMasterVolume(lin);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Observer(
            builder: (_) => Text(
              _linearToDb(store.masterVolume) > -59.9
                  ? _linearToDb(store.masterVolume).toStringAsFixed(1)
                  : '-INF',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0;
        return Container(
          height: h,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top: Track name ──
          Text(
            track.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB0B0B0),
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          // ── M / S buttons ──
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
                activeColor: AppColors.primary,
                onPressed: () => store.setTrackSolo(track.id, !track.isSolo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Body: VU LEDs + Fader ──
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // VU meter (reactive from store.trackPeaks when isPlaying)
                SizedBox(
                  width: 10,
                  child: Observer(
                    builder: (_) {
                      final peak = store.trackPeaks[track.id] ?? 0.0;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return CustomPaint(
                            painter: _VuLedStripPainter(peak: peak),
                            size: Size(10, constraints.maxHeight),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 4),
                // Fader
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final h = constraints.maxHeight;
                      return SizedBox(
                        height: h,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 8.0,
                              activeTrackColor: const Color(0xFF1A1A1A),
                              inactiveTrackColor: const Color(0xFF0A0A0A),
                              thumbShape: const _RectangularSliderThumbShape(),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                              thumbColor: Colors.transparent,
                            ),
                            child: Slider(
                              value: _linearToDb(track.volume).clamp(-60.0, 6.0),
                              min: -60.0,
                              max: 6.0,
                              onChanged: (db) {
                                final lin = db <= -59.9
                                    ? 0.0
                                    : math.pow(10.0, db / 20.0).toDouble();
                                store.setTrackVolume(track.id, lin);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ── Base: gain (dB) in Amber ──
          Text(
            _linearToDb(track.volume) > -59.9
                ? _linearToDb(track.volume).toStringAsFixed(1)
                : '-INF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: (track.volume - 1.0).abs() < 0.01
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}


/// VU meter: segment LEDs from bottom to top (green → amber → red). Lit by [peak] (0.0–1.0).
class _VuLedStripPainter extends CustomPainter {
  final double peak;

  _VuLedStripPainter({required this.peak});

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 12;
    final segmentHeight = size.height / segments;
    // Amplifica o pico para os segmentos subirem mais (o dobro da altura)
    final scaledPeak = (peak * 4.4).clamp(0.0, 1.0);
    final activeCount = (scaledPeak * segments).round().clamp(0, segments);

    for (var i = 0; i < segments; i++) {
      final y = size.height - (i + 1) * segmentHeight;
      final isLit = i < activeCount;
      Color color;
      if (i < 8) {
        color = const Color(0xFF059669);
      } else if (i < 10) {
        color = AppColors.primary;
      } else {
        color = AppColors.alert;
      }
      final opacity = isLit ? 1.0 : 0.2;
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, segmentHeight - 1),
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_VuLedStripPainter oldDelegate) => oldDelegate.peak != peak;
}

/// Thumb em forma de retângulo cinza/chumbo com linha amarela no meio (fader físico).
class _RectangularSliderThumbShape extends SliderComponentShape {
  static const double width = 30.0;
  static const double height = 15.0;

  const _RectangularSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Rect rect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF4A4A4A),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF2A2A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final midY = center.dy;
    canvas.drawLine(
      Offset(center.dx - 10, midY),
      Offset(center.dx + 10, midY),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
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
      color: isActive ? activeColor : const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFF555555),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? (label == 'M' ? Colors.white : Colors.black) : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

