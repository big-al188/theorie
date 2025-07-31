// lib/views/widgets/fretboard/fretboard_container.dart - Integrated with audio controls
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_state.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../models/fretboard/fretboard_instance.dart';
import '../../../models/music/note.dart';
import '../../../controllers/fretboard_controller.dart';
import '../../../constants/ui_constants.dart'; // NEW: For responsive constants
import 'fretboard_widget.dart';
import 'audio_controls.dart'; // NEW: Import audio controls

/// Stateful container that manages fretboard instance state with audio integration
class FretboardContainer extends StatefulWidget {
  final FretboardInstance instance;
  final Function(FretboardInstance) onUpdate;
  final bool showControls;

  const FretboardContainer({
    super.key,
    required this.instance,
    required this.onUpdate,
    this.showControls = true,
  });

  @override
  State<FretboardContainer> createState() => _FretboardContainerState();
}

class _FretboardContainerState extends State<FretboardContainer> {
  
  // Helper method to check if a note exists on the fretboard
  bool _noteExistsOnFretboard(int midiNote, List<String> tuning, int maxFrets) {
    for (final tuningNote in tuning) {
      final openNote = Note.fromString(tuningNote);
      final fretNumber = midiNote - openNote.midi;
      if (fretNumber >= 0 && fretNumber <= maxFrets) {
        return true;
      }
    }
    return false;
  }
  
  void _handleFretTap(int stringIndex, int fretIndex) {
    if (widget.instance.viewMode == ViewMode.intervals) {
      final appState = context.read<AppState>();
      
      // Calculate the tapped note
      final openStringNote = Note.fromString(widget.instance.tuning[stringIndex]);
      final tappedNote = openStringNote.transpose(fretIndex);
      final tappedMidi = tappedNote.midi;
      
      // Get reference octave
      final sortedOctaves = widget.instance.selectedOctaves.toList()..sort();
      final referenceOctave = sortedOctaves.isNotEmpty ? sortedOctaves.first : 3;
      
      // Safely create root note
      final rootNoteString = widget.instance.root.contains(RegExp(r'\d')) 
          ? widget.instance.root 
          : '${widget.instance.root}$referenceOctave';
      final rootNote = Note.fromString(rootNoteString);
      
      // Calculate extended interval from the current root
      final extendedInterval = tappedMidi - rootNote.midi;
      
      debugPrint('Fretboard tap: string $stringIndex, fret $fretIndex, MIDI $tappedMidi, interval $extendedInterval');
      
      var newIntervals = Set<int>.from(widget.instance.selectedIntervals);
      var newOctaves = Set<int>.from(widget.instance.selectedOctaves);
      var newRoot = widget.instance.root;
      
      // Handle based on current state
      if (newIntervals.isEmpty) {
        // No notes selected - this becomes the new root
        newRoot = tappedNote.name;
        newIntervals = {0};
        newOctaves = {tappedNote.octave};
        
        debugPrint('Setting new root: $newRoot');
        
        // Update global root
        if (appState.viewMode == ViewMode.intervals) {
          appState.setRoot(newRoot);
        }
      } else if (newIntervals.contains(extendedInterval)) {
        // Removing an existing interval
        newIntervals.remove(extendedInterval);
        
        if (newIntervals.isEmpty) {
          // Just removed the last note - empty state
          debugPrint('All intervals removed - empty state');
        } else if (extendedInterval == 0) {
          // Removed the root - find new root from lowest remaining interval
          final lowestInterval = newIntervals.reduce((a, b) => a < b ? a : b);
          final newRootMidi = rootNote.midi + lowestInterval;
          final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
          newRoot = newRootNote.name;
          
          // Recalculate the new root's octave
          newOctaves = {newRootNote.octave};
          
          // Adjust all intervals relative to new root
          final adjustedIntervals = <int>{};
          for (final interval in newIntervals) {
            final adjustedInterval = interval - lowestInterval;
            adjustedIntervals.add(adjustedInterval);
            
            // Add octaves for all notes
            final noteMidi = newRootMidi + adjustedInterval;
            final noteOctave = Note.fromMidi(noteMidi).octave;
            newOctaves.add(noteOctave);
          }
          newIntervals = adjustedIntervals;
          
          debugPrint('Root removed - new root: $newRoot');
          
          // Update global root
          if (appState.viewMode == ViewMode.intervals) {
            appState.setRoot(newRoot);
          }
        } else if (newIntervals.length == 1 && !newIntervals.contains(0)) {
          // SINGLE INTERVAL BECOMES ROOT LOGIC
          final singleInterval = newIntervals.first;
          final newRootMidi = rootNote.midi + singleInterval;
          final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
          newRoot = newRootNote.name;
          newOctaves = {newRootNote.octave};
          newIntervals = {0};
          
          debugPrint('Single interval becomes new root: $newRoot');
          
          // Update global root
          if (appState.viewMode == ViewMode.intervals) {
            appState.setRoot(newRoot);
          }
        }
      } else {
        // Adding a new interval
        if (extendedInterval < 0) {
          // Note is below current root
          
          // Calculate how many octaves down we need to go
          final octavesDown = ((-extendedInterval - 1) ~/ 12) + 1;
          final newReferenceOctave = referenceOctave - octavesDown;
          
          // Check if the new root would exist on the fretboard
          final newRootNoteString = '${widget.instance.root}$newReferenceOctave';
          final newRootNote = Note.fromString(newRootNoteString);
          final rootExistsOnFretboard = _noteExistsOnFretboard(
            newRootNote.midi, 
            widget.instance.tuning, 
            appState.fretCount
          );
          
          if (!rootExistsOnFretboard) {
            // The root wouldn't exist on the fretboard - make the clicked note the new root
            newRoot = tappedNote.name;
            
            // Recalculate all intervals relative to the new root
            final adjustedIntervals = <int>{};
            for (final interval in newIntervals) {
              final oldNoteMidi = rootNote.midi + interval;
              final newInterval = oldNoteMidi - tappedNote.midi;
              if (newInterval >= 0) {
                adjustedIntervals.add(newInterval);
              }
            }
            adjustedIntervals.add(0); // Add new root
            newIntervals = adjustedIntervals;
            newOctaves = {tappedNote.octave};
            
            // Collect octaves for all intervals
            for (final interval in newIntervals) {
              final noteMidi = tappedNote.midi + interval;
              final noteOctave = Note.fromMidi(noteMidi).octave;
              newOctaves.add(noteOctave);
            }
            
            debugPrint('Root would be off-fretboard - setting clicked note as new root: $newRoot');
            
            // Update global root
            if (appState.viewMode == ViewMode.intervals) {
              appState.setRoot(newRoot);
            }
          } else {
            // Root exists on fretboard - normal octave extension
            
            // Add the new lower octaves
            for (int i = 0; i < octavesDown; i++) {
              newOctaves.add(referenceOctave - i - 1);
            }
            
            // First, convert existing intervals to their new values
            final adjustedIntervals = <int>{};
            for (final interval in newIntervals) {
              adjustedIntervals.add(interval + (octavesDown * 12));
            }
            
            // Now add the new interval
            final adjustedNewInterval = tappedMidi - newRootNote.midi;
            adjustedIntervals.add(adjustedNewInterval);
            
            newIntervals = adjustedIntervals;
            
            debugPrint('Added note below root - extended octaves downward');
          }
        } else {
          // Normal case - just add the interval
          newIntervals.add(extendedInterval);
          
          // Make sure we have the octave for this note
          if (!newOctaves.contains(tappedNote.octave)) {
            newOctaves.add(tappedNote.octave);
          }
        }
      }
      
      // Always check after state change if we have single interval
      if (newIntervals.length == 1 && !newIntervals.contains(0)) {
        // Single non-root interval should become root
        final singleInterval = newIntervals.first;
        final newRootMidi = rootNote.midi + singleInterval;
        final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
        newRoot = newRootNote.name;
        newOctaves = {newRootNote.octave};
        newIntervals = {0};
        
        debugPrint('After state change: single interval becomes new root: $newRoot');
        
        // Update global root
        if (appState.viewMode == ViewMode.intervals) {
          appState.setRoot(newRoot);
        }
      }
      
      widget.onUpdate(widget.instance.copyWith(
        root: newRoot,
        selectedIntervals: newIntervals,
        selectedOctaves: newOctaves,
      ));
    }
  }

  void _handleScaleNoteTap(int midiNote) {
    if (widget.instance.viewMode == ViewMode.intervals) {
      final appState = context.read<AppState>();
      
      debugPrint('Scale note tapped with MIDI: $midiNote');

      // Get clicked note details
      final clickedNote = Note.fromMidi(midiNote);
      
      // Calculate the extended interval from the current root
      final referenceOctave = widget.instance.selectedOctaves.isEmpty
          ? 3
          : widget.instance.selectedOctaves.reduce((a, b) => a < b ? a : b);
      
      // Safely create root note
      final rootNoteString = widget.instance.root.contains(RegExp(r'\d')) 
          ? widget.instance.root 
          : '${widget.instance.root}$referenceOctave';
      final rootNote = Note.fromString(rootNoteString);
      
      final extendedInterval = midiNote - rootNote.midi;

      var newIntervals = Set<int>.from(widget.instance.selectedIntervals);
      var newOctaves = Set<int>.from(widget.instance.selectedOctaves);
      var newRoot = widget.instance.root;
      
      // Handle based on current state
      if (newIntervals.isEmpty) {
        // No notes selected - this becomes the new root
        newRoot = clickedNote.name;
        newIntervals = {0};
        newOctaves = {clickedNote.octave};
        
        debugPrint('Setting new root from scale strip: $newRoot');
        
        // Update global root
        if (appState.viewMode == ViewMode.intervals) {
          appState.setRoot(newRoot);
        }
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
          
          // Reset octaves based on new root
          newOctaves = {newRootNote.octave};
          
          // Adjust intervals and collect octaves
          final adjustedIntervals = <int>{};
          for (final interval in newIntervals) {
            final adjustedInterval = interval - lowestInterval;
            adjustedIntervals.add(adjustedInterval);
            
            // Add octave for this note
            final noteMidi = newRootMidi + adjustedInterval;
            final noteOctave = Note.fromMidi(noteMidi).octave;
            newOctaves.add(noteOctave);
          }
          newIntervals = adjustedIntervals;
          
          // Update global root
          if (appState.viewMode == ViewMode.intervals) {
            appState.setRoot(newRoot);
          }
        } else if (newIntervals.length == 1 && !newIntervals.contains(0)) {
          // SINGLE INTERVAL BECOMES ROOT LOGIC
          final singleInterval = newIntervals.first;
          final newRootMidi = rootNote.midi + singleInterval;
          final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
          newRoot = newRootNote.name;
          newOctaves = {newRootNote.octave};
          newIntervals = {0};
          
          debugPrint('Single interval from scale strip becomes new root: $newRoot');
          
          // Update global root
          if (appState.viewMode == ViewMode.intervals) {
            appState.setRoot(newRoot);
          }
        }
      } else {
        // Adding new interval
        if (extendedInterval < 0) {
          // Below root
          
          // Calculate how many octaves down
          final octavesDown = ((-extendedInterval - 1) ~/ 12) + 1;
          final newReferenceOctave = referenceOctave - octavesDown;
          
          // Check if new root would exist on fretboard
          final newRootNoteString = '${widget.instance.root}$newReferenceOctave';
          final newRootNote = Note.fromString(newRootNoteString);
          final rootExistsOnFretboard = _noteExistsOnFretboard(
            newRootNote.midi,
            widget.instance.tuning,
            appState.fretCount
          );
          
          if (!rootExistsOnFretboard) {
            // Make clicked note the new root
            newRoot = clickedNote.name;
            
            // Recalculate intervals
            final adjustedIntervals = <int>{};
            for (final interval in newIntervals) {
              final oldNoteMidi = rootNote.midi + interval;
              final newInterval = oldNoteMidi - clickedNote.midi;
              if (newInterval >= 0) {
                adjustedIntervals.add(newInterval);
              }
            }
            adjustedIntervals.add(0);
            newIntervals = adjustedIntervals;
            newOctaves = {clickedNote.octave};
            
            // Collect octaves
            for (final interval in newIntervals) {
              final noteMidi = clickedNote.midi + interval;
              final noteOctave = Note.fromMidi(noteMidi).octave;
              newOctaves.add(noteOctave);
            }
            
            debugPrint('Root would be off-fretboard from scale strip - new root: $newRoot');
            
            // Update global root
            if (appState.viewMode == ViewMode.intervals) {
              appState.setRoot(newRoot);
            }
          } else {
            // Normal octave extension
            for (int i = 0; i < octavesDown; i++) {
              newOctaves.add(referenceOctave - i - 1);
            }
            
            // Adjust existing intervals
            final adjustedIntervals = <int>{};
            for (final interval in newIntervals) {
              adjustedIntervals.add(interval + (octavesDown * 12));
            }
            
            // Add the new interval
            final adjustedNewInterval = midiNote - newRootNote.midi;
            adjustedIntervals.add(adjustedNewInterval);
            
            newIntervals = adjustedIntervals;
          }
        } else {
          // Normal addition
          newIntervals.add(extendedInterval);
          
          // Add octave if needed
          if (!newOctaves.contains(clickedNote.octave)) {
            newOctaves.add(clickedNote.octave);
          }
        }
      }

      // Always check after state change if we have single interval
      if (newIntervals.length == 1 && !newIntervals.contains(0)) {
        // Single non-root interval should become root
        final singleInterval = newIntervals.first;
        final newRootMidi = rootNote.midi + singleInterval;
        final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
        newRoot = newRootNote.name;
        newOctaves = {newRootNote.octave};
        newIntervals = {0};
        
        debugPrint('After scale strip state change: single interval becomes new root: $newRoot');
        
        // Update global root
        if (appState.viewMode == ViewMode.intervals) {
          appState.setRoot(newRoot);
        }
      }

      widget.onUpdate(widget.instance.copyWith(
        root: newRoot,
        selectedIntervals: newIntervals,
        selectedOctaves: newOctaves,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final config = widget.instance.toConfig(
          layout: appState.layout,
          globalFretCount: appState.fretCount,
        );

        // NEW: Check if we should show audio controls
        final shouldShowAudioControls = config.isIntervalMode && 
                                       appState.audioEnabled && 
                                       widget.showControls;

        return Column(
          children: [
            // NEW: Audio controls for interval mode
            if (shouldShowAudioControls) ...[
              AudioControls(config: config),
              SizedBox(height: ResponsiveConstants.getAudioControlsSpacing(
                MediaQuery.of(context).size.width,
              )),
            ],
            
            // Main fretboard widget
            FretboardWidget(
              config: config,
              onFretTap: _handleFretTap,
              onScaleNoteTap: _handleScaleNoteTap,
              onRangeChanged: widget.showControls
                  ? (start, end) {
                      widget.onUpdate(widget.instance.copyWith(
                        visibleFretStart: start,
                        visibleFretEnd: end,
                      ));
                    }
                  : null,
            ),
          ],
        );
      },
    );
  }
}