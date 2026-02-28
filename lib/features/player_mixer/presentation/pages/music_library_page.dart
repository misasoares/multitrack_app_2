import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../injection_container.dart';
import '../../domain/entities/music.dart';
import '../stores/music_library_store.dart';
import '../enums/music_sort_type.dart';
import '../stores/create_music_store.dart';
import 'create_music_page.dart';
import 'setlist_library_page.dart';
import 'package:multitracks_df_pro/features/performance/presentation/pages/performance_list_page.dart';

class MusicLibraryPage extends StatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  late final MusicLibraryStore _store;
  bool _isGlobalLoading = false; // For full-screen loading during edit

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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _LibraryHeader(
                  onCreate: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateMusicPage(store: sl<CreateMusicStore>()),
                      ),
                    );
                    _store.loadAllMusic();
                  },
                ),
                _FilterBar(),
                Expanded(
                  child: Observer(
                    builder: (_) {
                      if (_store.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      if (_store.errorMessage != null) {
                        return Center(
                          child: Text(
                            _store.errorMessage!,
                            style: AppTextStyles.bodyMuted.copyWith(
                              color: AppColors.alert,
                            ),
                          ),
                        );
                      }

                      if (_store.filteredMusicList.isEmpty) {
                        return _EmptyState(
                          onCreate: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateMusicPage(
                                  store: sl<CreateMusicStore>(),
                                ),
                              ),
                            );
                            _store.loadAllMusic();
                          },
                        );
                      }

                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(24),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 400,
                                    mainAxisExtent:
                                        300, // Increased to 300 to fix overflow
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final music = _store.filteredMusicList[index];
                                return _SongCard(
                                  music: music,
                                  onEdit: () async {
                                    debugPrint('Edit music: ${music.title}');
                                    setState(() => _isGlobalLoading = true);
                                    try {
                                      final createStore =
                                          sl<CreateMusicStore>();
                                      await createStore.loadMusic(music);

                                      if (!context.mounted) return;

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateMusicPage(
                                            store: createStore,
                                          ),
                                        ),
                                      );
                                      // Refresh library on return
                                      _store.loadAllMusic();
                                    } finally {
                                      if (mounted) {
                                        setState(
                                          () => _isGlobalLoading = false,
                                        );
                                      }
                                    }
                                  },
                                  onDelete: () {
                                    _showDeleteConfirmation(context, music);
                                  },
                                );
                              }, childCount: _store.filteredMusicList.length),
                            ),
                          ),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 80),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const _BottomNavBar(),
              ],
            ),
            if (_isGlobalLoading)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Music music) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Delete Song',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${music.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _store.deleteMusic(music.id);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final VoidCallback onCreate;

  const _LibraryHeader({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0A),
            border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          child: Row(
            children: [
              // Left: Icon + Title (hidden on narrow)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(Icons.library_music, color: AppColors.primary),
              ),
              SizedBox(width: isNarrow ? 8 : 16),
              if (!isNarrow) ...[
                Flexible(
                  child: Text(
                    'SONG LIBRARY',
                    style: AppTextStyles.h1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isNarrow ? 8 : 48),
              ],

              // Center: Search Bar (hidden on narrow/portrait)
              if (!isNarrow)
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF181818),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            onChanged: (value) =>
                                sl<MusicLibraryStore>().setSearchQuery(value),
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: 'SEARCH TRACKS, ARTISTS, OR TAGS_',
                              hintStyle: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF444444)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⌘K',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isNarrow) const Spacer(),

              SizedBox(width: isNarrow ? 8 : 48),

              // Right: Create Button (icon-only on narrow)
              if (isNarrow)
                IconButton(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'Create new song',
                )
              else
                ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    'CREATE NEW SONG',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = sl<MusicLibraryStore>();

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterTab(label: 'All Songs', isActive: true),
            const SizedBox(width: 32),
            _FilterTab(label: 'Recent', isActive: false),
            const SizedBox(width: 32),
            _FilterTab(label: 'Favorites', isActive: false),
            const SizedBox(width: 24),
            // Duration Filter Button
            TextButton.icon(
              onPressed: () => _showDurationFilterDialog(context, store),
              icon: const Icon(Icons.timer, size: 16, color: AppColors.textMuted),
              label: Text(
                'DURATION',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 24, color: Color(0xFF2A2A2A)),
            const SizedBox(width: 16),
            Text(
              'SORT BY:',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Observer(
              builder: (_) => DropdownButton<MusicSortType>(
              value: store.sortBy,
              dropdownColor: const Color(0xFF1E1E1E),
              underline: const SizedBox(),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFFCCCCCC),
                size: 16,
              ),
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFCCCCCC),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (MusicSortType? newValue) {
                if (newValue != null) {
                  store.setSortBy(newValue);
                }
              },
              items: MusicSortType.values.map((MusicSortType value) {
                return DropdownMenuItem<MusicSortType>(
                  value: value,
                  child: Text(_getSortLabel(value)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _getSortLabel(MusicSortType type) {
    switch (type) {
      case MusicSortType.dateDesc:
        return 'DATE ADDED (NEWEST)';
      case MusicSortType.dateAsc:
        return 'DATE ADDED (OLDEST)';
      case MusicSortType.alphaAsc:
        return 'A-Z';
      case MusicSortType.alphaDesc:
        return 'Z-A';
      case MusicSortType.durationDesc:
        return 'DURATION (LONG)';
      case MusicSortType.durationAsc:
        return 'DURATION (SHORT)';
    }
  }

  void _showDurationFilterDialog(
    BuildContext context,
    MusicLibraryStore store,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Filter by Duration',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Observer(
            builder: (_) => SizedBox(
              height: 100,
              width: 300,
              child: Column(
                children: [
                  RangeSlider(
                    values: RangeValues(
                      store.minDurationFilter,
                      store.maxDurationFilter,
                    ),
                    min: 0,
                    max: 20, // Max 20 minutes
                    divisions: 20,
                    labels: RangeLabels(
                      '${store.minDurationFilter.round()}m',
                      '${store.maxDurationFilter.round()}m',
                    ),
                    activeColor: AppColors.primary,
                    inactiveColor: const Color(0xFF333333),
                    onChanged: (RangeValues values) {
                      store.setDurationRange(values.start, values.end);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${store.minDurationFilter.round()} min - ${store.maxDurationFilter.round()} min',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'DONE',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterTab({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isActive
            ? const Border(
                bottom: BorderSide(color: AppColors.primary, width: 2),
              )
            : null,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: isActive ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SongCard extends StatefulWidget {
  final Music music;
  final Future<void> Function() onEdit;
  final VoidCallback onDelete;

  const _SongCard({
    required this.music,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<_SongCard> {
  bool isHovered = false;
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isHovered
                ? AppColors.primary.withValues(alpha: 0.5)
                : const Color(0xFF2A2A2A),
          ),
        ),
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.music.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isHovered
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                          ),
                          // Duration Display
                          if (widget.music.tracks.isNotEmpty)
                            Text(
                              _formatDuration(widget.music.tracks[0].duration),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.music.artist.isEmpty
                            ? 'Unknown Artist'
                            : widget.music.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions (Edit/Delete)
                Row(
                  children: [
                    _IconBtn(
                      Icons.edit,
                      onTap: () async {
                        if (isEditing) return;
                        setState(() => isEditing = true);
                        try {
                          await widget.onEdit();
                        } finally {
                          if (mounted) setState(() => isEditing = false);
                        }
                      },
                      isLoading: isEditing,
                    ),
                    const SizedBox(width: 4),
                    _IconBtn(
                      Icons.delete,
                      onTap: widget.onDelete,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12), // Reduced spacing
            // Stats Row (Replaced GridView)
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'TEMPO / SIG',
                    value:
                        '${widget.music.bpm} BPM | ${widget.music.timeSignatureNumerator}/${widget.music.timeSignatureDenominator}',
                    isAccent: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    label: 'DURATION',
                    value: widget.music.tracks.isNotEmpty
                        ? _formatDuration(widget.music.tracks[0].duration)
                        : '--:--',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // Reduced spacing
            // Configuration Box (Full Width)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIGURATION',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.music.tracks.length} TRACKS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFCCCCCC),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(), // Use spacer to push button to bottom
            // Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Add to setlist logic
                },
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('ADD TO SETLIST'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes); // Support > 60 mins
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isAccent;

  const _StatBox({
    required this.label,
    required this.value,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isAccent ? AppColors.primary : const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isLoading;

  const _IconBtn(
    this.icon, {
    required this.onTap,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                icon,
                size: 18,
                color: isDestructive ? Colors.red : AppColors.textMuted,
              ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarItem(
            icon: Icons.library_music,
            label: 'LIBRARY',
            isActive: true,
          ),
          _NavBarItem(
            icon: Icons.queue_music,
            label: 'SETLISTS',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SetlistLibraryPage()),
              );
            },
          ),
          _NavBarItem(
            icon: Icons.play_circle_filled,
            label: 'PERFORMANCE',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerformanceListPage()),
              );
            },
          ),
          _NavBarItem(icon: Icons.settings, label: 'SYSTEM'),
          _NavBarItem(icon: Icons.account_circle, label: 'PROFILE'),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : const Color(0xFF555555);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onCreate,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.5),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 32,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'IMPORT TRACK',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
