import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/setlist_item.dart';
import '../dialogs/transpose_config_dialog.dart';
import '../stores/setlist_config_store.dart';
import 'eq/eq_interactive_dialog.dart';
import 'preview_timeline.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/audio_engine/audio_dsp_service.dart';

class SetlistSongConfigTile extends StatelessWidget {
  final SetlistItem item;
  final int index;
  // isPlaying and isLoadingPreview removed as they are observed directly
  final VoidCallback onPreviewToggle;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onTempoChanged;
  final ValueChanged<int> onTransposeChanged;
  final Function(List<String>) onTransposableTracksChanged;
  final Stream<Duration> positionStream;
  final ValueChanged<Duration> onSeek;
  final SetlistConfigStore store; // NEW

  const SetlistSongConfigTile({
    super.key,
    required this.item,
    required this.index,
    // required this.isPlaying, // Removed
    // this.isLoadingPreview = false, // Removed
    required this.onPreviewToggle,
    required this.onVolumeChanged,
    required this.onTempoChanged,
    required this.onTransposeChanged,
    required this.onTransposableTracksChanged,
    required this.positionStream,
    required this.onSeek,
    required this.store, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final isPlaying = store.playingItemId == item.id && store.isPlaying;
        final isLoadingPreview = store.previewLoadingItemId == item.id;

        return Container(
          // margin removed for GridView compatibility
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPlaying ? AppColors.primary : const Color(0xFF333333),
              width: isPlaying ? 1 : 0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Index + Title + Badges
              Row(
                children: [
                  Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.jetBrainsMono(
                      color: isPlaying
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.originalMusic.title.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        color: isPlaying
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBadge('Orig Key: ${item.originalMusic.key}'),
                      const SizedBox(height: 4),
                      _buildBadge('Orig BPM: ${item.originalMusic.bpm}'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Volume Control
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'VOL',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary.withValues(
                          alpha: 0.3,
                        ),
                        inactiveTrackColor: const Color(0xFF333333),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.1),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: item.volume.clamp(0.0, 1.5),
                        min: 0.0,
                        max: 1.5,
                        onChanged: onVolumeChanged,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${_formatDb(item.volume)} dB',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // BPM Control
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'BPM',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildBpmButton(
                    icon: Icons.remove,
                    onTap: () => onTempoChanged(
                      (item.tempoFactor - 0.05).clamp(0.5, 2.0),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: Text(
                        '${(item.tempoFactor * 100).round()}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _buildBpmButton(
                    icon: Icons.add,
                    onTap: () => onTempoChanged(
                      (item.tempoFactor + 0.05).clamp(0.5, 2.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions: Transpose & Global EQ
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.music_note,
                      label: 'TRANSPOSE',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => TransposeConfigDialog(
                            item: item,
                            onConfirm: (val) => onTransposeChanged(val),
                            onTracksChanged: (tracks) =>
                                onTransposableTracksChanged(tracks),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEffectsButton(context)),
                ],
              ),
              const SizedBox(height: 24),

              // Preview Timeline
              if (isLoadingPreview)
                Container(
                  height: 48, // Match button height
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (isPlaying)
                PreviewTimeline(
                  totalDuration: item.originalMusic.duration,
                  positionStream: positionStream,
                  onPlayPause: onPreviewToggle,
                  onSeek: onSeek,
                  isPlaying: isPlaying,
                )
              else
                _buildActionButton(
                  context,
                  icon: Icons.play_circle_outline,
                  label: 'PREVIEW SONG',
                  onTap: onPreviewToggle,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textMuted,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildBpmButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Icon(icon, color: AppColors.textMuted, size: 16),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDb(double volume) {
    if (volume == 0) return '-∞';
    // Rough approx for display: 1.0 = 0dB.
    // Let's just show relative value for now or standard log conversion
    // Actually, usually volume 1.0 is 0dB.
    // volume 0.5 is approx -6dB.
    // volume 0.0 is -inf.

    // Simpler display logic based on slider 0.0-1.5 range
    // 1.0 is 0.0 dB
    // > 1.0 is +dB
    // < 1.0 is -dB

    // Just mapping 0.0-1.5 linearly-ish to dB for display
    // or standard formula: 20 * log10(volume)
    // dart:math needed for log.
    // Let's stick to simple formatting:

    double dbValue = 0.0;
    if (volume > 0) {
      // Log10 is not available without import dart:math
      // We'll just display a relative percentage-like or simplified dB
      // For this widget, let's keep it simple:
      // (Volume - 1.0) * 10 mostly visual
      dbValue = (volume - 1.0) * 10;
    } else {
      return '-∞';
    }

    return '${dbValue >= 0 ? '+' : ''}${dbValue.toStringAsFixed(1)}';
  }

  Widget _buildEffectsButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Material(
        color: Colors.transparent,
        child: PopupMenuButton<String>(
          offset: const Offset(0, 48),
          color: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFF333333)),
          ),
          onSelected: (value) {
            if (value == 'eq') {
              showDialog(
                context: context,
                builder: (context) => EqInteractiveDialog(
                  trackId:
                      'master_${item.id}', // Logic to be refined if per-track is needed, but this is 'Global' per song
                  dspService:
                      GetIt.I<
                        AudioDspService
                      >(), // Assuming GetIt or passing via properties
                  initialBands: item.masterEqBands,
                  onBandChanged: (band) {
                    store.updateItemMasterEq(item.id, band);
                  },
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'eq',
              height: 40,
              child: Row(
                children: [
                  const Icon(
                    Icons.graphic_eq,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'EQUALIZER',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_fix_high,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'EFFECTS',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
