// lib/views/widgets/fretboard/scale_strip.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/fretboard/fretboard_config.dart';
import '../../../models/music/note.dart';
import '../../../models/music/chord.dart';
import '../../../models/music/scale.dart';
import '../../../constants/ui_constants.dart';
import '../../../controllers/fretboard_controller.dart';
import '../../../controllers/music_controller.dart';
import '../../../utils/color_utils.dart';
import '../../../utils/note_utils.dart';

class ScaleStrip extends StatelessWidget {
  final FretboardConfig config;
  final Function(int midiNote)? onNoteTap;

  const ScaleStrip({
    super.key,
    required this.config,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate display octaves for all modes properly
    Set<int> displayOctaves;
    int actualOctaveCount;

    if (config.isChordMode) {
      // For chord mode with inversions, calculate needed octaves
      final chord = Chord.get(config.chordType);
      if (chord != null) {
        // Get the chord voicing to determine actual octave span
        final baseOctave = config.selectedChordOctave;
        final rootNote = Note.fromString('${config.root}$baseOctave');
        final voicingMidiNotes = chord.buildVoicing(
          root: rootNote,
          inversion: config.chordInversion,
        );

        // Find min and max octaves in voicing
        if (voicingMidiNotes.isNotEmpty) {
          // Convert MIDI notes back to octaves using the same formula as Note.fromMidi
          final minNote = Note.fromMidi(voicingMidiNotes.reduce(math.min));
          final maxNote = Note.fromMidi(voicingMidiNotes.reduce(math.max));
          
          displayOctaves = {};
          for (int i = minNote.octave; i <= maxNote.octave; i++) {
            displayOctaves.add(i);
          }
          actualOctaveCount = displayOctaves.length;
          
          debugPrint('Chord mode: root=${config.root}, baseOctave=$baseOctave, voicing=$voicingMidiNotes');
          debugPrint('Chord mode octaves: min=${minNote.octave}, max=${maxNote.octave}, display=$displayOctaves');
        } else {
          displayOctaves = {baseOctave};
          actualOctaveCount = 1;
        }
      } else {
        displayOctaves =
            config.selectedOctaves.isEmpty ? {3} : config.selectedOctaves;
        actualOctaveCount = 1;
      }
    } else {
      // For interval and scale modes, use all selected octaves
      displayOctaves =
          config.selectedOctaves.isEmpty ? {3} : config.selectedOctaves;
      actualOctaveCount = displayOctaves.length;
    }

    final totalHeight = UIConstants.scaleStripLabelSpace +
        (actualOctaveCount * UIConstants.noteRowHeight) +
        (actualOctaveCount * UIConstants.scaleStripPaddingPerOctave);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minRequiredWidth = 13 * 60.0;
        final actualWidth = constraints.maxWidth < minRequiredWidth
            ? minRequiredWidth
            : constraints.maxWidth;

        return Container(
          width: actualWidth,
          height: totalHeight,
          child: CustomPaint(
            size: Size(actualWidth, totalHeight),
            painter: ScaleStripPainter(
              config: config,
              displayOctaves: displayOctaves,
              highlightMap: FretboardController.getHighlightMap(config),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _handleTap(context, details, displayOctaves),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(
      BuildContext context, TapDownDetails details, Set<int> displayOctaves) {
    if (onNoteTap == null) return;

    final box = context.findRenderObject() as RenderBox;
    final noteWidth = box.size.width / 13.0;
    final noteIndex =
        (details.localPosition.dx / noteWidth).clamp(0, 12).floor();

    final clickY = details.localPosition.dy - UIConstants.scaleStripLabelSpace;
    final rowHeight = UIConstants.noteRowHeight;
    final octaveRowIndex = (clickY / rowHeight).floor();

    final sortedOctaves = displayOctaves.toList()..sort();

    if (octaveRowIndex >= 0 && octaveRowIndex < sortedOctaves.length) {
      final clickedOctave = sortedOctaves[octaveRowIndex];

      if (config.isIntervalMode) {
        // Interval mode logic
        final referenceOctave = sortedOctaves.first;
        
        // Calculate the extended interval based on the click position
        int extendedInterval;
        if (noteIndex == 12) {
          // Special handling for the 13th position (octave)
          extendedInterval = ((clickedOctave - referenceOctave + 1) * 12);
        } else {
          extendedInterval = ((clickedOctave - referenceOctave) * 12) + (noteIndex % 12);
        }

        final rootNote = Note.fromString('${config.root}$referenceOctave');
        final clickedMidi = rootNote.midi + extendedInterval;

        onNoteTap!(clickedMidi);
      } else {
        // Scale mode logic
        final effectiveRoot = MusicController.getModeRoot(
            config.root, config.scale, config.modeIndex);
        final rootNote = Note.fromString('$effectiveRoot$clickedOctave');
        final clickedMidi = rootNote.midi + (noteIndex % 12);

        onNoteTap!(clickedMidi);
      }
    }
  }
}

class ScaleStripPainter extends CustomPainter {
  final FretboardConfig config;
  final Set<int> displayOctaves;
  final Map<int, Color> highlightMap;

  ScaleStripPainter({
    required this.config,
    required this.displayOctaves,
    required this.highlightMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rootForDisplay = config.isChordMode
        ? config.root
        : MusicController.getModeRoot(
            config.root, config.scale, config.modeIndex);

    final rootNote = Note.fromString('${rootForDisplay}0');
    final useFlats = rootNote.preferFlats;

    final chromaticSequence = NoteUtils.chromaticSequence(rootForDisplay);

    final sortedOctaves = displayOctaves.toList()..sort();
    final octavesToShow = sortedOctaves;

    // Draw each octave row
    for (int i = 0; i < octavesToShow.length; i++) {
      final octave = octavesToShow[i];
      final rowY =
          UIConstants.scaleStripLabelSpace + (i * UIConstants.noteRowHeight);

      try {
        _drawOctaveRow(
          canvas,
          size,
          octave,
          rowY,
          chromaticSequence,
          rootNote.pitchClass,
          config.isChordMode,
        );

        // Draw octave label
        _drawOctaveLabel(canvas, octave, rowY, config.isChordMode, i);
      } catch (e) {
        // Silently handle any drawing errors to prevent crash
        debugPrint('Error drawing octave $octave: $e');
      }
    }
  }

  void _drawOctaveRow(
    Canvas canvas,
    Size size,
    int octave,
    double rowY,
    List<String> chromaticSequence,
    int rootPc,
    bool isChordMode,
  ) {
    final noteWidth = size.width / 13.0;

    for (int pc = 0; pc < 13; pc++) {
      final cx = pc * noteWidth + noteWidth / 2;
      if (cx < 0 || cx > size.width) continue;

      final actualPc = (rootPc + (pc % 12)) % 12;
      
      // Calculate octave correctly
      final noteOctave = octave + ((rootPc + pc) ~/ 12);
      
      // Create the note and get its MIDI value
      final note = Note(pitchClass: actualPc, octave: noteOctave);
      final midi = note.midi;

      // Determine if highlighted
      bool isHighlighted = false;
      Color noteColor = Colors.grey.shade300;
      int intervalForColor = pc % 12;
      
      // Check highlight map for all modes
      if (highlightMap.containsKey(midi)) {
        isHighlighted = true;
        noteColor = highlightMap[midi]!;
        
        if (config.isScaleMode) {
          // Calculate the interval within the musical octave
          final effectiveRoot = MusicController.getModeRoot(
              config.root, config.scale, config.modeIndex);
          final octaveRoot = Note.fromString('$effectiveRoot$octave');
          
          // If note is below root in pitch class, it belongs to previous octave
          if (actualPc < rootPc && pc < 12) {
            final prevOctaveRoot = Note.fromString('$effectiveRoot${octave - 1}');
            intervalForColor = midi - prevOctaveRoot.midi;
          } else {
            intervalForColor = midi - octaveRoot.midi;
          }
          
          // Clamp to 0-12 range
          if (intervalForColor > 12) intervalForColor = 12;
          if (intervalForColor < 0) intervalForColor = 0;
        } else if (config.isChordMode) {
          // Get interval from the chord root
          final baseOctave = config.selectedChordOctave;
          final chordRootNote = Note.fromString('${config.root}$baseOctave');
          final extendedInterval = midi - chordRootNote.midi;
          intervalForColor = extendedInterval % 12;
        } else if (config.isIntervalMode) {
          // Get interval from reference octave
          final minOctave = displayOctaves.reduce((a, b) => a < b ? a : b);
          final rootNote = Note.fromString('${config.root}$minOctave');
          intervalForColor = (midi - rootNote.midi) % 12;
        }
      }

      // Draw note circle
      _drawNoteCircle(canvas, cx, rowY + 50, noteColor, isHighlighted);

      // Draw interval label
      _drawIntervalLabel(
        canvas,
        cx,
        rowY + 15,
        actualPc,
        rootPc,
        octave,
        isHighlighted,
        config.isChordMode,
        intervalForColor,
        midi,
      );

      // Draw note name
      _drawNoteName(
        canvas,
        cx,
        rowY + 50,
        chromaticSequence[pc % 12],
        noteOctave,
        noteColor,
        isHighlighted,
      );
    }
  }

  int _getIntervalFromHighlightMap(int midi, int rootPc, int octave) {
    // This is a helper to determine the interval for coloring purposes
    if (config.isIntervalMode) {
      final minOctave = displayOctaves.reduce((a, b) => a < b ? a : b);
      final rootNote = Note.fromString('${config.root}$minOctave');
      return midi - rootNote.midi;
    }
    return (midi % 12 - rootPc + 12) % 12;
  }

  void _drawNoteCircle(
      Canvas canvas, double cx, double cy, Color color, bool isHighlighted) {
    canvas.drawCircle(
      Offset(cx, cy),
      UIConstants.scaleStripNoteRadius,
      Paint()..color = color,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      UIConstants.scaleStripNoteRadius,
      Paint()
        ..color = isHighlighted ? Colors.black : Colors.grey.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 2 : 1,
    );
  }

  void _drawIntervalLabel(
    Canvas canvas,
    double cx,
    double cy,
    int notePc,
    int rootPc,
    int octave,
    bool isHighlighted,
    bool isChordMode,
    int intervalForScale,
    int midi,
  ) {
    String intervalLabel;

    if (isHighlighted) {
      if (config.isScaleMode) {
        // For scale mode, use the calculated interval
        intervalLabel = FretboardController.getIntervalLabel(intervalForScale);
      } else if (config.isChordMode) {
        // For chord mode, calculate from chord root
        final baseOctave = config.selectedChordOctave;
        final chordRootNote = Note.fromString('${config.root}$baseOctave');
        final extendedInterval = midi - chordRootNote.midi;
        intervalLabel = FretboardController.getIntervalLabel(extendedInterval);
      } else if (config.isIntervalMode) {
        // Extended interval for interval mode
        final minOctave = displayOctaves.reduce((a, b) => a < b ? a : b);
        final rootNote = Note.fromString('${config.root}$minOctave');
        final extendedInterval = midi - rootNote.midi;
        intervalLabel = FretboardController.getIntervalLabel(extendedInterval);
      } else {
        // Default to simple interval
        final interval = (notePc - rootPc + 12) % 12;
        intervalLabel = FretboardController.getIntervalLabel(interval);
      }
    } else {
      // Not highlighted - show simple interval
      final interval = (notePc - rootPc + 12) % 12;
      intervalLabel = FretboardController.getIntervalLabel(interval);
    }

    final intervalPainter = TextPainter(
      text: TextSpan(
        text: intervalLabel,
        style: TextStyle(
          fontSize: isHighlighted ? 11 : 9,
          color: isHighlighted ? Colors.black : Colors.grey.shade600,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final intervalOffset = Offset(cx - intervalPainter.width / 2, cy);

    // Add subtle background for highlighted intervals
    if (isHighlighted) {
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          intervalOffset.dx - 3,
          intervalOffset.dy - 1,
          intervalPainter.width + 6,
          intervalPainter.height + 2,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(bgRect, Paint()..color = Colors.white.withOpacity(0.85));
    }

    intervalPainter.paint(canvas, intervalOffset);
  }

  void _drawNoteName(
    Canvas canvas,
    double cx,
    double cy,
    String noteName,
    int octave,
    Color noteColor,
    bool isHighlighted,
  ) {
    // Always show note name with octave number
    final noteNameWithOctave = '$noteName$octave';

    final notePainter = TextPainter(
      text: TextSpan(
        text: noteNameWithOctave,
        style: TextStyle(
          fontSize: isHighlighted ? 11 : 9,
          color: ColorUtils.getContrastingTextColor(noteColor),
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    notePainter.paint(
      canvas,
      Offset(cx - notePainter.width / 2, cy - notePainter.height / 2),
    );
  }

  void _drawOctaveLabel(
      Canvas canvas, int octave, double rowY, bool isChordMode, int rowIndex) {
    String rowLabel;
    if (isChordMode) {
      // For chord mode with extended intervals, label appropriately
      if (rowIndex == 0) {
        rowLabel = 'Chord';
      } else {
        rowLabel = 'Ext.'; // Extended intervals
      }
    } else {
      rowLabel = 'Oct $octave';
    }

    final octaveLabelPainter = TextPainter(
      text: TextSpan(
        text: rowLabel,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Keep the label at positive offset as the fix
    octaveLabelPainter.paint(
      canvas,
      Offset(10, rowY + 40),
    );
  }

  @override
  bool shouldRepaint(covariant ScaleStripPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.displayOctaves != displayOctaves ||
        oldDelegate.highlightMap != highlightMap;
  }
}