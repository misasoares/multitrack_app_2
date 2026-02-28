import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/setlist.dart';
import '../stores/setlist_config_store.dart';
import '../widgets/setlist_song_config_tile.dart';
import '../../../../../injection_container.dart';

class SetlistMasteringPage extends StatefulWidget {
  final Setlist setlist;

  const SetlistMasteringPage({super.key, required this.setlist});

  @override
  State<SetlistMasteringPage> createState() => _SetlistMasteringPageState();
}

class _SetlistMasteringPageState extends State<SetlistMasteringPage> {
  late final SetlistConfigStore _store;

  @override
  void initState() {
    super.initState();
    _store = sl<SetlistConfigStore>();
    _store.init(widget.setlist);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          children: [
            Text(
              'MASTER SETLIST',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
            Text(
              'Ajuste os tons, andamentos e volumes antes da renderização final.',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textMuted),
            onPressed: () {
              // TODO: Settings
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF2A2A2A), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Observer(
              builder: (_) {
                final setlist = _store.currentSetlist;
                if (setlist == null) return const SizedBox();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    final crossAxisCount =
                        isNarrow ? 1 : (constraints.maxWidth > 900 ? 3 : 2);
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: isNarrow ? 380 : 360,
                      ),
                      itemCount: setlist.items.length,
                      itemBuilder: (context, index) {
                        final item = setlist.items[index];
                        return SetlistSongConfigTile(
                          key: ValueKey(item.id),
                          item: item,
                          index: index + 1,
                          store: _store, // Pass store
                          onPreviewToggle: () => _store.togglePreview(item.id),
                          onVolumeChanged: (vol) =>
                              _store.updateItemVolume(item.id, vol),
                          onTempoChanged: (val) =>
                              _store.updateItemTempo(item.id, val),
                          positionStream: _store.previewPosition,
                          onSeek: (pos) => _store.seek(pos),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final btnPadding = isNarrow
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
        final iconSize = isNarrow ? 14.0 : 16.0;
        final fontSize = isNarrow ? 11.0 : null;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 24,
            vertical: isNarrow ? 10 : 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Observer(
                    builder: (_) {
                      final setlist = _store.currentSetlist;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStat(
                            'SONG COUNT:',
                            (setlist?.items.length ?? 0)
                                .toString()
                                .padLeft(2, '0'),
                          ),
                          const SizedBox(height: 4),
                          _buildStat(
                            'TOTAL TIME:',
                            _formatDuration(_store.totalDuration),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _store.saveDraft();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rascunho salvo com sucesso!'),
                      ),
                    );
                  },
                  icon: Icon(Icons.save, size: iconSize),
                  label: Text(
                    'SAVE DRAFT',
                    style: fontSize != null
                        ? GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          )
                        : null,
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: Color(0xFF333333)),
                    padding: btnPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(width: isNarrow ? 8 : 12),
                ElevatedButton.icon(
                  onPressed: _store.currentSetlist == null ||
                          _store.currentSetlist!.items.isEmpty
                      ? null
                      : () => _onRenderShowPressed(context),
                  icon: Icon(Icons.ios_share, size: iconSize),
                  label: Text(
                    'RENDER SHOW',
                    style: fontSize != null
                        ? GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          )
                        : null,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: btnPadding,
                    textStyle: fontSize == null
                        ? GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold,
                          )
                        : GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _onRenderShowPressed(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ShowRenderDialog(store: _store),
    );
    try {
      await _store.renderShow();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Show renderizado e pronto para o palco!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao renderizar o show. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ShowRenderDialog extends StatelessWidget {
  const _ShowRenderDialog({required this.store});
  final SetlistConfigStore store;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        'Preparando Show...',
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Observer(
        builder: (_) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                store.renderMessage.isNotEmpty
                    ? store.renderMessage
                    : 'Preparando...',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: store.renderProgress.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF333333),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ],
          );
        },
      ),
    );
  }
}
