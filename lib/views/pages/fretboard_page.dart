// lib/views/pages/fretboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/fretboard/fretboard_config.dart';
import '../../models/app_state.dart';
import '../../models/fretboard/fretboard_instance.dart';
import '../../models/music/chord.dart';
import '../../models/music/note.dart';
import '../../constants/ui_constants.dart';
import '../widgets/common/app_bar.dart';
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

  // Check if should auto-compact for mobile
  bool _shouldAutoCompact(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return ResponsiveConstants.getDeviceType(width) == DeviceType.mobile;
  }

  void _addFretboard() {
    // Get current state from AppState to initialize fretboard
    final appState = context.read<AppState>();

    setState(() {
      var newFretboard = FretboardInstance(
        id: 'fretboard_${_nextId++}',

        // Use CURRENT SESSION STATE for music settings (preserves current workflow)
        root: appState.root, // Current working root
        viewMode: appState.viewMode, // Current working view mode
        scale: appState.scale, // Current working scale
        modeIndex: appState.modeIndex, // Current working mode
        selectedOctaves: Set.from(appState.selectedOctaves), // Current octaves
        selectedIntervals:
            Set.from(appState.selectedIntervals), // Current intervals

        // Use DEFAULT SETTINGS for fretboard physical configuration
        tuning: List.from(appState.defaultTuning), // Use default tuning
        stringCount: appState.defaultStringCount, // Use default string count
        visibleFretEnd: appState.defaultFretCount, // Use default fret count

        // Standard new fretboard settings
        chordType: 'major',
        chordInversion: ChordInversion.root,
        showScaleStrip: true,
        showNoteNames: false,
        isCompact: false,
      );

      // Auto-compact for mobile devices
      if (_shouldAutoCompact(context)) {
        newFretboard = newFretboard.copyWith(isCompact: true);
      }

      _fretboards.add(newFretboard);
    });
  }

  void _removeFretboard(String id) {
    if (_fretboards.length > 1) {
      setState(() {
        _fretboards.removeWhere((f) => f.id == id);
      });
    }
  }

  // Add method to sync root changes back to AppState
  void _syncRootToAppState(String newRoot) {
    final appState = context.read<AppState>();
    if (appState.viewMode == ViewMode.intervals && appState.root != newRoot) {
      appState.setRoot(newRoot);
    }
  }

  void _updateFretboard(String id, FretboardInstance updated) {
    setState(() {
      final index = _fretboards.indexWhere((f) => f.id == id);
      if (index != -1) {
        // Check if root changed in interval mode
        final oldInstance = _fretboards[index];
        final rootChanged = oldInstance.root != updated.root;

        _fretboards[index] = updated;

        // Sync root changes to AppState in interval mode
        if (updated.viewMode == ViewMode.intervals && rootChanged) {
          _syncRootToAppState(updated.root);
        }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);

    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: TheorieAppBar(
            title: 'Multi-Fretboard View',
            actions: [
              // Page-specific actions - these appear BEFORE common actions
              IconButton(
                icon: Icon(
                  _cleanViewMode ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _cleanViewMode
                    ? 'Show Controls'
                    : 'Hide Controls (Clean View)',
                onPressed: _toggleCleanView,
              ),
              if (!_cleanViewMode) 
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Fretboard',
                  onPressed: _addFretboard,
                ),
              // Theme toggle, Settings, and Logout will be added automatically
            ],
          ),
          body: _fretboards.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: EdgeInsets.all(_getListPadding(screenWidth)),
                  itemCount: _fretboards.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: _getSeparatorHeight(screenWidth)),
                  itemBuilder: (context, index) {
                    final fretboard = _fretboards[index];
                    return _FretboardCard(
                      key: ValueKey(fretboard.id),
                      fretboard: fretboard,
                      globalState: state,
                      canRemove: _fretboards.length > 1,
                      cleanViewMode: _cleanViewMode,
                      screenWidth: screenWidth,
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

  // Responsive list padding
  double _getListPadding(double screenWidth) {
    if (_cleanViewMode) {
      return ResponsiveConstants.getCleanViewPadding(screenWidth);
    }

    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return 8.0; // Reduced padding for mobile
      case DeviceType.tablet:
        return 12.0; // Moderate padding for tablet
      case DeviceType.desktop:
        return 16.0; // Full padding for desktop
    }
  }

  // Responsive separator height
  double _getSeparatorHeight(double screenWidth) {
    if (_cleanViewMode) {
      final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
      switch (deviceType) {
        case DeviceType.mobile:
          return 4.0; // Very tight for mobile clean view
        case DeviceType.tablet:
          return 6.0; // Tight for tablet clean view
        case DeviceType.desktop:
          return 8.0; // Normal for desktop clean view
      }
    }

    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return 16.0; // Reduced spacing for mobile
      case DeviceType.tablet:
        return 20.0; // Moderate spacing for tablet
      case DeviceType.desktop:
        return 24.0; // Full spacing for desktop
    }
  }
}

class _FretboardCard extends StatelessWidget {
  final FretboardInstance fretboard;
  final AppState globalState;
  final bool canRemove;
  final bool cleanViewMode;
  final double screenWidth;
  final Function(FretboardInstance) onUpdate;
  final VoidCallback onRemove;

  const _FretboardCard({
    super.key,
    required this.fretboard,
    required this.globalState,
    required this.canRemove,
    required this.cleanViewMode,
    required this.screenWidth,
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

    // Auto-compact for mobile in clean view mode
    final shouldForceCompact = cleanViewMode &&
        ResponsiveConstants.getDeviceType(screenWidth) == DeviceType.mobile;

    final finalFretboard = shouldForceCompact && !adjustedFretboard.isCompact
        ? adjustedFretboard.copyWith(isCompact: true)
        : adjustedFretboard;

    return Card(
      margin: cleanViewMode ? EdgeInsets.zero : null,
      elevation: cleanViewMode ? 0 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!cleanViewMode) _buildHeader(context, config),
          if (!cleanViewMode && !finalFretboard.isCompact)
            FretboardControls(
              instance: finalFretboard,
              onUpdate: onUpdate,
            ),
          Padding(
            padding: EdgeInsets.all(_getCardPadding()),
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
                      onUpdate(finalFretboard.copyWith(
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

  // Responsive card padding
  double _getCardPadding() {
    if (cleanViewMode) {
      return ResponsiveConstants.getCleanViewPadding(screenWidth);
    }

    return ResponsiveConstants.getCardPadding(screenWidth, fretboard.isCompact);
  }

  Widget _buildHeader(BuildContext context, config) {
    String headerText = _getHeaderText(config);

    // Responsive header font size
    final headerFontSize =
        ResponsiveConstants.getScaledFontSize(16.0, screenWidth);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            ResponsiveConstants.getDeviceType(screenWidth) == DeviceType.mobile
                ? 12.0
                : 16.0,
        vertical:
            ResponsiveConstants.getDeviceType(screenWidth) == DeviceType.mobile
                ? 6.0
                : 8.0,
      ),
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
            iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                    DeviceType.mobile
                ? 20.0
                : 24.0,
            onPressed: () {
              onUpdate(fretboard.copyWith(isCompact: !fretboard.isCompact));
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: headerFontSize,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: ResponsiveConstants.getDeviceType(screenWidth) ==
                      DeviceType.mobile
                  ? 2
                  : 1,
            ),
          ),
          IconButton(
            icon: Icon(
              fretboard.showScaleStrip ? Icons.piano : Icons.piano_off,
              color: fretboard.showScaleStrip
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                    DeviceType.mobile
                ? 20.0
                : 24.0,
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
            iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                    DeviceType.mobile
                ? 20.0
                : 24.0,
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
              iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                      DeviceType.mobile
                  ? 20.0
                  : 24.0,
              tooltip: 'Remove Fretboard',
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  String _getHeaderText(config) {
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isCompact = deviceType == DeviceType.mobile;

    if (config.isChordMode) {
      if (isCompact) {
        return '${config.currentChordName} - ${config.tuning.length}str';
      }
      return '${config.currentChordName} - ${config.tuning.length} strings - ${config.layout.displayName}';
    } else if (config.isIntervalMode) {
      if (isCompact) {
        return '${config.effectiveRoot} Intervals - ${config.tuning.length}str';
      }
      return '${config.effectiveRoot} Intervals - ${config.tuning.length} strings - ${config.layout.displayName}';
    } else {
      if (isCompact) {
        return '${config.effectiveRoot} ${config.currentModeName} - ${config.tuning.length}str';
      }
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
      final referenceOctave =
          sortedOctaves.isNotEmpty ? sortedOctaves.first : 3;
      final rootNote = Note.fromString('${fretboard.root}$referenceOctave');

      // Calculate extended interval
      final extendedInterval = tappedMidi - rootNote.midi;

      debugPrint(
          'Tapped note: ${tappedNote.fullName}, interval: $extendedInterval');

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
          final newRootNote =
              Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
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
          final newRootNote =
              Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
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
          final newRootNote =
              Note.fromString('${fretboard.root}$newReferenceOctave');

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

          debugPrint(
              'Added note below root - extended octaves downward, original root now at interval ${octavesDown * 12}');
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
          final newRootNote =
              Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
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
          final newRootNote =
              Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
          newRoot = newRootNote.name;
          newOctaves = {newRootNote.octave};
          newIntervals = {0};

          debugPrint(
              'Single interval from scale strip becomes new root: $newRoot');
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
          final newRootNote =
              Note.fromString('${fretboard.root}$newReferenceOctave');

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
