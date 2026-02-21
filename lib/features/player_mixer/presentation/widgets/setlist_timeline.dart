import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/setlist_item.dart';
import '../stores/create_setlist_store.dart';

class SetlistTimeline extends StatelessWidget {
  final CreateSetlistStore store;
  final double height;

  const SetlistTimeline({super.key, required this.store, this.height = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Observer(
          builder: (_) {
            if (store.selectedItems.isEmpty) {
              return Center(
                child: Text(
                  "TIMELINE",
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF555555),
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              );
            }

            final totalDuration = store.totalDuration;
            if (totalDuration.inMilliseconds == 0) {
              return const SizedBox.shrink();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;

                return Stack(
                  children: [
                    Row(
                      children: store.selectedItems.map((item) {
                        final itemDuration = _getItemDuration(item);
                        final width =
                            itemDuration.inMilliseconds /
                            totalDuration.inMilliseconds *
                            totalWidth;

                        final isCurrent =
                            store.selectedItems.indexOf(item) ==
                            store.currentItemIndex;

                        // Alternate colors for better visibility
                        final index = store.selectedItems.indexOf(item);
                        final color = isCurrent
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : (index % 2 == 0
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFF222222));

                        return Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border(
                              right: BorderSide(
                                color: Colors.black.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child:
                              width >
                                  40 // Only show text if space allows
                              ? Text(
                                  item.originalMusic.title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: isCurrent
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                    ),

                    // Playhead
                    Observer(
                      builder: (_) {
                        // Calculate global position
                        double currentGlobalMs = 0;
                        for (int i = 0; i < store.currentItemIndex; i++) {
                          if (i < store.selectedItems.length) {
                            currentGlobalMs += _getItemDuration(
                              store.selectedItems[i],
                            ).inMilliseconds;
                          }
                        }
                        currentGlobalMs +=
                            store.currentItemPosition.inMilliseconds;

                        final playheadLeft =
                            currentGlobalMs /
                            totalDuration.inMilliseconds *
                            totalWidth;

                        return Positioned(
                          left: playheadLeft,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 2,
                            color: Colors.white,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  top: 0,
                                  left: -3,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Duration _getItemDuration(SetlistItem item) {
    if (item.originalMusic.tracks.isEmpty) return Duration.zero;
    return item.originalMusic.tracks
        .map((t) => t.duration)
        .reduce((a, b) => a > b ? a : b);
  }
}
