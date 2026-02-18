import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../injection_container.dart';
import '../stores/music_library_store.dart';
import '../stores/create_music_store.dart';
import 'create_music_page.dart';

class MusicLibraryPage extends StatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  late final MusicLibraryStore _store;

  @override
  void initState() {
    super.initState();
    _store = sl<MusicLibraryStore>();
    _store.loadAllMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('MUSIC LIBRARY', style: AppTextStyles.h1),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateMusicPage(store: sl<CreateMusicStore>()),
            ),
          );
          // Refresh list when returning
          _store.loadAllMusic();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'NEW PROJECT',
          style: AppTextStyles.buttonLabel.copyWith(color: Colors.black),
        ),
      ),
      body: Observer(
        builder: (_) {
          if (_store.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (_store.errorMessage != null) {
            return Center(
              child: Text(
                _store.errorMessage!,
                style: AppTextStyles.bodyMuted.copyWith(color: AppColors.alert),
              ),
            );
          }

          if (_store.musicList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.music_note,
                    size: 64,
                    color: AppColors.surfaceHighlight,
                  ),
                  const SizedBox(height: 16),
                  Text('No music found', style: AppTextStyles.bodyMuted),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _store.musicList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final music = _store.musicList[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceHighlight),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(music.title, style: AppTextStyles.headingS),
                  subtitle: Text(
                    music.artist.isEmpty ? 'Unknown Artist' : music.artist,
                    style: AppTextStyles.bodyMuted,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InfoBadge(label: '${music.bpm} BPM', icon: Icons.speed),
                      const SizedBox(width: 12),
                      _InfoBadge(
                        label: '${music.tracks.length} Tracks',
                        icon: Icons.layers,
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Open Player/Mixer for this music
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelMuted.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
