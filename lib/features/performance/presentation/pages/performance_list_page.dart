import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multitracks_df_pro/core/theme/app_colors.dart';
import 'package:multitracks_df_pro/core/theme/app_text_styles.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/setlist.dart';
import 'package:multitracks_df_pro/features/player_mixer/presentation/pages/setlist_mastering_page.dart';
import 'package:multitracks_df_pro/injection_container.dart';
import '../stores/performance_list_store.dart';
import 'live_performance_page.dart';

/// Duração total do setlist (soma do maior duration das tracks de cada item).
Duration _totalSetlistDuration(Setlist setlist) {
  var total = Duration.zero;
  for (final item in setlist.items) {
    var maxItem = Duration.zero;
    for (final t in item.originalMusic.tracks) {
      if (t.duration > maxItem) maxItem = t.duration;
    }
    total += maxItem;
  }
  return total;
}

/// Formata duração: HH:MM:SS se houver horas, senão apenas MM:SS.
String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class PerformanceListPage extends StatefulWidget {
  const PerformanceListPage({super.key});

  @override
  State<PerformanceListPage> createState() => _PerformanceListPageState();
}

class _PerformanceListPageState extends State<PerformanceListPage> {
  late final PerformanceListStore _store;
  String _filter = 'All'; // All | Drafts | Rendered | Archived

  @override
  void initState() {
    super.initState();
    _store = sl<PerformanceListStore>();
    _store.loadSetlists();
  }

  List<Setlist> get _filteredSetlists {
    switch (_filter) {
      case 'Drafts':
        return _store.setlists.where((s) => !_store.isSetlistRendered(s)).toList();
      case 'Rendered':
        return _store.setlists.where((s) => _store.isSetlistRendered(s)).toList();
      case 'Archived':
        return []; // TODO: quando existir status archived
      default:
        return _store.setlists;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PerformanceHeader(),
            _SearchAndFilterBar(
              filter: _filter,
              onFilterChanged: (v) => setState(() => _filter = v),
            ),
            Expanded(
              child: Observer(
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
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final list = _filteredSetlists;
                  if (list.isEmpty) {
                    return _EmptyPerformanceState(
                      hasSetlists: _store.setlists.isNotEmpty,
                      filter: _filter,
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final setlist = list[index];
                      final isRendered = _store.isSetlistRendered(setlist);
                      return _SetlistPerformanceCard(
                        setlist: setlist,
                        isRendered: isRendered,
                        onTap: () => _onSetlistTap(context, setlist, isRendered),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSetlistTap(BuildContext context, Setlist setlist, bool isRendered) {
    if (isRendered) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LivePerformancePage(setlist: setlist),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SetlistMasteringPage(setlist: setlist),
        ),
      ).then((_) => _store.loadSetlists());
    }
  }
}

class _PerformanceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          const Icon(Icons.queue_music, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Text('Setlist Library', style: AppTextStyles.h1.copyWith(fontSize: 22)),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Setlist'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onFilterChanged;

  const _SearchAndFilterBar({required this.filter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search setlists, songs, or venues...',
                      hintStyle: AppTextStyles.bodyMuted.copyWith(fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: AppTextStyles.bodyPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterPill(label: 'All', isActive: filter == 'All', onTap: () => onFilterChanged('All')),
              const SizedBox(width: 8),
              _FilterPill(label: 'Drafts', isActive: filter == 'Drafts', onTap: () => onFilterChanged('Drafts')),
              const SizedBox(width: 8),
              _FilterPill(label: 'Rendered', isActive: filter == 'Rendered', onTap: () => onFilterChanged('Rendered')),
              const SizedBox(width: 8),
              _FilterPill(label: 'Archived', isActive: filter == 'Archived', onTap: () => onFilterChanged('Archived')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SetlistPerformanceCard extends StatelessWidget {
  final Setlist setlist;
  final bool isRendered;
  final VoidCallback onTap;

  const _SetlistPerformanceCard({
    required this.setlist,
    required this.isRendered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isRendered ? const Color(0xFF22C55E) : const Color(0xFFE9A00D);
    final badgeLabel = isRendered ? 'RENDERED' : 'DRAFT';
    final totalDuration = _totalSetlistDuration(setlist);
    final timeLabel = isRendered ? 'TOTAL TIME' : 'EST. TIME';
    final timeColor = isRendered ? const Color(0xFF22C55E) : AppColors.textPrimary;
    final previewSongs = setlist.items.take(3).map((i) => i.originalMusic.title).toList();
    final moreCount = setlist.items.length > 3 ? setlist.items.length - 3 : 0;

    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header: title, subtitle (TO DO - local), badge, options ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          setlist.name,
                          style: AppTextStyles.headingS.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'TO DO - local aqui',
                                style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isRendered
                          ? [
                              BoxShadow(
                                color: badgeColor.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 18),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ---- Two columns: Setlist preview (left) | Divider | Time + button (right) ----
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left column: SETLIST PREVIEW + songs (positioned lower)
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SETLIST PREVIEW',
                              style: AppTextStyles.sectionLabel.copyWith(
                                fontSize: 9,
                                letterSpacing: 1.2,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...previewSongs.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.textMuted.withValues(alpha: 0.2),
                                      border: Border.all(
                                        color: AppColors.textMuted.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${e.key + 1}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            if (moreCount > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '+ $moreCount more songs',
                                style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Vertical separator
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: AppColors.textMuted.withValues(alpha: 0.25),
                    ),
                    // Right column: time (large, upper) + button (bottom)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                timeLabel,
                                style: AppTextStyles.labelMuted.copyWith(
                                  fontSize: 8,
                                  letterSpacing: 1.0,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(totalDuration),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: timeColor,
                                  height: 1.1,
                                  shadows: isRendered
                                      ? [
                                          Shadow(
                                            color: timeColor.withValues(alpha: 0.5),
                                            offset: Offset.zero,
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: isRendered
                                ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                                        blurRadius: 14,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  )
                                : null,
                            child: Material(
                              color: isRendered ? const Color(0xFF22C55E) : AppColors.primary,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                onTap: onTap,
                                borderRadius: BorderRadius.circular(22),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    isRendered ? Icons.play_arrow : Icons.edit,
                                    color: Colors.black87,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPerformanceState extends StatelessWidget {
  final bool hasSetlists;
  final String filter;

  const _EmptyPerformanceState({this.hasSetlists = false, this.filter = 'All'});

  @override
  Widget build(BuildContext context) {
    final isFiltered = hasSetlists && filter != 'All';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'Nenhum setlist neste filtro' : 'Nenhum setlist cadastrado',
            style: AppTextStyles.headingS.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Altere o filtro ou adicione setlists.'
                : 'Crie setlists na aba Setlists e finalize o mastering\npara que apareçam aqui como prontos para o palco.',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
