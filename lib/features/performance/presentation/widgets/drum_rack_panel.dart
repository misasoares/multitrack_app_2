import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/audio_engine/iaudio_engine_service.dart';
import '../../../../injection_container.dart';

class DrumRackPanel extends StatefulWidget {
  const DrumRackPanel({super.key});

  @override
  State<DrumRackPanel> createState() => _DrumRackPanelState();
}

class _DrumRackPanelState extends State<DrumRackPanel> {
  final IAudioEngineService _audioEngine = sl<IAudioEngineService>();
  final List<bool> _isPressed = List.generate(8, (_) => false);

  // ID -> Value
  final Map<int, double> _padVolumes = {};
  final Map<int, double> _padPans = {};

  @override
  void initState() {
    super.initState();
    // Default: Volume 1.0, Pan 1.0 (Strictly Right / R as per user rule)
    for (int i = 0; i < 8; i++) {
      _padVolumes[i] = 1.0;
      _padPans[i] = 1.0;
      _audioEngine.setDrumPadParams('pad_${i + 1}', 1.0, 1.0);
    }
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed[index] = true);
    _audioEngine.triggerDrumPad('pad_${index + 1}');

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isPressed[index] = false);
      }
    });
  }

  void _showPadSettings(int index) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getPadColor(index).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.tune, color: _getPadColor(index)),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'PAD ${index + 1} SETTINGS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSettingRow(
                    label: 'VOLUME',
                    value: _padVolumes[index]!,
                    onChanged: (v) {
                      setSheetState(() => _padVolumes[index] = v);
                      setState(() {});
                      _audioEngine.setDrumPadParams(
                        'pad_${index + 1}',
                        _padVolumes[index]!,
                        _padPans[index]!,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSettingRow(
                    label: 'PAN (L <-> R)',
                    value: _padPans[index]!,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (v) {
                      setSheetState(() => _padPans[index] = v);
                      setState(() {});
                      _audioEngine.setDrumPadParams(
                        'pad_${index + 1}',
                        _padVolumes[index]!,
                        _padPans[index]!,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingRow({
    required String label,
    required double value,
    double min = 0.0,
    double max = 1.0,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.orangeAccent,
            inactiveTrackColor: Colors.grey[900],
            thumbColor: Colors.white,
            overlayColor: Colors.orangeAccent.withValues(alpha: 0.1),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  static const double _panelWidth = 400.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _panelWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          left: BorderSide(
            color: Colors.orangeAccent.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
            ),
            child: const Row(
              children: [
                Icon(Icons.grid_view, color: Colors.orangeAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'DRUM RACK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                childAspectRatio: 1.05,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return _buildPad(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPad(int index) {
    final bool pressed = _isPressed[index];
    final Color padColor = _getPadColor(index);

    return GestureDetector(
      onLongPress: () => _showPadSettings(index),
      child: Listener(
        onPointerDown: (_) => _handleTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          decoration: BoxDecoration(
            color: pressed ? padColor : Colors.grey[950],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: pressed ? padColor.withValues(alpha: 0.8) : Colors.grey[900]!,
              width: 1.5,
            ),
            boxShadow: pressed
                ? [
                    BoxShadow(
                      color: padColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: pressed ? Colors.white : Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.music_note,
                  size: 12,
                  color: pressed ? Colors.white : Colors.grey[800],
                ),
                if (_padVolumes[index] != 1.0 || _padPans[index] != 1.0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPadColor(int index) {
    switch (index % 4) {
      case 0:
        return Colors.orangeAccent;
      case 1:
        return Colors.cyanAccent;
      case 2:
        return Colors.pinkAccent;
      case 3:
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }
}
