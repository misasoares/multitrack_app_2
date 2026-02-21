import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/setlist_item.dart';

class TransposeConfigDialog extends StatefulWidget {
  final SetlistItem item;
  final ValueChanged<int> onConfirm;
  final void Function(List<String>)? onTracksChanged;

  const TransposeConfigDialog({
    super.key,
    required this.item,
    required this.onConfirm,
    this.onTracksChanged,
  });

  @override
  State<TransposeConfigDialog> createState() => _TransposeConfigDialogState();
}

class _TransposeConfigDialogState extends State<TransposeConfigDialog> {
  late int _semitones;
  late Set<String> _selectedTrackIds;

  @override
  void initState() {
    super.initState();
    _semitones = widget.item.transposeSemitones;

    // Initialize selected tracks:
    // If the item has a specific list, use it.
    // If empty (default), assume ALL tracks should be selected initially.
    if (widget.item.transposableTrackIds.isEmpty) {
      _selectedTrackIds = widget.item.originalMusic.tracks
          .map((t) => t.id)
          .toSet();
    } else {
      _selectedTrackIds = widget.item.transposableTrackIds.toSet();
    }
  }

  void _handleConfirm() {
    widget.onConfirm(_semitones);
    widget.onTracksChanged?.call(_selectedTrackIds.toList());
    Navigator.of(context).pop();
  }

  void _onTrackToggle(String trackId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedTrackIds.add(trackId);
      } else {
        _selectedTrackIds.remove(trackId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRANSPOSE CONFIG',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Key Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButton(
                    icon: Icons.remove,
                    onTap: () => setState(() => _semitones--),
                  ),
                  Container(
                    width: 120,
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          _semitones > 0 ? '+${_semitones}' : '$_semitones',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'SEMITONES',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withValues(alpha: 0.1),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildButton(
                    icon: Icons.add,
                    onTap: () => setState(() => _semitones++),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Track Selection Header
              Text(
                'APPLY TO TRACKS:',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Track List
              Container(
                height: 200, // Limit height for list
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.item.originalMusic.tracks.length,
                  itemBuilder: (context, index) {
                    final track = widget.item.originalMusic.tracks[index];
                    final isSelected = _selectedTrackIds.contains(track.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) => _onTrackToggle(track.id, val),
                      title: Text(
                        track.name,
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      activeColor: AppColors.primary,
                      checkColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      dense: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'CONFIRM',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
