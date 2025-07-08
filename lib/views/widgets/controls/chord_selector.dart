// lib/views/widgets/controls/chord_selector.dart
import 'package:flutter/material.dart';
import '../../../models/music/chord.dart';
import '../../../constants/ui_constants.dart';

class ChordSelector extends StatefulWidget {
  final String currentChordType;
  final Function(String) onChordSelected;

  const ChordSelector({
    super.key,
    required this.currentChordType,
    required this.onChordSelected,
  });

  @override
  State<ChordSelector> createState() => _ChordSelectorState();
}

class _ChordSelectorState extends State<ChordSelector> {
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();

  void _showChordMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _removeOverlay,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height,
                width: 300,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, size.height),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _ChordMenuContent(
                        currentChordType: widget.currentChordType,
                        onChordSelected: (chordType) {
                          widget.onChordSelected(chordType);
                          _removeOverlay();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chord = Chord.get(widget.currentChordType);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chord Type', style: UIConstants.labelStyle),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showChordMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      chord?.displayName ?? widget.currentChordType,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordMenuContent extends StatelessWidget {
  final String currentChordType;
  final Function(String) onChordSelected;

  const _ChordMenuContent({
    required this.currentChordType,
    required this.onChordSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chordsByCategory = Chord.byCategory;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: chordsByCategory.entries.map((entry) {
          final category = entry.key;
          final chords = entry.value;

          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                category,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              children: chords.map((chord) {
                final isSelected = currentChordType == chord.type;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                  title: Text(
                    chord.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    chord.symbol.isEmpty ? 'Major' : chord.symbol,
                    style: const TextStyle(fontSize: 10),
                  ),
                  onTap: () => onChordSelected(chord.type),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
