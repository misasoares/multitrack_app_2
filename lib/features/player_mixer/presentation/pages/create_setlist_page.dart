import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../../injection_container.dart';
import '../../domain/entities/setlist_item.dart';
import '../stores/create_setlist_store.dart';
import '../stores/music_library_store.dart';
import 'setlist_mastering_page.dart';

class CreateSetlistPage extends StatefulWidget {
  final CreateSetlistStore store;

  const CreateSetlistPage({super.key, required this.store});

  @override
  State<CreateSetlistPage> createState() => _CreateSetlistPageState();
}

class _CreateSetlistPageState extends State<CreateSetlistPage> {
  late TextEditingController _nameController;
  late final MusicLibraryStore _libraryStore;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.name);
    _libraryStore = sl<MusicLibraryStore>();
    // Load all music to display in the right panel
    _libraryStore.loadAllMusic();
  }

  @override
  void dispose() {
    widget.store.stop(); // Stop playback when leaving
    widget.store.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // Prevent keyboard from resizing UI
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                children: [
                  // Left Panel: Setlist (Chosen Music)
                  Expanded(flex: 5, child: _buildLeftPanel()),
                  // Divider
                  Container(width: 1, color: const Color(0xFF2A2A2A)),
                  // Right Panel: Library (All Music)
                  Expanded(flex: 4, child: _buildRightPanel()),
                ],
              ),
            ),
            _buildPlaybackBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _nameController,
              onChanged: (v) => widget.store.setName(v),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Setlist Name',
                hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Observer(
            builder: (_) => ElevatedButton.icon(
              onPressed: widget.store.isLoading
                  ? null
                  : () async {
                      await widget.store.saveSetlist();
                      if (!mounted) return;

                      if (widget.store.saveSuccess) {
                        final setlist = widget.store.savedSetlist;
                        if (setlist != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SetlistMasteringPage(setlist: setlist),
                            ),
                          );
                        }
                      } else if (widget.store.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.store.errorMessage!,
                              style: GoogleFonts.jetBrainsMono(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: widget.store.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.tune, size: 20),
              label: Text(
                widget.store.isLoading ? 'SAVING...' : 'CONFIRM & MASTER',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      color: AppColors.primary.withValues(
        alpha: 0.1,
      ), // Yellowish tint background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Large Duration
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SETLIST DURATION',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Observer(
                        builder: (_) => Text(
                          _formatDuration(widget.store.totalDuration),
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.primary,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Observer(
                  builder: (_) => Text(
                    '${widget.store.selectedItems.length} TRACKS',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: Observer(
              builder: (_) {
                if (widget.store.selectedItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'YOUR SETLIST IS EMPTY',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: widget.store.selectedItems.length,
                  onReorder: widget.store.reorderMusic,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A1A), // Dark yellow tint
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  itemBuilder: (context, index) {
                    final item = widget.store.selectedItems[index];

                    return Container(
                      key: ValueKey('${item.id}_$index'),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 4,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_indicator,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        title: Text(
                          item.originalMusic.title.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                        ),
                        subtitle: Text(
                          '${item.originalMusic.artist} • ${item.originalMusic.bpm} BPM',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDuration(_getItemDuration(item)),
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => widget.store.removeMusic(index),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildRightPanel() {
    return Container(
      color: Colors.black, // Pure black background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIBRARY',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: GoogleFonts.jetBrainsMono(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'SEARCH SONGS, ARTISTS...',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF555555),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF555555),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: Observer(
              builder: (_) {
                if (_libraryStore.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _libraryStore.musicList.length,
                  itemBuilder: (context, index) {
                    final music = _libraryStore.musicList[index];
                    final isInSetlist = widget.store.selectedItems.any(
                      (item) => item.originalMusic.id == music.id,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  music.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${music.artist} • ${music.bpm} BPM',
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF666666),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.store.addMusic(music),
                              borderRadius: BorderRadius.circular(4),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isInSetlist
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isInSetlist ? Icons.check : Icons.add,
                                  color: isInSetlist
                                      ? Colors.black
                                      : AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildPlaybackBar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Duration _getItemDuration(SetlistItem item) {
    if (item.originalMusic.tracks.isEmpty) return Duration.zero;
    return item.originalMusic.tracks
        .map((t) => t.duration)
        .reduce((a, b) => a > b ? a : b);
  }
}
