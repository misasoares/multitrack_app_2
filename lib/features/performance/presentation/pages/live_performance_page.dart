import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multitracks_df_pro/core/theme/app_colors.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/setlist.dart';

/// Placeholder para a tela de performance ao vivo (setlist renderizado no palco).
/// Será substituída pela implementação completa de controle de playback em show.
class LivePerformancePage extends StatelessWidget {
  final Setlist setlist;

  const LivePerformancePage({super.key, required this.setlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          setlist.name,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, size: 80, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 24),
            Text(
              'Live Performance',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tela em construção — controle de playback no palco.',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
