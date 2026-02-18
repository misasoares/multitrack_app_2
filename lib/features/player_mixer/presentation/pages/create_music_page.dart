import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/track.dart';
import '../stores/create_music_store.dart';

class CreateMusicPage extends StatefulWidget {
  final CreateMusicStore store;

  const CreateMusicPage({super.key, required this.store});

  @override
  State<CreateMusicPage> createState() => _CreateMusicPageState();
}

class _CreateMusicPageState extends State<CreateMusicPage> {
  // Reaction disposer
  ReactionDisposer? _saveReaction;

  // Text Controllers
  late TextEditingController _titleController;
  late TextEditingController _artistController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with store data (for edit mode)
    _titleController = TextEditingController(text: widget.store.title);
    _artistController = TextEditingController(text: widget.store.artist);

    // Listen for save success
    _saveReaction = reaction((_) => widget.store.saveSuccess, (success) {
      if (success) {
        // Verify if mounted to avoid functionality
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Music saved to library!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    widget.store.pausePreview(); // Stop playback when leaving
    _titleController.dispose();
    _artistController.dispose();
    _saveReaction?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rackBlack,
      body: SafeArea(
        child: Column(
          children: [
            // ── Status Bar ──
            _buildStatusBar(),
            // ── Main Content ──
            Expanded(
              child: Row(
                children: [
                  _buildLeftPanel(),
                  Expanded(child: _buildRightPanel()),
                ],
              ),
            ),
            // ── Bottom Bar ──
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STATUS BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStatusBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.rackBlack,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, color: AppColors.primary, size: 8),
              const SizedBox(width: 8),
              Text('AMBER STAGE COMMANDER', style: AppTextStyles.sectionLabel),
            ],
          ),
          Row(
            children: [
              Text('SYS: ONLINE', style: AppTextStyles.trackLabel),
              const SizedBox(width: 16),
              Text(
                TimeOfDay.now().format(context),
                style: AppTextStyles.trackLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LEFT PANEL — Metadata
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildLeftPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.rackDark,
        border: Border(
          right: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.library_music,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'NEW SEQUENCE',
                  style: AppTextStyles.h1.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildImportZone(),
            const SizedBox(height: 24),
            _buildInputField(
              'SONG TITLE',
              _titleController,
              (v) => widget.store.setTitle(v),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              'ARTIST',
              _artistController,
              (v) => widget.store.setArtist(v),
            ),
            const SizedBox(height: 24),
            _buildBpmAndTimeSig(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportZone() {
    return InkWell(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.audio,
        );
        if (result != null) {
          final files = result.files
              .where((f) => f.path != null)
              .map((f) => (name: f.name, path: f.path!))
              .toList();
          if (files.isNotEmpty) {
            widget.store.importTracks(files);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'IMPORT TRACKS',
              style: AppTextStyles.buttonLabel.copyWith(
                fontSize: 12,
                color: AppColors.primary,
                fontFamily: 'JetBrains Mono',
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text('Drag .WAV or .AIFF here', style: AppTextStyles.trackLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.sectionLabel.copyWith(
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.bodyPrimary.copyWith(
            fontFamily: 'JetBrains Mono',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.rackBlack,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBpmAndTimeSig() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.rackBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // BPM Dial
          Column(
            children: [
              Text('TEMPO / BPM', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // TODO: Tap-tempo logic
                },
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceDark, width: 4),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.rackDark, AppColors.rackBlack],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Arc indicator
                      Positioned.fill(
                        child: CustomPaint(painter: _BpmArcPainter()),
                      ),
                      // BPM value
                      Observer(
                        builder: (_) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.store.bpm.isEmpty
                                  ? '---'
                                  : widget.store.bpm,
                              style: AppTextStyles.tempoDisplay.copyWith(
                                color: AppColors.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'TAP',
                              style: AppTextStyles.trackLabel.copyWith(
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Time Sig + Count In
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TIME SIG', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 4),
                _buildDropdown(['4/4', '3/4', '6/8', '5/4']),
                const SizedBox(height: 12),
                Text('COUNT IN', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildSmallButton('1 BAR')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildSmallButton('2 BAR', isActive: true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: '4/4',
          isExpanded: true,
          dropdownColor: AppColors.surfaceDark,
          icon: Icon(
            Icons.expand_more,
            color: AppColors.primary.withValues(alpha: 0.5),
            size: 16,
          ),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: AppTextStyles.trackLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildSmallButton(String label, {bool isActive = false}) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.black : AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // RIGHT PANEL — Track Mixer
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildRightPanel() {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Subtle dot grid background
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),
          Column(
            children: [
              _buildRightHeader(),
              Expanded(child: _buildTrackList()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.rackDark.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text('TRACK MIXER', style: AppTextStyles.sectionLabel),
            ],
          ),
          Observer(
            builder: (_) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.store.tracks.length} TRACKS',
                    style: AppTextStyles.trackLabel.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList() {
    return Observer(
      builder: (_) {
        final content = _buildTrackListContent();

        return Stack(
          children: [
            content,
            if (widget.store.isProcessingAudio)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTrackListContent() {
    if (widget.store.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off,
              color: AppColors.textMuted.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('No tracks imported', style: AppTextStyles.bodyMuted),
            const SizedBox(height: 4),
            Text(
              'Import .WAV or .AIFF files to begin',
              style: AppTextStyles.trackLabel,
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(24),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            child: child,
          ),
          child: child,
        );
      },
      onReorder: widget.store.reorderTracks,
      itemCount: widget.store.tracks.length,
      itemBuilder: (context, index) {
        final track = widget.store.tracks[index];
        return _buildTrackItem(track, index);
      },
    );
  }

  Widget _buildTrackItem(Track track, int index) {
    final bool isSpecial =
        track.isClick ||
        track.name.toLowerCase().contains('click') ||
        track.name.toLowerCase().contains('cue');

    return Container(
      key: ValueKey(track.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.rackDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // ── Drag Handle ──
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_indicator, color: Colors.grey, size: 18),
            ),
          ),

          // ── Track Name + dB ──
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: TextStyle(
                    color: isSpecial
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Observer(
                  builder: (_) => Text(
                    _volumeToDb(track.volume),
                    style: AppTextStyles.trackLabel,
                  ),
                ),
              ],
            ),
          ),

          // ── Waveform ──
          SizedBox(
            width: 300,
            child: Observer(
              builder: (_) {
                final peaks = widget.store.waveformData[track.id];
                return Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomPaint(painter: _WaveformPainter(peaks: peaks)),
                  ),
                );
              },
            ),
          ),

          // ── Pan Slider ──
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'L',
                      style: AppTextStyles.trackLabel.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'C',
                      style: AppTextStyles.trackLabel.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'R',
                      style: AppTextStyles.trackLabel.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Observer(
                  builder: (_) => SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceDark,
                      thumbColor: AppColors.primary,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: track.pan,
                      min: -1.0,
                      max: 1.0,
                      onChanged: (v) => widget.store.updatePan(track.id, v),
                    ),
                  ),
                ),
                Observer(
                  builder: (_) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      _panLabel(track.pan),
                      style: AppTextStyles.trackLabel.copyWith(
                        fontSize: 9,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Volume Slider ──
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.volume_down,
                  color: AppColors.textMuted,
                  size: 12,
                ),
                Expanded(
                  child: Observer(
                    builder: (_) => SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceDark,
                        thumbColor: AppColors.primary,
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        overlayColor: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: track.volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (v) =>
                            widget.store.updateVolume(track.id, v),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── M / S Buttons ──
          Observer(
            builder: (_) => Row(
              children: [
                _buildMuteButton(track),
                const SizedBox(width: 4),
                _buildSoloButton(track),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Delete ──
          InkWell(
            onTap: () => widget.store.removeTrack(track.id),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuteButton(Track track) {
    final isMuted = track.isMuted;
    return InkWell(
      onTap: () => widget.store.toggleMute(track.id),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isMuted ? AppColors.mutedRed : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isMuted
                ? AppColors.alert.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'M',
          style: TextStyle(
            color: isMuted ? AppColors.alert : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }

  Widget _buildSoloButton(Track track) {
    final isSolo = track.isSolo;
    return InkWell(
      onTap: () => widget.store.toggleSolo(track.id),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSolo ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSolo
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          'S',
          style: TextStyle(
            color: isSolo ? AppColors.rackBlack : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOTTOM BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.rackBlack.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Project size
              Observer(
                builder: (_) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROJECT SIZE', style: AppTextStyles.sectionLabel),
                    Text(
                      '${(widget.store.tracks.length * 15.4).toStringAsFixed(1)} MB',
                      style: AppTextStyles.trackLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Save button
              Observer(
                builder: (_) => ElevatedButton.icon(
                  onPressed: widget.store.isLoading
                      ? null
                      : () => widget.store.saveMusicConfig(),
                  icon: widget.store.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.save_alt),
                  label: Text(widget.store.isLoading ? 'SAVING...' : 'SAVE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          // Timeline / Preview Controls
          Positioned(
            left: 200,
            right: 200,
            top: 12,
            bottom: 12,
            child: Observer(
              builder: (_) {
                final hasTracks = widget.store.tracks.isNotEmpty;

                return Row(
                  children: [
                    // Play / Pause Button (Outside Timeline)
                    InkWell(
                      onTap: hasTracks
                          ? () {
                              if (widget.store.isPlaying) {
                                widget.store.pausePreview();
                              } else {
                                widget.store.playPreview();
                              }
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasTracks
                              ? AppColors.primary
                              : AppColors.surfaceDark,
                          shape: BoxShape.circle,
                          boxShadow: hasTracks
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          widget.store.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: hasTracks ? Colors.black : AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Timeline Area
                    Expanded(
                      child: Stack(
                        children: [
                          if (!hasTracks)
                            Center(
                              child: Text(
                                'ADD TRACKS TO ENABLE TIMELINE',
                                style: AppTextStyles.trackLabel.copyWith(
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTapUp: (details) {
                                _seekTo(details.localPosition.dx, context);
                              },
                              onHorizontalDragUpdate: (details) {
                                _seekTo(details.localPosition.dx, context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.rackDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      // Background Grid
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _TimelineGridPainter(),
                                        ),
                                      ),
                                      // Waveform
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _UnifiedWaveformPainter(
                                            waveform:
                                                widget.store.unifiedWaveform,
                                          ),
                                        ),
                                      ),
                                      // Playhead
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _PlayheadPainter(
                                            position:
                                                widget.store.currentPosition,
                                            duration:
                                                widget.store.totalDuration,
                                          ),
                                        ),
                                      ),
                                      // Time Display
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.7,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${_formatDuration(widget.store.currentPosition)} / ${_formatDuration(widget.store.totalDuration)}',
                                            style: AppTextStyles.trackLabel
                                                .copyWith(
                                                  fontFamily: 'JetBrains Mono',
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Loading Overlay
                          if (widget.store.isProcessingAudio)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _seekTo(double dx, BuildContext context) {
    if (context.size == null) return;

    // We need the width of the rendered timeline.
    // Since we are inside a builder, we can try to get the size from the context
    // or assume the width matches the available width minus margins.
    // A safer way is to use LayoutBuilder, but for now let's use the context size of the gesture detector.

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && widget.store.totalDuration > Duration.zero) {
      final width = box.size.width;
      final pct = (dx / width).clamp(0.0, 1.0);
      final ms = (widget.store.totalDuration.inMilliseconds * pct).round();
      widget.store.seekTo(Duration(milliseconds: ms));
    }
  }

  // Helper
  String _formatDuration(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000 ~/ 100).toString();
    return '$mm:$ss.$ms';
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Converts a linear volume (0.0–1.0) to a dB string.
  String _volumeToDb(double volume) {
    if (volume <= 0.0) return '-∞ dB';
    final db = 20 * math.log(volume) / math.ln10;
    return '${db.toStringAsFixed(1)}dB';
  }

  /// Converts a pan value (-1.0 to 1.0) to a readable label.
  String _panLabel(double pan) {
    if (pan.abs() < 0.05) return 'C';
    final pct = (pan.abs() * 100).round();
    return pan < 0 ? 'L$pct' : 'R$pct';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════

/// Draws a half-arc around the BPM dial.
class _BpmArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Waveform painter — renders real peak data when available,
/// falls back to random bars when no data is loaded.
class _WaveformPainter extends CustomPainter {
  final List<double>? peaks;

  _WaveformPainter({this.peaks});

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 2.0;
    const gap = 1.5;
    final center = size.height / 2;

    final peakList = peaks;
    if (peakList != null && peakList.isNotEmpty) {
      // ── Real waveform from PCM peak data ──
      final paintBar = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.7)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      final totalBars = (size.width / (barWidth + gap)).floor().clamp(
        1,
        peakList.length,
      );
      final step = peakList.length / totalBars;

      for (int i = 0; i < totalBars; i++) {
        final peakIdx = (i * step).floor().clamp(0, peakList.length - 1);
        final amplitude = peakList[peakIdx].clamp(0.0, 1.0);
        final h = amplitude * size.height * 0.85;
        final x = i * (barWidth + gap);

        canvas.drawLine(
          Offset(x, center - h / 2),
          Offset(x, center + h / 2),
          paintBar,
        );
      }
    } else {
      // ── Fallback: deterministic random bars ──
      final paintStub = Paint()
        ..color = AppColors.textMuted.withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      final random = math.Random(42);
      for (double x = 0; x < size.width; x += barWidth + gap) {
        final h = random.nextDouble() * (size.height * 0.7);
        canvas.drawLine(
          Offset(x, center - h / 2),
          Offset(x, center + h / 2),
          paintStub,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.peaks != peaks;
}

/// Unified Waveform across the entire timeline
class _UnifiedWaveformPainter extends CustomPainter {
  final List<double> waveform;

  _UnifiedWaveformPainter({required this.waveform});

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final center = size.height / 2;
    final widthPerSample = size.width / waveform.length;

    for (int i = 0; i < waveform.length; i++) {
      final amplitude = waveform[i];
      final height = amplitude * size.height * 0.8;
      final x = i * widthPerSample;

      canvas.drawLine(
        Offset(x, center - height / 2),
        Offset(x, center + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UnifiedWaveformPainter oldDelegate) =>
      oldDelegate.waveform != waveform;
}

/// Playhead (cursor) painter
class _PlayheadPainter extends CustomPainter {
  final Duration position;
  final Duration duration;

  _PlayheadPainter({required this.position, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    final progress = (position.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final x = progress * size.width;

    final paintLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintLine);

    // Draw triangle head
    final path = Path()
      ..moveTo(x - 6, 0)
      ..lineTo(x + 6, 0)
      ..lineTo(x, 8)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PlayheadPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.duration != duration;
}

/// Timeline Grid Background
class _TimelineGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    // Draw vertical bars (every 10% roughly)
    for (double i = 0; i <= 1.0; i += 0.1) {
      final x = size.width * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw center line
    final centerPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws a subtle dot grid background.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
