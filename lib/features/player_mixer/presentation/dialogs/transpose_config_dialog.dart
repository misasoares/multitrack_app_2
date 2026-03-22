import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/track.dart';
import '../stores/stage_store.dart';

class TransposeConfigDialog extends StatelessWidget {
  final String itemId;
  final StageStore store;

  const TransposeConfigDialog({
    super.key,
    required this.itemId,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final item = store.currentSetlist?.items.firstWhere(
          (i) => i.id == itemId,
        );
        if (item == null) return const SizedBox.shrink();

        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'CONFIGURAÇÕES DE TOM',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Global Transpose Selector
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 340;
                        final centerWidth = isNarrow ? 90.0 : 140.0;
                        final semitoneFontSize = isNarrow ? 32.0 : 42.0;
                        return Column(
                          children: [
                            Text(
                              'TRANSPOSE GERAL',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildCircleButton(
                                  icon: Icons.remove,
                                  compact: isNarrow,
                                  onTap: () => store.updateItemTranspose(
                                    itemId,
                                    item.transposeSemitones - 1,
                                  ),
                                ),
                                Container(
                                  width: centerWidth,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.transposeSemitones > 0
                                            ? '+${item.transposeSemitones}'
                                            : '${item.transposeSemitones}',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: AppColors.primary,
                                          fontSize: semitoneFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'SEMITONES',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: Colors.white24,
                                          fontSize: isNarrow ? 9 : 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildCircleButton(
                                  icon: Icons.add,
                                  compact: isNarrow,
                                  onTap: () => store.updateItemTranspose(
                                    itemId,
                                    item.transposeSemitones + 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Track Selection Header
                  Text(
                    'PITCH POR TRACK (SMART OCTAVE):',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Track List
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: item.originalMusic.tracks.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final track = item.originalMusic.tracks[index];
                          return _TrackTransposeTile(
                            itemId: itemId,
                            track: track,
                            globalTranspose: item.transposeSemitones,
                            store: store,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'CONCLUÍDO',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final padding = compact ? 8.0 : 12.0;
    final iconSize = compact ? 20.0 : 24.0;
    return Material(
      color: const Color(0xFF2A2A2A),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _TrackTransposeTile extends StatelessWidget {
  final String itemId;
  final Track track;
  final int globalTranspose;
  final StageStore store;

  const _TrackTransposeTile({
    required this.itemId,
    required this.track,
    required this.globalTranspose,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    // Smart Octave Labeling
    String octaveLabel = 'OITAVA';
    if (track.octaveShift != 0) {
      octaveLabel = track.octaveShift > 0 ? '+1 OITAVA' : '-1 OITAVA';
    } else {
      if (globalTranspose < 0) {
        octaveLabel = '+1 OITAVA';
      } else if (globalTranspose > 0) {
        octaveLabel = '-1 OITAVA';
      }
    }

    final hasOctaveShift = track.octaveShift != 0;
    final canApplyOctave = track.applyTranspose && globalTranspose != 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Transpose Checkbox
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: track.applyTranspose,
              onChanged: (val) =>
                  store.toggleTrackTranspose(itemId, track.id, val ?? true),
              activeColor: AppColors.primary,
              checkColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: track.applyTranspose ? Colors.white : Colors.white24,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  track.applyTranspose ? 'TRANSPOSE ATIVO' : 'TOM ORIGINAL',
                  style: GoogleFonts.jetBrainsMono(
                    color: track.applyTranspose
                        ? AppColors.primary.withValues(alpha: 0.7)
                        : Colors.white10,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Smart Octave Button
          if (canApplyOctave)
            GestureDetector(
              onTap: () => store.toggleTrackOctave(itemId, track.id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasOctaveShift
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasOctaveShift ? AppColors.primary : Colors.white10,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasOctaveShift ? Icons.auto_awesome : Icons.exposure,
                      size: 14,
                      color: hasOctaveShift ? Colors.black : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      octaveLabel,
                      style: GoogleFonts.jetBrainsMono(
                        color: hasOctaveShift ? Colors.black : Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
