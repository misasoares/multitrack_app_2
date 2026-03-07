import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/audio_engine/iaudio_engine_service.dart';
import '../../../../core/presentation/widgets/shared_waveform_timeline.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/marker.dart';
import '../../domain/entities/track.dart';

class MarkersEditorPage extends StatefulWidget {
  final List<Track> tracks;
  final List<double> peaks;
  final List<int> clickMap;
  final List<Marker> initialMarkers;

  const MarkersEditorPage({
    super.key,
    required this.tracks,
    required this.peaks,
    required this.clickMap,
    required this.initialMarkers,
  });

  @override
  State<MarkersEditorPage> createState() => _MarkersEditorPageState();
}

class _MarkersEditorPageState extends State<MarkersEditorPage> {
  final _audioEngine = sl<IAudioEngineService>();

  List<Marker> _markers = [];
  Duration _duration = Duration.zero;
  final ValueNotifier<int> _currentPositionNotifier = ValueNotifier(0);
  bool _isPlaying = false;
  double _zoomLevel = 1.0;

  StreamSubscription? _positionSub;

  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;
  final GlobalKey _timelineKey = GlobalKey();

  // Dragging state
  String? _draggingMarkerId;

  @override
  void initState() {
    super.initState();
    _markers = List.from(widget.initialMarkers);

    _duration = widget.tracks.fold<Duration>(
      Duration.zero,
      (maxDur, t) => t.duration > maxDur ? t.duration : maxDur,
    );
    if (_duration.inMilliseconds == 0) {
      _duration = const Duration(minutes: 5); // fallback
    }

    _initEngine();
  }

  Future<void> _initEngine() async {
    await _audioEngine.loadPreview(widget.tracks);

    // Listen to changes
    _positionSub = _audioEngine.onPreviewPosition.listen((p) {
      if (!mounted) return;
      if (!_isScrubbing) {
        _currentPositionNotifier.value = p.inMicroseconds;
      }

      // Auto-scroll logic
      if (!_isUserScrolling &&
          _scrollController.hasClients &&
          _duration.inMicroseconds > 0) {
        final screenWidth = MediaQuery.of(context).size.width;
        final baseWidth = screenWidth - 32.0; // Subtracting horizontal padding
        final zoomedWidth = baseWidth * _zoomLevel;

        final progress = p.inMicroseconds / _duration.inMicroseconds;
        final needlePixelPos = progress * zoomedWidth;

        final currentOffset = _scrollController.offset;
        final viewportWidth = _scrollController.position.viewportDimension;

        // If needle is past 85% of the visible screen, or if it went backwards
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
    _audioEngine.clearAllTracks();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isScrubbing = false;

  void _addMarker() {
    setState(() {
      _markers.add(
        Marker(
          id: const Uuid().v4(),
          label: 'MARKER ${_markers.length + 1}',
          timestamp: Duration(microseconds: _currentPositionNotifier.value),
          colorHex: '#FFFFFF',
        ),
      );
    });
  }

  int _snapToClickMap(int timeMs, double zoomedWidth) {
    if (widget.clickMap.isEmpty) return timeMs;
    // Find closest time in clickMap
    int closest = widget.clickMap.first;
    int minDiff = (timeMs - closest).abs();

    for (final tick in widget.clickMap) {
      final diff = (timeMs - tick).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = tick;
      }
    }

    return closest;
  }

  Future<void> _showEditMarkerDialog(Marker initialMarker) async {
    final TextEditingController nameController = TextEditingController(
      text: initialMarker.label,
    );

    // We get the latest marker from the list to avoid editing an outdated instance
    Marker getLatestMarker() => _markers.firstWhere(
      (m) => m.id == initialMarker.id,
      orElse: () => initialMarker,
    );

    // List of 24 distinct colors
    final List<Color> paletteList = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF3F51B5),
      const Color(0xFF00BCD4),
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final Marker currentMarker = getLatestMarker();
            final Color currentColor = currentMarker.colorHex == '#FFFFFF'
                ? Colors.white
                : Color(
                    int.parse(currentMarker.colorHex.replaceAll('#', '0xff')),
                  );

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Editar Marcador',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nome do Marcador',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      onChanged: (text) {
                        setState(() {
                          final i = _markers.indexWhere(
                            (m) => m.id == currentMarker.id,
                          );
                          if (i != -1) {
                            _markers[i] = currentMarker.copyWith(label: text);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ajuste de Posição',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_left,
                            size: 32,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            if (widget.clickMap.isEmpty) return;
                            int closestIndex = 0;
                            int minDiff =
                                (currentMarker.timestamp.inMilliseconds -
                                        widget.clickMap.first)
                                    .abs();
                            for (int i = 0; i < widget.clickMap.length; i++) {
                              final diff =
                                  (currentMarker.timestamp.inMilliseconds -
                                          widget.clickMap[i])
                                      .abs();
                              if (diff < minDiff) {
                                minDiff = diff;
                                closestIndex = i;
                              }
                            }
                            if (closestIndex > 0) {
                              final newTime = widget.clickMap[closestIndex - 1];
                              setState(() {
                                final idx = _markers.indexWhere(
                                  (m) => m.id == currentMarker.id,
                                );
                                if (idx != -1) {
                                  _markers[idx] = currentMarker.copyWith(
                                    timestamp: Duration(milliseconds: newTime),
                                  );
                                }
                              });
                              setDialogState(() {}); // update dialog locally
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_right,
                            size: 32,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            if (widget.clickMap.isEmpty) return;
                            int closestIndex = 0;
                            int minDiff =
                                (currentMarker.timestamp.inMilliseconds -
                                        widget.clickMap.first)
                                    .abs();
                            for (int i = 0; i < widget.clickMap.length; i++) {
                              final diff =
                                  (currentMarker.timestamp.inMilliseconds -
                                          widget.clickMap[i])
                                      .abs();
                              if (diff < minDiff) {
                                minDiff = diff;
                                closestIndex = i;
                              }
                            }
                            if (closestIndex < widget.clickMap.length - 1) {
                              final newTime = widget.clickMap[closestIndex + 1];
                              setState(() {
                                final idx = _markers.indexWhere(
                                  (m) => m.id == currentMarker.id,
                                );
                                if (idx != -1) {
                                  _markers[idx] = currentMarker.copyWith(
                                    timestamp: Duration(milliseconds: newTime),
                                  );
                                }
                              });
                              setDialogState(() {}); // update dialog locally
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Cor', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: paletteList.map((color) {
                        final isSelected = color.value == currentColor.value;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              final i = _markers.indexWhere(
                                (m) => m.id == currentMarker.id,
                              );
                              if (i != -1) {
                                // To hex string
                                final hex =
                                    '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                                _markers[i] = currentMarker.copyWith(
                                  colorHex: hex,
                                );
                              }
                            });
                            setDialogState(() {});
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: color.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Concluído',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
        title: const Text(
          'Editar Marcadores',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _markers),
            child: const Text(
              'Concluído',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 48,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        _audioEngine.pausePreview();
                        setState(() => _isPlaying = false);
                      } else {
                        _audioEngine.playPreview();
                        setState(() => _isPlaying = true);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: _addMarker,
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('+ Marcador'),
                  ),
                ],
              ),
            ),

            // Timeline Section (Superior)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final baseWidth = constraints.maxWidth;
                    final zoomedWidth = baseWidth * _zoomLevel;

                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        if (notification is ScrollStartNotification &&
                            notification.dragDetails != null) {
                          _isUserScrolling = true;
                        } else if (notification is ScrollEndNotification) {
                          _isUserScrolling = false;
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: SizedBox(
                          key: _timelineKey,
                          width: zoomedWidth,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // STATIC BACKGROUND (RepaintBoundary)
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Background Grid
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: GridPainter(
                                            clickMap: widget.clickMap,
                                            totalDuration: _duration,
                                          ),
                                        ),
                                      ),

                                      // Base Timeline
                                      Positioned.fill(
                                        child: SharedWaveformTimeline(
                                          peaks: widget.peaks,
                                          progress:
                                              0.0, // Fixed progress to avoid rebuilding
                                          isPlaying: _isPlaying,
                                          duration: _duration,
                                          markers: const [],
                                          onScrubStart: (pos) {
                                            _isScrubbing = true;
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
                                            _isScrubbing = false;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Playhead Isolado com ValueListenableBuilder
                              Positioned.fill(
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _currentPositionNotifier,
                                  builder: (context, currentMicros, child) {
                                    final double progress =
                                        _duration.inMicroseconds > 0
                                        ? (currentMicros /
                                                  _duration.inMicroseconds)
                                              .clamp(0.0, 1.0)
                                        : 0.0;
                                    final playheadX = progress * zoomedWidth;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: playheadX - 1.0,
                                          top: 0,
                                          bottom: 0,
                                          width: 2.0,
                                          child: Container(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              // Markers Overlay
                              ..._markers.map((m) {
                                // Calc X position
                                final durationMs = _duration.inMilliseconds > 0
                                    ? _duration.inMilliseconds.toDouble()
                                    : 1.0;
                                final t =
                                    m.timestamp.inMilliseconds / durationMs;
                                if (t < 0 || t > 1)
                                  return const SizedBox.shrink(); // Out of bounds

                                final markerX = t * zoomedWidth;

                                return Positioned(
                                  left: markerX - 24, // center the 48px handle
                                  top: -24,
                                  bottom: 0,
                                  width: 48, // fat hitbox
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onHorizontalDragStart: (_) {
                                      setState(() => _draggingMarkerId = m.id);
                                    },
                                    onHorizontalDragUpdate: (details) {
                                      if (_draggingMarkerId != m.id) return;

                                      // Renderbox translation
                                      final RenderBox? box =
                                          _timelineKey.currentContext
                                                  ?.findRenderObject()
                                              as RenderBox?;
                                      if (box == null) return;

                                      final localPos = box.globalToLocal(
                                        details.globalPosition,
                                      );

                                      // Calc new time
                                      final percentage =
                                          (localPos.dx / zoomedWidth).clamp(
                                            0.0,
                                            1.0,
                                          );
                                      final newTimeMs =
                                          (_duration.inMilliseconds *
                                                  percentage)
                                              .round();

                                      // Magnetic snap
                                      final snappedTimeMs = _snapToClickMap(
                                        newTimeMs,
                                        zoomedWidth,
                                      );

                                      // Update marker
                                      setState(() {
                                        final i = _markers.indexWhere(
                                          (mk) => mk.id == m.id,
                                        );
                                        if (i != -1) {
                                          _markers[i] = m.copyWith(
                                            timestamp: Duration(
                                              milliseconds: snappedTimeMs,
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    onHorizontalDragEnd: (_) {
                                      setState(() => _draggingMarkerId = null);
                                    },
                                    onHorizontalDragCancel: () {
                                      setState(() => _draggingMarkerId = null);
                                    },
                                    child: Container(
                                      width: 48,
                                      color: Colors.transparent,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // The vertical line (perfectly centered: 48 / 2 - 1 = 23)
                                          Positioned(
                                            left: 23.0,
                                            top: 24.0,
                                            bottom: 0.0,
                                            width: 2.0,
                                            child: Container(
                                              color: _draggingMarkerId == m.id
                                                  ? Colors.white
                                                  : Color(
                                                      int.parse(
                                                        m.colorHex.replaceAll(
                                                          '#',
                                                          '0xFF',
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          // The handle/flag
                                          Align(
                                            alignment: Alignment.topCenter,
                                            child: Builder(
                                              builder: (context) {
                                                final markerColor =
                                                    _draggingMarkerId == m.id
                                                    ? Colors.white
                                                    : Color(
                                                        int.parse(
                                                          m.colorHex.replaceAll(
                                                            '#',
                                                            '0xFF',
                                                          ),
                                                        ),
                                                      );
                                                final textColor =
                                                    markerColor
                                                            .computeLuminance() >
                                                        0.5
                                                    ? Colors.black
                                                    : Colors.white;

                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: markerColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    m.label,
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Zoom Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: AppColors.textMuted),
                  Expanded(
                    child: Slider(
                      value: _zoomLevel,
                      min: 1.0,
                      max: 10.0,
                      activeColor: Colors.amber,
                      onChanged: (val) => setState(() => _zoomLevel = val),
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: AppColors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Marker List Section (Inferior)
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: _markers.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum marcador adicionado',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _markers.length,
                              itemBuilder: (context, index) {
                                // Sort markers by time
                                final sortedMarkers =
                                    List<Marker>.from(_markers)..sort(
                                      (a, b) =>
                                          a.timestamp.compareTo(b.timestamp),
                                    );
                                final marker = sortedMarkers[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: const Color(0xFF1E1E1E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 12,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            marker.colorHex.replaceAll(
                                              '#',
                                              '0xFF',
                                            ),
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    title: Text(
                                      marker.label,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${marker.timestamp.inMinutes.toString().padLeft(2, '0')}:${(marker.timestamp.inSeconds % 60).toString().padLeft(2, '0')}.${(marker.timestamp.inMilliseconds % 1000).toString().padLeft(3, '0')}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () =>
                                              _showEditMarkerDialog(marker),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _markers.removeWhere(
                                                (m) => m.id == marker.id,
                                              );
                                            });
                                          },
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
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final List<int> clickMap;
  final Duration totalDuration;

  GridPainter({required this.clickMap, required this.totalDuration});

  @override
  void paint(Canvas canvas, Size size) {
    if (totalDuration.inMilliseconds <= 0 || clickMap.isEmpty) return;

    final Paint paint = Paint()
      ..color = AppColors.textMuted
          .withValues(alpha: 0.5) // Increased from 0.2 for testing
      ..strokeWidth = 1.0;

    for (final tickMs in clickMap) {
      final double progress = tickMs / totalDuration.inMilliseconds;
      if (progress >= 0.0 && progress <= 1.0) {
        final double x = progress * size.width;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.totalDuration != totalDuration ||
        oldDelegate.clickMap != clickMap;
  }
}
