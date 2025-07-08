// lib/views/pages/fretboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/fretboard/fretboard_config.dart';
import '../../models/app_state.dart';
import '../../models/fretboard/fretboard_instance.dart';
import '../../models/music/chord.dart';
import '../../models/music/note.dart';
import '../widgets/fretboard/fretboard_widget.dart';
import '../widgets/controls/fretboard_controls.dart';
import '../dialogs/settings_dialog.dart';

class FretboardPage extends StatefulWidget {
  const FretboardPage({super.key});

  @override
  State<FretboardPage> createState() => _FretboardPageState();
}

class _FretboardPageState extends State<FretboardPage> {
  List<FretboardInstance> _fretboards = [];
  int _nextId = 1;
  bool _cleanViewMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addFretboard();
    });
  }

  void _addFretboard() {
    // FIX: Get current state from AppState to initialize fretboard
    final appState = context.read<AppState>();

    setState(() {
      _fretboards.add(FretboardInstance(
        id: 'fretboard_${_nextId++}',
        root: appState.root, // Use current root from AppState
        viewMode: appState.viewMode, // Use current view mode from AppState
        scale: appState.scale, // Use current scale from AppState
        modeIndex: appState.modeIndex,
        chordType: 'major',
        chordInversion: ChordInversion.root,
        selectedOctaves: Set.from(appState.selectedOctaves), // Copy octaves
        selectedIntervals:
            Set.from(appState.selectedIntervals), // Copy intervals
        tuning: List.from(appState.tuning), // Copy tuning
        stringCount: appState.stringCount,
        visibleFretEnd: appState.fretCount,
        showScaleStrip: true,
        showNoteNames: false,
        isCompact: false,
      ));
    });
  }

  void _removeFretboard(String id) {
    if (_fretboards.length > 1) {
      setState(() {
        _fretboards.removeWhere((f) => f.id == id);
      });
    }
  }

  void _updateFretboard(String id, FretboardInstance updated) {
    setState(() {
      final index = _fretboards.indexWhere((f) => f.id == id);
      if (index != -1) {
        _fretboards[index] = updated;
      }
    });
  }

  void _toggleCleanView() {
    setState(() {
      _cleanViewMode = !_cleanViewMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Multi-Fretboard View'),
            actions: [
              IconButton(
                icon: Icon(
                    _cleanViewMode ? Icons.visibility_off : Icons.visibility),
                tooltip: _cleanViewMode
                    ? 'Show Controls'
                    : 'Hide Controls (Clean View)',
                onPressed: _toggleCleanView,
              ),
              if (!_cleanViewMode) ...[
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Fretboard',
                  onPressed: _addFretboard,
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => showSettingsDialog(context),
                ),
              ],
            ],
          ),
          body: _fretboards.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: EdgeInsets.all(_cleanViewMode ? 8 : 16),
                  itemCount: _fretboards.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: _cleanViewMode ? 8 : 24),
                  itemBuilder: (context, index) {
                    final fretboard = _fretboards[index];
                    return _FretboardCard(
                      key: ValueKey(fretboard.id),
                      fretboard: fretboard,
                      globalState: state,
                      canRemove: _fretboards.length > 1,
                      cleanViewMode: _cleanViewMode,
                      onUpdate: (updated) =>
                          _updateFretboard(fretboard.id, updated),
                      onRemove: () => _removeFretboard(fretboard.id),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _FretboardCard extends StatelessWidget {
  final FretboardInstance fretboard;
  final AppState globalState;
  final bool canRemove;
  final bool cleanViewMode;
  final Function(FretboardInstance) onUpdate;
  final VoidCallback onRemove;

  const _FretboardCard({
    super.key,
    required this.fretboard,
    required this.globalState,
    required this.canRemove,
    required this.cleanViewMode,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final config = fretboard.toConfig(
      layout: globalState.layout,
      globalFretCount: globalState.fretCount,
    );

    final adjustedFretboard = fretboard.visibleFretEnd > globalState.fretCount
        ? fretboard.copyWith(visibleFretEnd: globalState.fretCount)
        : fretboard;

    return Card(
      margin: cleanViewMode ? EdgeInsets.zero : null,
      elevation: cleanViewMode ? 0 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!cleanViewMode) _buildHeader(context, config),
          if (!cleanViewMode && !adjustedFretboard.isCompact)
            FretboardControls(
              instance: adjustedFretboard,
              onUpdate: onUpdate,
            ),
          Padding(
            padding: EdgeInsets.all(
                cleanViewMode ? 4 : (adjustedFretboard.isCompact ? 8 : 16)),
            child: FretboardWidget(
              config: config.copyWith(
                showChordName: cleanViewMode && config.isChordMode,
              ),
              onFretTap: (stringIndex, fretIndex) {
                _handleFretTap(stringIndex, fretIndex);
              },
              onScaleNoteTap: (midiNote) {
                _handleScaleNoteTap(midiNote);
              },
              onRangeChanged: cleanViewMode
                  ? null
                  : (newStart, newEnd) {
                      onUpdate(adjustedFretboard.copyWith(
                        visibleFretStart: newStart,
                        visibleFretEnd: newEnd,
                      ));
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, config) {
    String headerText = _getHeaderText(config);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
                fretboard.isCompact ? Icons.expand_more : Icons.expand_less),
            tooltip: fretboard.isCompact ? 'Show Controls' : 'Hide Controls',
            onPressed: () {
              onUpdate(fretboard.copyWith(isCompact: !fretboard.isCompact));
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              headerText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: Icon(
              fretboard.showScaleStrip ? Icons.piano : Icons.piano_off,
              color: fretboard.showScaleStrip
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            tooltip: 'Toggle Scale Strip',
            onPressed: () {
              onUpdate(fretboard.copyWith(
                  showScaleStrip: !fretboard.showScaleStrip));
            },
          ),
          IconButton(
            icon: Icon(
              fretboard.showNoteNames ? Icons.abc : Icons.numbers,
              color: fretboard.showNoteNames
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            tooltip:
                fretboard.showNoteNames ? 'Show Intervals' : 'Show Note Names',
            onPressed: () {
              onUpdate(
                  fretboard.copyWith(showNoteNames: !fretboard.showNoteNames));
            },
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove Fretboard',
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  String _getHeaderText(config) {
    if (config.isChordMode) {
      return '${config.currentChordName} - ${config.tuning.length} strings - ${config.layout.displayName}';
    } else if (config.isIntervalMode) {
      return '${config.effectiveRoot} Intervals - ${config.tuning.length} strings - ${config.layout.displayName}';
    } else {
      return '${config.effectiveRoot} ${config.currentModeName} - ${config.tuning.length} strings - ${config.layout.displayName}';
    }
  }

  void _handleFretTap(int stringIndex, int fretIndex) {
    // Handle fret taps for interval mode
    if (fretboard.viewMode == ViewMode.intervals) {
      debugPrint('Fretboard tap: string $stringIndex, fret $fretIndex');
      
      // Calculate the tapped note
      final openStringNote = Note.fromString(fretboard.tuning[stringIndex]);
      final tappedNote = openStringNote.transpose(fretIndex);
      final tappedMidi = tappedNote.midi;
      
      // Get reference octave from selected octaves
      final sortedOctaves = fretboard.selectedOctaves.toList()..sort();
      final referenceOctave = sortedOctaves.isNotEmpty ? sortedOctaves.first : 3;
      final rootNote = Note.fromString('${fretboard.root}$referenceOctave');
      
      // Calculate extended interval
      final extendedInterval = tappedMidi - rootNote.midi;
      
      debugPrint('Tapped note: ${tappedNote.fullName}, interval: $extendedInterval');
      
      var newIntervals = Set<int>.from(fretboard.selectedIntervals);
      var newOctaves = Set<int>.from(fretboard.selectedOctaves);
      var newRoot = fretboard.root;
      
      // Handle based on current state
      if (newIntervals.isEmpty) {
        // No notes selected - this becomes the new root
        newRoot = tappedNote.name;
        newIntervals = {0}; // Just the root
        newOctaves = {tappedNote.octave}; // Reset octaves to just this one
        
        debugPrint('Setting new root: $newRoot');
      } else if (newIntervals.contains(extendedInterval)) {
        // Removing an existing interval
        newIntervals.remove(extendedInterval);
        
        if (newIntervals.isEmpty) {
          // Just removed the last note - empty state
          debugPrint('All intervals removed - empty state');
        } else if (extendedInterval == 0) {
          // Removed the root - find new root
          final lowestInterval = newIntervals.reduce((a, b) => a < b ? a : b);
          final newRootMidi = rootNote.midi + lowestInterval;
          final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
          newRoot = newRootNote.name;
          
          // Reset octaves for new root
          newOctaves = {newRootNote.octave};
          
          // Adjust all intervals relative to new root
          final adjustedIntervals = <int>{};
          for (final interval in newIntervals) {
            final adjustedInterval = interval - lowestInterval;
            adjustedIntervals.add(adjustedInterval);
            
            // Collect octaves for all intervals
            final noteMidi = newRootMidi + adjustedInterval;
            final noteOctave = Note.fromMidi(noteMidi).octave;
            newOctaves.add(noteOctave);
          }
          newIntervals = adjustedIntervals;
          
          debugPrint('Root removed - new root: $newRoot');
        } else if (newIntervals.length == 1 && !newIntervals.contains(0)) {
          // SINGLE INTERVAL BECOMES ROOT LOGIC
          final singleInterval = newIntervals.first;
          final newRootMidi = rootNote.midi + singleInterval;
          final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
          newRoot = newRootNote.name;
          newOctaves = {newRootNote.octave};
          newIntervals = {0};
          
          debugPrint('Single interval becomes new root: $newRoot');
        }
      } else {
        // Adding a new interval
        if (extendedInterval < 0) {
          // Note is below current root - extend octaves downward
          final octavesDown = ((-extendedInterval - 1) ~/ 12) + 1;
          final newReferenceOctave = referenceOctave - octavesDown;
          
          // Add the lower octaves
          for (int i = 0; i < octavesDown; i++) {
            newOctaves.add(referenceOctave - i - 1);
          }
          
          // Recalculate ALL intervals from the new lower reference
          final newRootNote = Note.fromString('${fretboard.root}$newReferenceOctave');
          
          // Convert existing intervals to new reference
          final adjustedIntervals = <int>{};
          for (final interval in newIntervals) {
            // Shift existing intervals up by the octave difference
            adjustedIntervals.add(interval + (octavesDown * 12));
          }
          
          // Add the new interval
          final adjustedNewInterval = tappedMidi - newRootNote.midi;
          adjustedIntervals.add(adjustedNewInterval);
          
          newIntervals = adjustedIntervals;
          
          debugPrint('Added note below root - extended octaves downward, original root now at interval ${octavesDown * 12}');
        } else {
          // Normal case - just add the interval
          newIntervals.add(extendedInterval);
          
          // Add octave if needed
          if (!newOctaves.contains(tappedNote.octave)) {
            newOctaves.add(tappedNote.octave);
          }
          
          debugPrint('Added interval: $extendedInterval');
        }
      }
      
      // Update the fretboard instance
      onUpdate(fretboard.copyWith(
        root: newRoot,
        selectedIntervals: newIntervals,
        selectedOctaves: newOctaves,
      ));
    }
  }

  void _handleScaleNoteTap(int midiNote) {
    if (fretboard.viewMode == ViewMode.intervals) {
      debugPrint('Scale note tapped with MIDI: $midiNote');

      // Get clicked note details
      final clickedNote = Note.fromMidi(midiNote);
      
      // Calculate the extended interval from the tapped note
      final referenceOctave = fretboard.selectedOctaves.isEmpty
          ? 3
          : fretboard.selectedOctaves.reduce((a, b) => a < b ? a : b);
      final rootNote = Note.fromString('${fretboard.root}$referenceOctave');
      final extendedInterval = midiNote - rootNote.midi;

      var newIntervals = Set<int>.from(fretboard.selectedIntervals);
      var newOctaves = Set<int>.from(fretboard.selectedOctaves);
      var newRoot = fretboard.root;
      
      // Handle based on current state
      if (newIntervals.isEmpty) {
        // No notes selected - this becomes the new root
        newRoot = clickedNote.name;
        newIntervals = {0};
        newOctaves = {clickedNote.octave};
        
        debugPrint('Setting new root from scale strip: $newRoot');
      } else if (newIntervals.contains(extendedInterval)) {
        // Removing an interval
        newIntervals.remove(extendedInterval);
        
        if (newIntervals.isEmpty) {
          // Empty state
          debugPrint('All intervals removed from scale strip');
        } else if (extendedInterval == 0) {
          // Root removal - find new root
          final lowestInterval = newIntervals.reduce((a, b) => a < b ? a : b);
          final newRootMidi = rootNote.midi + lowestInterval;
          final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
          newRoot = newRootNote.name;
          
          // Reset octaves
          newOctaves = {newRootNote.octave};
          
          // Adjust intervals and collect octaves
          final adjustedIntervals = <int>{};
          for (final interval in newIntervals) {
            final adjustedInterval = interval - lowestInterval;
            adjustedIntervals.add(adjustedInterval);
            
            final noteMidi = newRootMidi + adjustedInterval;
            final noteOctave = Note.fromMidi(noteMidi).octave;
            newOctaves.add(noteOctave);
          }
          newIntervals = adjustedIntervals;
        } else if (newIntervals.length == 1 && !newIntervals.contains(0)) {
          // SINGLE INTERVAL BECOMES ROOT LOGIC  
          final singleInterval = newIntervals.first;
          final newRootMidi = rootNote.midi + singleInterval;
          final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
          newRoot = newRootNote.name;
          newOctaves = {newRootNote.octave};
          newIntervals = {0};
          
          debugPrint('Single interval from scale strip becomes new root: $newRoot');
        }
      } else {
        // Adding new interval
        if (extendedInterval < 0) {
          // Below root - extend octaves
          final octavesDown = ((-extendedInterval - 1) ~/ 12) + 1;
          final newReferenceOctave = referenceOctave - octavesDown;
          
          for (int i = 0; i < octavesDown; i++) {
            newOctaves.add(referenceOctave - i - 1);
          }
          
          // Recalculate all intervals
          final newRootNote = Note.fromString('${fretboard.root}$newReferenceOctave');
          
          // Adjust existing intervals
          final adjustedIntervals = <int>{};
          for (final interval in newIntervals) {
            adjustedIntervals.add(interval + (octavesDown * 12));
          }
          
          // Add new interval
          final adjustedNewInterval = midiNote - newRootNote.midi;
          adjustedIntervals.add(adjustedNewInterval);
          
          newIntervals = adjustedIntervals;
        } else {
          // Normal addition
          newIntervals.add(extendedInterval);
          
          if (!newOctaves.contains(clickedNote.octave)) {
            newOctaves.add(clickedNote.octave);
          }
        }
      }

      // Update the fretboard instance
      onUpdate(fretboard.copyWith(
        root: newRoot,
        selectedIntervals: newIntervals,
        selectedOctaves: newOctaves,
      ));
    }
  }
}