// lib/views/widgets/controls/keyboard_controls.dart
import 'package:flutter/material.dart';
import '../../../models/keyboard/keyboard_instance.dart';
import '../../../constants/keyboard_constants.dart';
import '../../../models/fretboard/fretboard_config.dart'; // For ViewMode
import '../../../models/music/scale.dart';
import '../../../models/music/chord.dart';
import 'chord_selector.dart';
import 'octave_selector.dart';

/// Controls widget for keyboard configuration
/// Following the same pattern as FretboardControls
class KeyboardControls extends StatelessWidget {
  final KeyboardInstance instance;
  final Function(KeyboardInstance) onUpdate;

  const KeyboardControls({
    super.key,
    required this.instance,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keyboard Controls',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Keyboard configuration
            _buildKeyboardSection(context),
            const SizedBox(height: 16),
            
            // Music theory controls
            _buildMusicTheorySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keyboard Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: ${instance.keyboardType}'),
                  Text('Keys: ${instance.keyCount}'),
                  Text('Start: ${instance.startNote}'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showKeyboardConfigDialog(context),
              child: const Text('Configure'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMusicTheorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Music Theory',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        
        // Root and View Mode
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Root:'),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: _buildRootSelector(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('View Mode:'),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: _buildViewModeSelector(),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Conditional controls based on mode
        if (instance.viewMode == ViewMode.scales) ...[
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Scale:'),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: _buildScaleSelector(),
              ),
            ],
          ),
        ],
        
        if (instance.viewMode.isChordMode) ...[
          const SizedBox(height: 16),
          // Chord type and inversion row
          Row(
            children: [
              // Chord type selector
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chord:'),
                    const SizedBox(height: 4),
                    ChordSelector(
                      currentChordType: instance.chordType,
                      onChordSelected: (chordType) {
                        onUpdate(instance.copyWith(
                          chordType: chordType,
                          chordInversion: ChordInversion.root, // Reset to root when chord changes
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Chord inversion selector
              if (instance.viewMode == ViewMode.chordInversions)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inversion:'),
                      const SizedBox(height: 4),
                      _buildChordInversionSelector(),
                    ],
                  ),
                )
              else
                const Expanded(flex: 2, child: SizedBox()), // Placeholder for other chord modes
            ],
          ),
        ],
        
        // Octave selector
        const SizedBox(height: 16),
        OctaveSelector(
          selectedOctaves: instance.selectedOctaves,
          isChordMode: instance.viewMode.isChordMode,
          onChanged: (octaves) {
            onUpdate(instance.copyWith(selectedOctaves: octaves));
          },
        ),
      ],
    );
  }

  Widget _buildRootSelector() {
    return DropdownButtonFormField<String>(
      value: instance.root,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true, // Prevent overflow
      items: ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
          .map((String root) {
        return DropdownMenuItem<String>(
          value: root,
          child: Text(
            root,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (String? newRoot) {
        if (newRoot != null) {
          onUpdate(instance.copyWith(root: newRoot));
        }
      },
    );
  }

  Widget _buildViewModeSelector() {
    return DropdownButtonFormField<ViewMode>(
      value: instance.viewMode,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true, // Prevent overflow
      items: ViewMode.values.map((ViewMode mode) {
        return DropdownMenuItem<ViewMode>(
          value: mode,
          child: Text(
            mode.displayName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (ViewMode? newMode) {
        if (newMode != null) {
          onUpdate(instance.copyWith(viewMode: newMode));
        }
      },
    );
  }

  Widget _buildScaleSelector() {
    // Use the same scale list as the main ScaleSelector widget
    final scales = Scale.all.keys.toList();
    return DropdownButtonFormField<String>(
      value: instance.scale,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true, // Prevent overflow
      items: scales.map((String scale) {
        return DropdownMenuItem<String>(
          value: scale,
          child: Text(
            scale,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (String? newScale) {
        if (newScale != null) {
          onUpdate(instance.copyWith(scale: newScale));
        }
      },
    );
  }

  Widget _buildChordInversionSelector() {
    // Get available inversions for the current chord type (same logic as fretboard)
    final chord = Chord.get(instance.chordType);
    final availableInversions = chord?.availableInversions ?? [ChordInversion.root];
    
    return DropdownButtonFormField<ChordInversion>(
      value: availableInversions.contains(instance.chordInversion) 
          ? instance.chordInversion 
          : availableInversions.first,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: availableInversions.map((ChordInversion inversion) {
        return DropdownMenuItem<ChordInversion>(
          value: inversion,
          child: Text(
            inversion.displayName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (ChordInversion? newInversion) {
        if (newInversion != null) {
          onUpdate(instance.copyWith(chordInversion: newInversion));
        }
      },
    );
  }


  void _showKeyboardConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newKeyboardType = instance.keyboardType;
        String newStartNote = instance.startNote;
        
        return AlertDialog(
          title: const Text('Keyboard Configuration'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: newKeyboardType,
                    decoration: const InputDecoration(labelText: 'Keyboard Type'),
                    isExpanded: true, // Prevent overflow
                    items: KeyboardConstants.keyboardTypes.keys.map((String type) {
                      final keyCount = KeyboardConstants.keyboardTypes[type]!;
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          '$type ($keyCount keys)',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          newKeyboardType = value;
                          newStartNote = KeyboardConstants.getDefaultStartNote(value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: newStartNote,
                    decoration: const InputDecoration(labelText: 'Start Note'),
                    isExpanded: true, // Prevent overflow
                    items: KeyboardConstants.commonStartNotes.map((String note) {
                      return DropdownMenuItem<String>(
                        value: note,
                        child: Text(
                          note,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          newStartNote = value;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newKeyCount = KeyboardConstants.keyboardTypes[newKeyboardType]!;
                onUpdate(instance.copyWith(
                  keyboardType: newKeyboardType,
                  keyCount: newKeyCount,
                  startNote: newStartNote,
                ));
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}