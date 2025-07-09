// lib/views/widgets/fretboard/scale_strip.dart - Fixed to respect user octave selection
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
    // FIXED: Always use the user's selected octaves, don't override with chord voicing calculation
    Set<int> displayOctaves =
        config.selectedOctaves.isEmpty ? {3} : config.selectedOctaves;
    int actualOctaveCount = displayOctaves.length;

    // FIXED: For chord mode, we still respect the user's octave selection
    // but may show additional context if the chord naturally extends
    if (config.isChordMode) {
      final chord = Chord.get(config.chordType);
      if (chord != null && displayOctaves.isNotEmpty) {
        // Use the user's selected octave as the primary display
        final userOctave = displayOctaves.first;
        final rootNote = Note.fromString('${config.root}$userOctave');
        final voicingMidiNotes = chord.buildVoicing(
          root: rootNote,
          inversion: config.chordInversion,
        );

        if (voicingMidiNotes.isNotEmpty) {
          // Check if the chord voicing extends beyond the user's selection
          final minNote = Note.fromMidi(voicingMidiNotes.reduce(math.min));
          final maxNote = Note.fromMidi(voicingMidiNotes.reduce(math.max));

          // Only add adjacent octaves if necessary and reasonable
          final voicingOctaves = <int>{};
          for (int i = minNote.octave; i <= maxNote.octave; i++) {
            voicingOctaves.add(i);
          }

          // If the voicing only extends one octave beyond user selection, include it
          // Otherwise, stick with user selection
          if (voicingOctaves.length <= 3) {
            final combinedOctaves = Set<int>.from(displayOctaves);
            for (final oct in voicingOctaves) {
              if (displayOctaves.any((userOct) => (oct - userOct).abs() <= 1)) {
                combinedOctaves.add(oct);
              }
            }
            displayOctaves = combinedOctaves;
            actualOctaveCount = displayOctaves.length;

            debugPrint(
                'Chord mode scale strip: user octaves=${config.selectedOctaves}, voicing spans=${voicingOctaves}, displaying=$displayOctaves');
          } else {
            debugPrint(
                'Chord mode scale strip: voicing too wide, using user selection only: $displayOctaves');
          }
        }
      }
    }

    debugPrint(
        'Scale strip: final display octaves=$displayOctaves, count=$actualOctaveCount');

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
          extendedInterval =
              ((clickedOctave - referenceOctave) * 12) + (noteIndex % 12);
        }

        final rootNote = Note.fromString('${config.root}$referenceOctave');
        final clickedMidi = rootNote.midi + extendedInterval;

        onNoteTap!(clickedMidi);
      } else {
        // Scale and chord mode logic
        final effectiveRoot = config.isChordMode
            ? config.root
            : MusicController.getModeRoot(
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

    // Draw each octave row
    for (int i = 0; i < sortedOctaves.length; i++) {
      final octave = sortedOctaves[i];
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

        // FIXED: Draw more appropriate octave labels
        _drawOctaveLabel(
            canvas, octave, rowY, config.isChordMode, i, sortedOctaves.length);
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
            final prevOctaveRoot =
                Note.fromString('$effectiveRoot${octave - 1}');
            intervalForColor = midi - prevOctaveRoot.midi;
          } else {
            intervalForColor = midi - octaveRoot.midi;
          }

          // Clamp to 0-12 range
          if (intervalForColor > 12) intervalForColor = 12;
          if (intervalForColor < 0) intervalForColor = 0;
        } else if (config.isChordMode) {
          // FIXED: Get interval from the user's selected octave, not calculated octave
          final userOctave = config.selectedOctaves.first;
          final chordRootNote = Note.fromString('${config.root}$userOctave');
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
        // FIXED: For chord mode, calculate from user's selected octave
        final userOctave = config.selectedOctaves.first;
        final chordRootNote = Note.fromString('${config.root}$userOctave');
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

  void _drawOctaveLabel(Canvas canvas, int octave, double rowY,
      bool isChordMode, int rowIndex, int totalRows) {
    String rowLabel;
    if (isChordMode) {
      // FIXED: Show actual octave numbers in chord mode too
      rowLabel = 'Oct $octave';
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
