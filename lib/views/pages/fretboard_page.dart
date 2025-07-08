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
      debugPrint(
          'Tapped ${fretboard.id}: string $stringIndex, fret $fretIndex');
    }
  }

  void _handleScaleNoteTap(int midiNote) {
    // FIX: Handle scale note taps for interval mode
    if (fretboard.viewMode == ViewMode.intervals) {
      debugPrint('Scale note tapped with MIDI: $midiNote');

      // Calculate the extended interval from the tapped note
      final referenceOctave = fretboard.selectedOctaves.isEmpty
          ? 3
          : fretboard.selectedOctaves.reduce((a, b) => a < b ? a : b);
      final rootNote = Note.fromString('${fretboard.root}$referenceOctave');
      final extendedInterval = midiNote - rootNote.midi;

      if (extendedInterval >= 0 && extendedInterval < 48) {
        final newIntervals = Set<int>.from(fretboard.selectedIntervals);
        if (newIntervals.contains(extendedInterval)) {
          if (newIntervals.length > 1 || extendedInterval != 0) {
            newIntervals.remove(extendedInterval);
          }
        } else {
          newIntervals.add(extendedInterval);
        }

        onUpdate(fretboard.copyWith(selectedIntervals: newIntervals));
      }
    }
  }
}
