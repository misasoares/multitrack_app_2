import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../injection_container.dart';
import '../../domain/entities/setlist.dart';
import '../../domain/entities/music.dart';
import '../stores/create_setlist_store.dart';
import '../stores/setlist_library_store.dart';
import '../stores/music_library_store.dart';
import 'create_setlist_page.dart';

class SetlistLibraryPage extends StatefulWidget {
  const SetlistLibraryPage({super.key});

  @override
  State<SetlistLibraryPage> createState() => _SetlistLibraryPageState();
}

class _SetlistLibraryPageState extends State<SetlistLibraryPage> {
  late final SetlistLibraryStore _store;
  late final MusicLibraryStore _musicStore;

  @override
  void initState() {
    super.initState();
    _store = sl<SetlistLibraryStore>();
    _musicStore = sl<MusicLibraryStore>();
    _store.loadAllSetlists();
    _musicStore.loadAllMusic(); // Ensure we have music data for previews
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isNarrow ? Drawer(child: _buildSidebar(forDrawer: true)) : null,
      body: SafeArea(
        child: isNarrow
            ? Column(
                children: [
                  _SetlistHeader(
                    onMenuTap: () => Scaffold.of(context).openDrawer(),
                  ),
                  Expanded(child: _buildMainContent()),
                ],
              )
            : Row(
                children: [
                  _buildSidebar(forDrawer: false),
                  Expanded(
                    child: Column(
                      children: [
                        const _SetlistHeader(),
                        Expanded(child: _buildMainContent()),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSidebar({required bool forDrawer}) {
    return Container(
      width: forDrawer ? null : 280,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(right: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(
                  Icons.grid_view,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'MY SETLISTS',
                  style: AppTextStyles.headingS.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _SidebarItem(
            icon: Icons.queue_music,
            label: 'All Setlists',
            isActive: true,
            count: _store.setlists.length,
          ),
          _SidebarItem(
            icon: Icons.calendar_today,
            label: 'Upcoming',
            count: 0,
          ),
          _SidebarItem(icon: Icons.archive, label: 'Archive', count: 0),
          _SidebarItem(
            icon: Icons.delete_outline,
            label: 'Trash',
            count: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Observer(
      builder: (_) {
        if (_store.isLoading || _musicStore.isLoading) {
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

        final allItems = [
          null,
          ..._store.setlists,
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return GridView.builder(
              padding: EdgeInsets.all(isNarrow ? 16 : 32),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isNarrow ? 280 : 400,
                crossAxisSpacing: isNarrow ? 12 : 24,
                mainAxisSpacing: isNarrow ? 12 : 24,
                childAspectRatio: isNarrow ? 0.72 : 0.85,
              ),
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];

                if (item == null) {
                  return _NewSetlistCard(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateSetlistPage(
                            store: sl<CreateSetlistStore>(),
                          ),
                        ),
                      );
                      _store.loadAllSetlists();
                    },
                  );
                }

                final previewMusics = item.items
                    .take(3)
                    .map((sli) => sli.originalMusic)
                    .toList();

                return _SetlistGridCard(
                  setlist: item,
                  previewMusics: previewMusics,
                  onTap: () async {
                    final editStore = sl<CreateSetlistStore>();
                    editStore.initFromSetlist(item);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateSetlistPage(store: editStore),
                      ),
                    );
                    _store.loadAllSetlists();
                  },
                  onDelete: () => _store.deleteSetlist(item.id),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SetlistHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const _SetlistHeader({this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(
        horizontal: onMenuTap != null ? 16 : 32,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          if (onMenuTap != null) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu, color: AppColors.textMuted),
              tooltip: 'Open menu',
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              'LIBRARY / ALL SETLISTS',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textMuted,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            ),
          const SizedBox(width: 8),
          if (onMenuTap == null) ...[
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, color: AppColors.textMuted),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int count;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isActive
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textMuted,
          size: 20,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: count > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              )
            : null,
        onTap: () {},
      ),
    );
  }
}

class _SetlistGridCard extends StatelessWidget {
  final Setlist setlist;
  final List<Music> previewMusics;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SetlistGridCard({
    required this.setlist,
    required this.previewMusics,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      setlist.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.more_horiz,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Preview Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SET PREVIEW',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (previewMusics.isEmpty)
                      Text(
                        'No tracks added',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF444444),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...previewMusics.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final music = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                index.toString().padLeft(2, '0'),
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  music.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFCCCCCC),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                border: Border(top: BorderSide(color: Color(0xFF222222))),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_list_numbered,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${setlist.items.length} TRACKS',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  // Placeholder for total duration calculation if available
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewSetlistCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NewSetlistCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: const Color(0xFF333333),
          strokeWidth: 2,
          dashPattern: const [6, 6],
          radius: const Radius.circular(2),
        ),
        child: Container(
          color: const Color(0xFF0F0F0F), // Slightly lighter detail
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New Setlist',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new empty setlist\nor import from previous',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
