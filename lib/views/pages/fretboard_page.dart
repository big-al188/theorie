// lib/views/pages/fretboard_page.dart - Enhanced for audio integration
import 'package:Theorie/controllers/fretboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../models/fretboard/fretboard_config.dart';
import '../../models/app_state.dart';
import '../../models/fretboard/fretboard_instance.dart';
import '../../models/music/chord.dart';
import '../../models/music/note.dart';
import '../../constants/ui_constants.dart';
import '../widgets/common/app_bar.dart';
import '../widgets/fretboard/fretboard_widget.dart';
import '../widgets/fretboard/audio_controls.dart'; // NEW: Import for potential use
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
        showAdditionalOctaves:
            false, // NEW: Default to false for new fretboards
        showOctave: false, // NEW: Default to false for new fretboards
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
    // Auto-compact for mobile in clean view mode
    final shouldForceCompact = cleanViewMode &&
        ResponsiveConstants.getDeviceType(screenWidth) == DeviceType.mobile;

    final finalFretboard = shouldForceCompact && !fretboard.isCompact
        ? fretboard.copyWith(isCompact: true)
        : fretboard;

    // Adjust fret end if needed
    final adjustedFretboard =
        finalFretboard.visibleFretEnd > globalState.fretCount
            ? finalFretboard.copyWith(visibleFretEnd: globalState.fretCount)
            : finalFretboard;

    // Check if this mode is not yet implemented
    if (!adjustedFretboard.viewMode.isImplemented) {
      return _buildUnimplementedCard(context, adjustedFretboard);
    }

    return Card(
      margin: cleanViewMode ? EdgeInsets.zero : null,
      elevation: cleanViewMode ? 0 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!cleanViewMode) _buildHeader(context, adjustedFretboard),
          if (!cleanViewMode && !adjustedFretboard.isCompact)
            FretboardControls(
              instance: adjustedFretboard,
              onUpdate: onUpdate,
              globalFretCount: globalState.fretCount,
            ),
          // ENHANCED: Proper FretboardWidget layout with audio integration
          _buildFretboardSection(context, adjustedFretboard),
        ],
      ),
    );
  }

// ENHANCED: Proper fretboard section with smart octave detection
  Widget _buildFretboardSection(
      BuildContext context, FretboardInstance instance) {
    final config = instance.toConfig(
      layout: globalState.layout,
      globalFretCount: globalState.fretCount,
    );

    // Calculate responsive dimensions
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final availableWidth = screenWidth - _getHorizontalPadding(deviceType);

    // Calculate heights using responsive constants
    final stringHeight = ResponsiveConstants.getStringHeight(screenWidth);
    final fretboardHeight = (instance.stringCount + 1) * stringHeight;

    // Account for audio controls height for ALL modes
    final audioControlsHeight = (globalState.audioEnabled && !cleanViewMode)
        ? _getAudioControlsHeight(deviceType)
        : 0.0;

    // SMART OCTAVE DETECTION: For chord modes, calculate octaves based on scale strip octaves
    int actualOctaveCount;

    if (instance.showScaleStrip && config.isAnyChordMode) {
      // Get the highlight map to see which notes are actually highlighted
      final highlightMap = FretboardController.getHighlightMap(config);

      if (highlightMap.isNotEmpty) {
        // Calculate which scale strip octaves contain highlighted notes
        // Scale strip octaves are relative to the root, not absolute MIDI octaves
        final scaleStripOctaves = <int>{};

        // Get the user's selected octave as the base for the scale strip
        final baseOctave =
            config.selectedOctaves.isEmpty ? 3 : config.selectedOctaves.first;
        final rootNote = Note.fromString('${config.root}$baseOctave');
        final baseMidi = rootNote.midi;

        for (final midiNote in highlightMap.keys) {
          // Calculate which scale strip octave this note falls into
          // Each scale strip covers 12 semitones starting from the root
          final intervalFromBase = midiNote - baseMidi;
          final scaleStripOctave = baseOctave + (intervalFromBase ~/ 12);

          // SPECIAL CASE: Don't create new scale strips for pure octave notes
          // If this note is exactly 12, 24, 36... semitones from root (pure octave)
          // and it's the only note in that scale strip octave, don't add it
          final isOctaveNote =
              intervalFromBase > 0 && intervalFromBase % 12 == 0;

          if (!isOctaveNote || scaleStripOctave == baseOctave) {
            // Either it's not an octave note, or it's in the base octave
            scaleStripOctaves.add(scaleStripOctave);
          } else {
            // It's an octave note in a higher octave
            // Check if there are other non-octave notes in this same scale strip octave
            final hasOtherNotesInOctave = highlightMap.keys.any((otherMidi) {
              final otherInterval = otherMidi - baseMidi;
              final otherScaleStripOctave = baseOctave + (otherInterval ~/ 12);
              final isOtherOctaveNote =
                  otherInterval > 0 && otherInterval % 12 == 0;
              return otherScaleStripOctave == scaleStripOctave &&
                  !isOtherOctaveNote;
            });

            if (hasOtherNotesInOctave) {
              // There are other notes in this octave, so include it
              scaleStripOctaves.add(scaleStripOctave);
            }
            // Otherwise, don't add this scale strip octave (pure octave note only)
          }
        }

        if (scaleStripOctaves.isNotEmpty) {
          actualOctaveCount = scaleStripOctaves.length;
          debugPrint(
              'Fretboard section: chord mode using ${scaleStripOctaves.length} scale strip octaves relative to ${config.root}$baseOctave: $scaleStripOctaves (octave-only strips filtered out)');
        } else {
          // Fallback to user selection if no highlights found
          actualOctaveCount = instance.selectedOctaves.isEmpty
              ? 1
              : instance.selectedOctaves.length;
          debugPrint(
              'Fretboard section: chord mode fallback to ${actualOctaveCount} user octaves');
        }
      } else {
        // No highlights - use user selection
        actualOctaveCount = instance.selectedOctaves.isEmpty
            ? 1
            : instance.selectedOctaves.length;
        debugPrint(
            'Fretboard section: chord mode no highlights, using ${actualOctaveCount} user octaves');
      }
    } else {
      // For non-chord modes or when scale strip is hidden, use user selection
      actualOctaveCount = instance.selectedOctaves.isEmpty
          ? 1
          : instance.selectedOctaves.length;
      debugPrint(
          'Fretboard section: non-chord mode using ${actualOctaveCount} user octaves');
    }

    // Calculate scale strip height with smart octave count
    final scaleStripHeight = instance.showScaleStrip
        ? _calculateScaleStripHeight(actualOctaveCount)
        : 0.0;

    // Add spacing between fretboard and scale strip only when both are shown
    final spacingHeight = (instance.showScaleStrip && config.showFretboard)
        ? ResponsiveConstants.getFretboardScaleStripSpacing(screenWidth)
        : 0.0;

    // Chord name height - account for cleanViewMode logic that will be applied
    final willShowChordName = (cleanViewMode && config.isAnyChordMode);
    final chordNameHeight = willShowChordName ? 30.0 : 0.0;

    // Height calculation that prevents overflow
    final baseHeight =
        fretboardHeight + scaleStripHeight + spacingHeight + chordNameHeight;
    final minContainerHeight = fretboardHeight +
        chordNameHeight +
        (config.isAnyChordMode ? 60.0 : 40.0); // Extra space for chord modes

    final totalHeight = instance.showScaleStrip
        ? baseHeight
        : math.max(baseHeight, minContainerHeight);

    return Container(
      padding: EdgeInsets.all(_getCardPadding()),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          // Audio controls integration for ALL modes
          if (globalState.audioEnabled && !cleanViewMode) ...[
            AudioControls(config: config),
            SizedBox(
                height:
                    ResponsiveConstants.getAudioControlsSpacing(screenWidth)),
          ],

          // Main fretboard widget with correct height calculation
          SizedBox(
            width: availableWidth,
            height: totalHeight,
            child: FretboardWidget(
              config: config.copyWith(
                width: availableWidth,
                height: totalHeight,
                showChordName: cleanViewMode && config.isAnyChordMode,
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
                      onUpdate(instance.copyWith(
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

  // NEW: Calculate audio controls height
  double _getAudioControlsHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 60.0; // Compact audio controls
      case DeviceType.tablet:
        return 70.0; // Medium audio controls
      case DeviceType.desktop:
        return 80.0; // Full-size audio controls
    }
  }

  // RESTORED: Proper responsive calculations
  double _calculateScaleStripHeight(int octaveCount) {
    final noteRowHeight = ResponsiveConstants.getNoteRowHeight(screenWidth);
    final paddingPerOctave =
        ResponsiveConstants.getScaleStripPaddingPerOctave(screenWidth);

    return UIConstants.scaleStripLabelSpace +
        (octaveCount * noteRowHeight) +
        (octaveCount * paddingPerOctave);
  }

  double _getHorizontalPadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 32.0; // Account for card margins and padding
      case DeviceType.tablet:
        return 48.0;
      case DeviceType.desktop:
        return 64.0;
    }
  }

  Widget _buildUnimplementedCard(
      BuildContext context, FretboardInstance instance) {
    return Card(
      margin: cleanViewMode ? EdgeInsets.zero : null,
      elevation: cleanViewMode ? 0 : null,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '${instance.viewMode.displayName} Mode',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This chord mode is currently under development and will be available in a future update.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => onUpdate(
                      fretboard.copyWith(viewMode: ViewMode.chordInversions)),
                  icon: const Icon(Icons.music_note),
                  label: const Text('Try Chord Inversions'),
                ),
                const SizedBox(width: 16),
                if (canRemove)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
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

  Widget _buildHeader(BuildContext context, FretboardInstance instance) {
    final config = instance.toConfig(
      layout: globalState.layout,
      globalFretCount: globalState.fretCount,
    );

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
                instance.isCompact ? Icons.expand_more : Icons.expand_less),
            tooltip: instance.isCompact ? 'Show Controls' : 'Hide Controls',
            iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                    DeviceType.mobile
                ? 20.0
                : 24.0,
            onPressed: () {
              onUpdate(instance.copyWith(isCompact: !instance.isCompact));
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
              instance.showScaleStrip ? Icons.piano : Icons.piano_off,
              color: instance.showScaleStrip
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                    DeviceType.mobile
                ? 20.0
                : 24.0,
            tooltip: 'Toggle Scale Strip',
            onPressed: () {
              onUpdate(
                  instance.copyWith(showScaleStrip: !instance.showScaleStrip));
            },
          ),
          // NEW: Octave Toggle (for scale mode)
          if (instance.viewMode == ViewMode.scales)
            IconButton(
              icon: Icon(
                Icons.repeat_one, // Octave icon (representing repetition/octave)
                color: instance.showOctave
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                      DeviceType.mobile
                  ? 20.0
                  : 24.0,
              tooltip: 'Toggle Octave',
              onPressed: () {
                onUpdate(instance.copyWith(
                  showOctave: !instance.showOctave,
                ));
              },
            ),
          // NEW: Additional Octaves Toggle (for chord inversion and open chord modes)
          if (instance.viewMode == ViewMode.chordInversions || 
              instance.viewMode == ViewMode.openChords)
            IconButton(
              icon: Icon(
                instance.showAdditionalOctaves
                    ? Icons.all_inclusive
                    : Icons.all_inclusive_outlined,
                color: instance.showAdditionalOctaves
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                      DeviceType.mobile
                  ? 20.0
                  : 24.0,
              tooltip: 'Toggle Additional Octaves',
              onPressed: () {
                onUpdate(instance.copyWith(
                    showAdditionalOctaves: !instance.showAdditionalOctaves));
              },
            ),
          // NEW: Show All Positions Toggle (only for open chord mode)
          if (instance.viewMode == ViewMode.openChords)
            IconButton(
              icon: Icon(
                instance.showAllPositions
                    ? Icons.grid_view
                    : Icons.grid_view_outlined,
                color: instance.showAllPositions
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                      DeviceType.mobile
                  ? 20.0
                  : 24.0,
              tooltip: 'Show All Positions',
              onPressed: () {
                onUpdate(instance.copyWith(
                    showAllPositions: !instance.showAllPositions));
              },
            ),
          IconButton(
            icon: Icon(
              instance.showNoteNames ? Icons.abc : Icons.numbers,
              color: instance.showNoteNames
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            iconSize: ResponsiveConstants.getDeviceType(screenWidth) ==
                    DeviceType.mobile
                ? 20.0
                : 24.0,
            tooltip:
                instance.showNoteNames ? 'Show Intervals' : 'Show Note Names',
            onPressed: () {
              onUpdate(
                  instance.copyWith(showNoteNames: !instance.showNoteNames));
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

  String _getHeaderText(FretboardConfig config) {
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isCompact = deviceType == DeviceType.mobile;

    if (config.isAnyChordMode) {
      if (isCompact) {
        return '${config.currentChordName} - ${config.tuning.length}str';
      }
      return '${config.currentChordName} - ${config.tuning.length} strings - ${config.layout.displayName}';
    } else if (config.isIntervalMode) {
      if (isCompact) {
        return '${config.effectiveRoot} Intervals - ${config.tuning.length}str';
      }
      return '${config.effectiveRoot} Intervals - ${config.tuning.length} strings - ${config.layout.displayName}';
    } else if (config.isScaleMode) {
      if (isCompact) {
        return '${config.effectiveRoot} ${config.currentModeName} - ${config.tuning.length}str';
      }
      return '${config.effectiveRoot} ${config.currentModeName} - ${config.tuning.length} strings - ${config.layout.displayName}';
    } else {
      // For unimplemented chord modes
      if (isCompact) {
        return '${config.viewMode.displayName} - ${config.tuning.length}str';
      }
      return '${config.viewMode.displayName} - ${config.tuning.length} strings - ${config.layout.displayName}';
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

      // Get clicked note details with proper flat preference
      final currentRootNote = Note.fromString('${fretboard.root}0');
      final clickedNote = Note.fromMidi(midiNote, preferFlats: currentRootNote.preferFlats);

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
