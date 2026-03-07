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

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed[index] = true);
    _audioEngine.triggerDrumPad('pad_${index + 1}');

    // Quick visual reset
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isPressed[index] = false);
      }
    });
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

    return Listener(
      onPointerDown: (_) => _handleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        decoration: BoxDecoration(
          color: pressed ? padColor : Colors.grey[950],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: pressed ? padColor.withOpacity(0.8) : Colors.grey[900]!,
            width: 1.5,
          ),
          boxShadow: pressed
              ? [
                  BoxShadow(
                    color: padColor.withOpacity(0.4),
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
            ],
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
