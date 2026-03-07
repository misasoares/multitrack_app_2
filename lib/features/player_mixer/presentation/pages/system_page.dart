import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../injection_container.dart';
import '../stores/system_store.dart';

class SystemPage extends StatefulWidget {
  const SystemPage({super.key});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  late final SystemStore _store;

  @override
  void initState() {
    super.initState();
    _store = sl<SystemStore>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SystemHeader(store: _store),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Observer(
                      builder: (_) {
                        if (_store.errorMessage != null) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _store.errorMessage!,
                              style: AppTextStyles.bodyMuted.copyWith(
                                color: AppColors.alert,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        if (_store.devices.isEmpty) {
                          return SizedBox(
                            height: 300,
                            child: _EmptyDevicesState(
                              isScanning: _store.isScanning,
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          itemCount: _store.devices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final device = _store.devices[index];
                            return _MidiDeviceTile(
                              device: device,
                              onConnect: () => _store.connectToDevice(device),
                              onDisconnect: () =>
                                  _store.disconnectFromDevice(device),
                            );
                          },
                        );
                      },
                    ),
                    const Divider(color: Color(0xFF2A2A2A), height: 1),
                    _MidiLearnSection(store: _store),
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

class _SystemHeader extends StatelessWidget {
  final SystemStore store;

  const _SystemHeader({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SISTEMA & HARDWARE', style: AppTextStyles.h1),
                Text(
                  'Configure seus dispositivos MIDI Bluetooth',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          Observer(
            builder: (_) => ElevatedButton.icon(
              onPressed: store.isScanning
                  ? store.stopScanning
                  : store.startScanning,
              icon: store.isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.bluetooth_audio, size: 20),
              label: Text(
                store.isScanning ? 'CANCELAR' : 'ESCANEAR BLE',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MidiDeviceTile extends StatelessWidget {
  final MidiDevice device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _MidiDeviceTile({
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = device.connected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isConnected
              ? AppColors.primary.withValues(alpha: 0.5)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.piano,
              color: isConnected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected ? 'CONECTADO' : 'DESCONECTADO',
                  style: GoogleFonts.jetBrainsMono(
                    color: isConnected
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: isConnected ? onDisconnect : onConnect,
            style: OutlinedButton.styleFrom(
              foregroundColor: isConnected ? Colors.red : AppColors.primary,
              side: BorderSide(
                color: isConnected ? Colors.red : AppColors.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              isConnected ? 'DESCONECTAR' : 'CONECTAR',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MidiLearnSection extends StatelessWidget {
  final SystemStore store;

  const _MidiLearnSection({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_input_component,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'MAPEAMENTO DO DRUM KIT (MIDI LEARN)',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Assinale as notas do seu controlador aos pads do app.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.3,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final padId = 'pad_${index + 1}';
                return Observer(
                  builder: (_) {
                    final mappedNote = store.midiDrumMap.entries
                        .where((e) => e.value == padId)
                        .map((e) => e.key)
                        .firstOrNull;

                    return _DrumPadMapTile(
                      padName: 'PAD ${index + 1}',
                      mappedNote: mappedNote,
                      isLearning: store.padInLearnMode == padId,
                      onTap: () => store.startLearning(padId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrumPadMapTile extends StatefulWidget {
  final String padName;
  final int? mappedNote;
  final bool isLearning;
  final VoidCallback onTap;

  const _DrumPadMapTile({
    required this.padName,
    this.mappedNote,
    required this.isLearning,
    required this.onTap,
  });

  @override
  State<_DrumPadMapTile> createState() => _DrumPadMapTileState();
}

class _DrumPadMapTileState extends State<_DrumPadMapTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          final color = widget.isLearning
              ? AppColors.primary.withValues(
                  alpha: _blinkController.value * 0.5 + 0.1,
                )
              : const Color(0xFF161616);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isLearning
                    ? AppColors.primary
                    : const Color(0xFF2A2A2A),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.padName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isLearning
                      ? 'PRESSIONE hardware...'
                      : (widget.mappedNote != null
                            ? 'NOTA: ${widget.mappedNote}'
                            : 'NENHUMA'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    color: widget.isLearning
                        ? Colors.white
                        : (widget.mappedNote != null
                              ? AppColors.primary
                              : AppColors.textMuted),
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.isLearning) ...[
                  const SizedBox(height: 8),
                  Text(
                    'MAPEAR',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyDevicesState extends StatelessWidget {
  final bool isScanning;

  const _EmptyDevicesState({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isScanning ? Icons.radar : Icons.bluetooth_disabled,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            isScanning
                ? 'PROCURANDO DISPOSITIVOS...'
                : 'NENHUM DISPOSITIVO ENCONTRADO',
            style: AppTextStyles.headingS.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            isScanning
                ? 'Certifique-se de que seu controlador está em modo de pareamento.'
                : 'Toque em ESCANEAR para buscar controladores MIDI BLE próximos.',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
