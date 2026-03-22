import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import '../stores/stage_store.dart';
import '../../domain/entities/app_mode.dart';
import '../widgets/live_mixer_widget.dart';

class StagePage extends StatefulWidget {
  const StagePage({super.key});

  @override
  State<StagePage> createState() => _StagePageState();
}

class _StagePageState extends State<StagePage> {
  late final StageStore store;

  @override
  void initState() {
    super.initState();
    store = GetIt.I<StageStore>();
    store.initialize().catchError((e) {
      debugPrint('## StageStore Init Error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final isRehearsal = store.mode == AppMode.rehearsal;

        return Scaffold(
          backgroundColor: const Color(0xFF050505),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            title: _buildModeToggle(),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey),
                onPressed: () {
                  // TODO: Open settings
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Info Bar (Artist/Song)
              _buildInfoBar(),

              Expanded(
                child: isRehearsal
                    ? _buildRehearsalView()
                    : _buildPerformanceView(),
              ),
            ],
          ),
          floatingActionButton: isRehearsal ? _buildRehearsalFAB() : null,
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeToggleButton(
            label: 'ENSAIO',
            isActive: store.mode == AppMode.rehearsal,
            activeColor: const Color(0xFFf9ac06),
            onPressed: () => store.setMode(AppMode.rehearsal),
          ),
          _ModeToggleButton(
            label: 'PALCO',
            isActive: store.mode == AppMode.performance,
            activeColor: Colors.redAccent,
            onPressed: () => store.setMode(AppMode.performance),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    final item = store.currentItem;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Column(
        children: [
          Text(
            item?.originalMusic.title.toUpperCase() ?? 'NO SONG SELECTED',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'JetBrains Mono',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          if (item != null) ...[
            const SizedBox(height: 4),
            Text(
              'BPM: ${item.originalMusic.bpm} | KEY: ${item.originalMusic.key.isEmpty ? "N/A" : item.originalMusic.key}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRehearsalView() {
    final item = store.currentItem;
    if (item == null) {
      return const Center(
        child: Text(
          'SELECT A SONG FROM SETLIST',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Mixer Section
        Expanded(
          flex: 2,
          child: LiveMixerWidget(
            // Passing StageStore after we refactor it
            store: store,
            itemId: item.id,
            songTitle: item.originalMusic.title,
            audioEngine: GetIt.I(),
            onReset: () {},
            onSave: () {},
          ),
        ),

        // Rehearsal Controls (Pitch / Tempo)
        _buildRehearsalControls(item),
      ],
    );
  }

  Widget _buildRehearsalControls(dynamic item) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0A0A0A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ControlKnob(
            label: 'PITCH',
            value:
                '${item.transposeSemitones > 0 ? "+" : ""}${item.transposeSemitones}',
          ),
          _ControlKnob(
            label: 'TEMPO',
            value: '${(item.tempoFactor * 100).toInt()}%',
          ),
          ElevatedButton.icon(
            onPressed: store.isRendering ? null : () => store.renderSetlist(),
            icon: store.isRendering
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bolt),
            label: Text(store.isRendering ? 'RENDERING...' : 'RENDER SETLIST'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf9ac06),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceView() {
    return const Center(
      child: Text(
        'PERFORMANCE MODE - TIMELINE COMING SOON',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRehearsalFAB() {
    return FloatingActionButton(
      onPressed: () {
        // TODO: Pick files
      },
      backgroundColor: const Color(0xFFf9ac06),
      child: const Icon(Icons.add, color: Colors.black),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;

  const _ModeToggleButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ControlKnob extends StatelessWidget {
  final String label;
  final String value;

  const _ControlKnob({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
