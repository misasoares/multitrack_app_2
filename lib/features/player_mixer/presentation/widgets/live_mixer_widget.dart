import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/setlist_config_store.dart';
import '../../../../core/audio_engine/iaudio_engine_service.dart';
import '../../../../core/audio_engine/mixer_level_controller.dart';
import '../../domain/entities/track.dart';
import 'eq/eq_interactive_dialog.dart';
import '../../../../../core/audio_engine/audio_dsp_service.dart';
import 'package:get_it/get_it.dart';

/// A full-screen or large dialog widget that provides a real-time audio mixer
/// with vertical faders and VU meters, styled after the "Amber Stage Commander" design.
class LiveMixerWidget extends StatefulWidget {
  final SetlistConfigStore store;
  final String itemId;
  final String songTitle;
  final IAudioEngineService audioEngine;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const LiveMixerWidget({
    super.key,
    required this.store,
    required this.itemId,
    required this.songTitle,
    required this.audioEngine,
    required this.onReset,
    required this.onSave,
  });

  @override
  State<LiveMixerWidget> createState() => _LiveMixerWidgetState();
}

class _LiveMixerWidgetState extends State<LiveMixerWidget> {
  late final MixerLevelController _levelController;

  @override
  void initState() {
    super.initState();
    final item = widget.store.currentSetlist?.items.firstWhere(
      (i) => i.id == widget.itemId,
      orElse: () => widget.store.currentSetlist!.items.first,
    );
    final trackIds = item?.originalMusic.tracks.map((t) => t.id).toList() ?? [];

    _levelController = MixerLevelController(widget.audioEngine, trackIds);
    _levelController.start();
  }

  @override
  void dispose() {
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final item = widget.store.currentSetlist?.items.firstWhere(
          (i) => i.id == widget.itemId,
          orElse: () => widget
              .store
              .currentSetlist!
              .items
              .first, // Fallback to first if not found (shouldn't happen)
        );
        final tracks = item?.originalMusic.tracks ?? [];

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border.all(
              color: const Color(0xFFf9ac06).withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Mixer Body
              Expanded(
                child: Container(
                  color: const Color(0xFF080808),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Tracks
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: tracks.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            return TrackChannelStrip(
                              track: track,
                              audioEngine: widget.audioEngine,
                              levelController: _levelController,
                              onEqChanged: (trackId, band) {
                                widget.store.updateTrackEq(
                                  widget.itemId,
                                  trackId,
                                  band,
                                );
                              },
                              onMuteChanged: (trackId, muted) {
                                widget.store.updateTrackMute(
                                  widget.itemId,
                                  trackId,
                                  muted,
                                );
                              },
                              onSoloChanged: (trackId, solo) {
                                widget.store.updateTrackSolo(
                                  widget.itemId,
                                  trackId,
                                  solo,
                                );
                              },
                              onVolumeChanged: (trackId, volume) {
                                widget.store.updateTrackVolume(
                                  widget.itemId,
                                  trackId,
                                  volume,
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Master
                      MasterChannelStrip(
                        audioEngine: widget.audioEngine,
                        levelController: _levelController,
                        volume: item?.volume ?? 0.8,
                        onVolumeChanged: (v) {
                          if (item != null) {
                            widget.store.updateItemVolume(item.id, v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              _buildFooter(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.equalizer, color: Color(0xFFf9ac06), size: 20),
              const SizedBox(width: 16),
              Text(
                'TRACK MIXER: ${widget.songTitle.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusInfo(),
          Row(
            children: [
              TextButton(
                onPressed: widget.onReset,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  shape: const RoundedRectangleBorder(),
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                ),
                child: const Text(
                  'RESET LEVELS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.onSave,
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf9ac06),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      shape: const RoundedRectangleBorder(),
                      elevation: 5,
                      shadowColor: const Color(0xFFf9ac06).withOpacity(0.4),
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith(
                        (states) =>
                            states.contains(WidgetState.hovered) ? 10 : 5,
                      ),
                    ),
                child: const Text(
                  'SAVE MIX',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return const Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'OUTPUT DEV',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            Text(
              'NATIVE OBOE ENGINE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
        SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'POLLING',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            Text(
              '30 FPS',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TrackChannelStrip extends StatelessWidget {
  final Track track;
  final IAudioEngineService audioEngine;
  final MixerLevelController levelController;
  final Function(String trackId, dynamic band)? onEqChanged;
  final Function(String trackId, bool muted)? onMuteChanged;
  final Function(String trackId, bool solo)? onSoloChanged;
  final Function(String trackId, double volume)? onVolumeChanged;

  const TrackChannelStrip({
    super.key,
    required this.track,
    required this.audioEngine,
    required this.levelController,
    this.onEqChanged,
    this.onMuteChanged,
    this.onSoloChanged,
    this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Track Name
          Text(
            track.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),

          // VU Meter
          SizedBox(
            width: 16,
            height: 180,
            child: Observer(
              builder: (_) {
                final db = levelController.trackLevels[track.id] ?? -60.0;
                return CustomPaint(painter: VuMeterPainter(db: db));
              },
            ),
          ),
          const SizedBox(height: 8),

          // DB Value
          Observer(
            builder: (_) {
              final db = levelController.trackLevels[track.id] ?? -60.0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: const Color(0xFFf9ac06).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  db > -60 ? db.toStringAsFixed(1) : '-INF',
                  style: const TextStyle(
                    color: Color(0xFFf9ac06),
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Fader
          Expanded(
            child: _Fader(
              initialValue: track.volume,
              onChanged: (v) => onVolumeChanged?.call(track.id, v),
            ),
          ),

          const SizedBox(height: 12),

          // EQ Button
          _SmallButton(
            label: 'EQ',
            isActive: track.eqBands.any((b) => b.gain.abs() > 0.1),
            activeColor: const Color(0xFFf9ac06),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => EqInteractiveDialog(
                  trackId: track.id,
                  dspService: GetIt.I<AudioDspService>(),
                  initialBands: track.eqBands,
                  onBandChanged: (band) {
                    onEqChanged?.call(track.id, band);
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Mute / Solo
          Row(
            children: [
              Expanded(
                child: _SmallButton(
                  label: 'M',
                  isActive: track.isMuted,
                  activeColor: Colors.red.withOpacity(0.6),
                  onPressed: () {
                    onMuteChanged?.call(track.id, !track.isMuted);
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _SmallButton(
                  label: 'S',
                  isActive: track.isSolo,
                  activeColor: const Color(0xFFf9ac06).withOpacity(0.6),
                  onPressed: () {
                    onSoloChanged?.call(track.id, !track.isSolo);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MasterChannelStrip extends StatelessWidget {
  final IAudioEngineService audioEngine;
  final MixerLevelController levelController;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const MasterChannelStrip({
    super.key,
    required this.audioEngine,
    required this.levelController,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFFf9ac06).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text(
            'MASTER',
            style: TextStyle(
              color: Color(0xFFf9ac06),
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),

          // Stereo VU Meters
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  child: Observer(
                    builder: (_) => CustomPaint(
                      painter: VuMeterPainter(db: levelController.masterLevel),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 16,
                  child: Observer(
                    builder: (_) => CustomPaint(
                      painter: VuMeterPainter(db: levelController.masterLevel),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // DB Value
          Observer(
            builder: (_) {
              final db = levelController.masterLevel;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: const Color(0xFFf9ac06).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${db > -60 ? db.toStringAsFixed(1) : '-INF'} dB',
                  style: const TextStyle(
                    color: Color(0xFFf9ac06),
                    fontFamily: 'JetBrains Mono',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Color(0xFFf9ac06), blurRadius: 8)],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Fader
          Expanded(
            child: _Fader(
              initialValue: volume,
              isMaster: true,
              onChanged: onVolumeChanged,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: _SmallButton(
              label: 'MASTER MUTE',
              isActive: false,
              activeColor: Colors.red,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _Fader extends StatefulWidget {
  final double initialValue; // Linear [0.0, 1.0+]
  final bool isMaster;
  final ValueChanged<double> onChanged;

  const _Fader({
    required this.initialValue,
    this.isMaster = false,
    required this.onChanged,
  });

  @override
  State<_Fader> createState() => _FaderState();
}

class _FaderState extends State<_Fader> {
  late double _dbValue;

  @override
  void initState() {
    super.initState();
    _dbValue = _linearToDb(widget.initialValue).clamp(-60.0, 15.0);
  }

  double _linearToDb(double lin) {
    if (lin <= 0.00001) return -60.0;
    return 20.0 * (math.log(lin) / math.ln10);
  }

  @override
  void didUpdateWidget(_Fader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _dbValue = _linearToDb(widget.initialValue).clamp(-60.0, 15.0);
      });
    }
  }

  double _dbToLinear(double db) {
    if (db <= -59.9) return 0.0; // Forced absolute silence
    return math.pow(10.0, db / 20.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Track
            Container(
              width: widget.isMaster ? 4 : 2,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Color(0xFF1A1A1A), Colors.black],
                ),
              ),
            ),

            // Slider
            RotatedBox(
              quarterTurns: 3,
              child: SizedBox(
                width: constraints.maxHeight,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 0,
                    thumbShape: _CustomThumbShape(isMaster: widget.isMaster),
                    overlayColor: Colors.transparent,
                  ),
                  child: Slider(
                    value: _dbValue,
                    min: -60.0,
                    max: 15.0,
                    onChanged: (db) {
                      setState(() => _dbValue = db);
                      widget.onChanged(_dbToLinear(db));
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomThumbShape extends SliderComponentShape {
  final bool isMaster;
  const _CustomThumbShape({this.isMaster = false});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(40, 20);

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
    final double width = isMaster ? 48.0 : 32.0;
    final double height = isMaster ? 24.0 : 16.0;

    final rect = Rect.fromCenter(center: center, width: height, height: width);
    final paint = Paint()
      ..color = const Color(0xFFf9ac06)
      ..style = PaintingStyle.fill;

    // Draw shadows
    canvas.drawRect(rect, paint);

    // Draw lines on the fader knob
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = isMaster ? 2 : 1;

    final lineSpacing = isMaster ? 6.0 : 4.0;
    canvas.drawLine(
      Offset(center.dx - 4, center.dy - lineSpacing),
      Offset(center.dx + 4, center.dy - lineSpacing),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - 4, center.dy),
      Offset(center.dx + 4, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - 4, center.dy + lineSpacing),
      Offset(center.dx + 4, center.dy + lineSpacing),
      linePaint,
    );
  }
}

class VuMeterPainter extends CustomPainter {
  final double db; // -60 to 0
  static const int numSegments = 16;

  VuMeterPainter({required this.db});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Background
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final segmentHeight = (size.height - (numSegments - 1) * 2) / numSegments;

    // Normalize dB to [0, numSegments]
    // -60dB -> 0
    // 0dB -> 16
    final activeSegments = ((db + 60) / 60 * numSegments)
        .clamp(0, numSegments)
        .round();

    for (int i = 0; i < numSegments; i++) {
      final y = size.height - (i + 1) * (segmentHeight + 2);
      final segmentRect = Rect.fromLTWH(2, y, size.width - 4, segmentHeight);

      Color color;
      if (i < activeSegments) {
        if (i < 10) {
          color = const Color(0xFF059669); // Green
        } else if (i < 14) {
          color = const Color(0xFFf9ac06); // Amber
        } else {
          color = const Color(0xFFdc2626); // Red
        }
      } else {
        color = const Color(0xFF1A1A1A); // Off
      }

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(segmentRect, const Radius.circular(1)),
        paint,
      );

      // Add glow to active segments
      if (i < activeSegments) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(segmentRect, const Radius.circular(1)),
          Paint()
            ..color = color.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(VuMeterPainter oldDelegate) => oldDelegate.db != db;
}

class _SmallButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;

  const _SmallButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.2)
              : const Color(0xFF0A0A0A),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.4)
                : const Color(0xFF2A2A2A),
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : Colors.grey[600],
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
