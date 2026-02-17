import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel: Metadata
          _buildLeftPanel(),

          // Right Panel: Mixer
          Expanded(child: _buildRightPanel()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 320,
      color: AppColors.background,
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
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text('NEW SEQUENCE', style: AppTextStyles.h1),
              ],
            ),
            const SizedBox(height: 24),

            // Import Tracks
            _buildImportZone(),
            const SizedBox(height: 24),

            // Metadata Fields
            _buildInputField('SONG TITLE', (v) => widget.store.setTitle(v)),
            const SizedBox(height: 16),
            _buildInputField('ARTIST', (v) => widget.store.setArtist(v)),
            const SizedBox(height: 24),

            // BPM & Time Sig Cluster
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
          for (var file in result.files) {
            if (file.path != null) {
              widget.store.addTrack(file.name, file.path!);
            }
          }
        }
      },
      child: Container(
        height: 160,
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
            const Icon(Icons.add, color: AppColors.primary, size: 40),
            Text('IMPORT TRACKS', style: AppTextStyles.buttonLabel),
            Text('Select .WAV or .AIFF files', style: AppTextStyles.bodyMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            letterSpacing: 2,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          style: AppTextStyles.bodyPrimary.copyWith(
            fontFamily: 'JetBrains Mono',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // BPM Circle (simplified from design)
          Column(
            children: [
              const Text(
                'BPM',
                style: TextStyle(color: AppColors.textMuted, fontSize: 8),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                alignment: Alignment.center,
                child: Observer(
                  builder: (_) => Text(
                    widget.store.bpm.isEmpty ? '---' : widget.store.bpm,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Time Sig & Count In
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIME SIG',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 8),
                ),
                _buildDropdown(['4/4', '3/4', '6/8', '5/4']),
                const SizedBox(height: 12),
                const Text(
                  'COUNT IN',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 8),
                ),
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
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: '4/4',
          isExpanded: true,
          dropdownColor: AppColors.surface,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
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
        color: isActive ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.black : AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildRightHeader(),
          Expanded(
            child: Observer(
              builder: (_) => ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: widget.store.tracks.length,
                itemBuilder: (context, index) {
                  final track = widget.store.tracks[index];
                  return _buildTrackItem(track);
                },
              ),
            ),
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
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'TRACK MIXER',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Observer(
            builder: (_) => Text(
              '${widget.store.tracks.length} TRACKS',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Track track) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  '0.0dB',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.show_chart,
                color: AppColors.textMuted,
                size: 16,
              ), // Mock waveform
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 120,
            child: Row(
              children: [
                const Icon(
                  Icons.volume_down,
                  color: AppColors.textMuted,
                  size: 12,
                ),
                Expanded(child: Slider(value: 0.8, onChanged: (_) {})),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              _buildControlToggle('M'),
              const SizedBox(width: 4),
              _buildControlToggle('S', isActive: true),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
            onPressed: () => widget.store.removeTrack(track.id),
          ),
        ],
      ),
    );
  }

  Widget _buildControlToggle(String label, {bool isActive = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.black : AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROJECT SIZE',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 8),
                  ),
                  Text(
                    '${(widget.store.tracks.length * 15.4).toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => widget.store.saveMusic(),
                icon: const Icon(Icons.save_alt),
                label: const Text('SAVE TO LIBRARY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          // Preview button centered
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow),
            label: const Text('PREVIEW'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceHighlight,
              foregroundColor: Colors.white,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
