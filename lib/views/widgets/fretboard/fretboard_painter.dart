// lib/views/widgets/fretboard/fretboard_painter.dart
import 'package:flutter/material.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../models/music/chord.dart';
import '../../../models/music/note.dart';
import '../../../constants/ui_constants.dart';
import '../../../models/music/scale.dart';
import '../../../constants/music_constants.dart';
import '../../../controllers/fretboard_controller.dart';
import '../../../controllers/music_controller.dart';
import '../../../utils/color_utils.dart';

class FretboardPainter extends CustomPainter {
  final FretboardConfig config;
  final Map<int, Color> highlightMap;

  FretboardPainter({
    required this.config,
    required this.highlightMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final correctedFretCount =
        FretboardController.getCorrectedFretCount(config);

    final canvasWidth = size.width;
    final headWidth = canvasWidth * UIConstants.headWidthRatio;
    final availableWidth =
        canvasWidth - (config.visibleFretStart == 0 ? headWidth : 0);
    final fretWidth = availableWidth / correctedFretCount;
    final boardHeight = (config.stringCount + 1) * UIConstants.stringHeight;

    // Draw chord name at top if enabled
    double topOffset = 0;
    if (config.showChordName && config.isChordMode) {
      topOffset =
          _drawChordName(canvas, size, headWidth, config.visibleFretStart == 0);
    }

    // Apply transformations
    canvas.save();
    if (config.isLeftHanded) {
      canvas.translate(size.width, topOffset);
      canvas.scale(-1, 1);
      canvas.translate(0, -topOffset);
    } else if (topOffset > 0) {
      canvas.translate(0, topOffset);
    }

    // Draw fretboard components
    _drawFretboardStructure(canvas, size, canvasWidth, headWidth, fretWidth,
        boardHeight, correctedFretCount);
    _drawStrings(canvas, size, canvasWidth, headWidth, boardHeight);
    _drawFretMarkers(canvas, size, canvasWidth, headWidth, fretWidth,
        boardHeight, correctedFretCount);

    canvas.restore();
  }

  double _drawChordName(
      Canvas canvas, Size size, double headWidth, bool hasHeadstock) {
    final chordName = MusicController.getChordDisplayName(
      config.root,
      config.chordType,
      config.chordInversion,
    );

    final chordPainter = TextPainter(
      text: TextSpan(
        text: chordName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position chord name over headstock if visible, otherwise center over fretboard
    final chordNameX = hasHeadstock
        ? (headWidth - chordPainter.width) / 2 // Center over headstock
        : (size.width - chordPainter.width) / 2; // Center over entire width

    const chordNameY = 5.0;
    chordPainter.paint(canvas, Offset(chordNameX, chordNameY));

    return chordPainter.height + 10;
  }

  void _drawFretboardStructure(
    Canvas canvas,
    Size size,
    double canvasWidth,
    double headWidth,
    double fretWidth,
    double boardHeight,
    int correctedFretCount,
  ) {
    final fretPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = UIConstants.fretWidth;

    final nutPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = UIConstants.nutWidth;

    final edgePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = UIConstants.edgeWidth;

    // Draw edges
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), edgePaint);
    canvas.drawLine(
        Offset(0, boardHeight), Offset(size.width, boardHeight), edgePaint);

    double startX = 0;

    if (config.visibleFretStart == 0) {
      // Draw nut and headstock
      canvas.drawLine(
          Offset(headWidth, 0), Offset(headWidth, boardHeight), nutPaint);
      startX = headWidth;

      // Draw frets and numbers
      for (int f = 1; f <= config.visibleFretEnd; f++) {
        final x = startX + f * fretWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, boardHeight), fretPaint);

        // Draw fret number
        _drawFretNumber(canvas, f, startX + (f - 0.5) * fretWidth);
      }
    } else {
      // No headstock - draw all fret lines
      for (int f = 0; f <= correctedFretCount; f++) {
        final x = startX + f * fretWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, boardHeight), fretPaint);
      }

      // Draw fret numbers
      for (int f = 0; f < correctedFretCount; f++) {
        final actualFret = config.visibleFretStart + f;
        if (actualFret <= config.visibleFretEnd) {
          _drawFretNumber(canvas, actualFret, startX + (f + 0.5) * fretWidth);
        }
      }
    }
  }

  void _drawFretNumber(Canvas canvas, int fretNumber, double centerX) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$fretNumber',
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, -textPainter.height - 4),
    );
  }

  void _drawStrings(
    Canvas canvas,
    Size size,
    double canvasWidth,
    double headWidth,
    double boardHeight,
  ) {
    final stringPaint = Paint()..strokeWidth = 2;

    final stringOrder = config.isBassTop
        ? List.generate(config.stringCount, (i) => i)
        : List.generate(config.stringCount, (i) => config.stringCount - 1 - i);

    for (final stringIndex in stringOrder) {
      final row = stringOrder.indexOf(stringIndex);
      final y = (row + 1) * UIConstants.stringHeight;

      stringPaint.color = UIConstants
          .stringColors[stringIndex % UIConstants.stringColors.length];

      double startX = config.visibleFretStart == 0 ? headWidth : 0;
      canvas.drawLine(Offset(startX, y), Offset(size.width, y), stringPaint);

      // Draw tuning labels if headstock is visible
      if (config.visibleFretStart == 0) {
        final tuningLabel = config.tuning[stringIndex];
        final textPainter = TextPainter(
          text: TextSpan(
            text: tuningLabel,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelX = headWidth / 2 - textPainter.width / 2;
        textPainter.paint(canvas, Offset(labelX, y - textPainter.height / 2));
      }
    }
  }

  void _drawFretMarkers(
    Canvas canvas,
    Size size,
    double canvasWidth,
    double headWidth,
    double fretWidth,
    double boardHeight,
    int correctedFretCount,
  ) {
    final effectiveRoot = config.isChordMode
        ? config.root
        : MusicController.getModeRoot(
            config.root, config.scale, config.modeIndex);

    final rootNote = Note.fromString('${effectiveRoot}0');
    final useFlats = rootNote.preferFlats;

    final stringOrder = config.isBassTop
        ? List.generate(config.stringCount, (i) => i)
        : List.generate(config.stringCount, (i) => config.stringCount - 1 - i);

    double startX = config.visibleFretStart == 0 ? headWidth : 0;

    for (final stringIndex in stringOrder) {
      final row = stringOrder.indexOf(stringIndex);
      final y = (row + 1) * UIConstants.stringHeight;
      final openNote = Note.fromString(config.tuning[stringIndex]);

      if (config.visibleFretStart == 0) {
        // Handle open string
        if (highlightMap.containsKey(openNote.midi)) {
          _drawNoteMarker(
            canvas,
            headWidth / 2,
            y,
            openNote.midi,
            highlightMap[openNote.midi]!,
            rootNote.pitchClass,
            useFlats,
          );
        }

        // Draw markers for frets 1 through visibleFretEnd
        for (int f = 1; f <= config.visibleFretEnd; f++) {
          final frettedNote = openNote.transpose(f);
          if (highlightMap.containsKey(frettedNote.midi)) {
            _drawNoteMarker(
              canvas,
              startX + (f - 0.5) * fretWidth,
              y,
              frettedNote.midi,
              highlightMap[frettedNote.midi]!,
              rootNote.pitchClass,
              useFlats,
            );
          }
        }
      } else {
        // Draw markers for visible range
        for (int f = 0; f < correctedFretCount; f++) {
          final actualFret = config.visibleFretStart + f;
          final frettedNote = openNote.transpose(actualFret);

          if (highlightMap.containsKey(frettedNote.midi)) {
            _drawNoteMarker(
              canvas,
              startX + (f + 0.5) * fretWidth,
              y,
              frettedNote.midi,
              highlightMap[frettedNote.midi]!,
              rootNote.pitchClass,
              useFlats,
            );
          }
        }
      }
    }
  }

  void _drawNoteMarker(
    Canvas canvas,
    double cx,
    double cy,
    int midi,
    Color markerColor,
    int rootPc,
    bool useFlats,
  ) {
    // Draw colored circle
    canvas.drawCircle(
      Offset(cx, cy),
      UIConstants.noteMarkerRadius,
      Paint()..color = markerColor,
    );

    // Draw border
    canvas.drawCircle(
      Offset(cx, cy),
      UIConstants.noteMarkerRadius,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = UIConstants.noteMarkerStrokeWidth,
    );

    // Determine what to display based on showNoteNames
    String displayText;
    bool isRoot = false;

    if (config.showNoteNames) {
      // Show note name
      final note = Note.fromMidi(midi, preferFlats: useFlats);
      displayText = note.name;
      isRoot = note.pitchClass == rootPc;
    } else {
      // Show interval label
      if (config.isChordMode) {
        // For chord mode, calculate the exact interval from the chord's voicing
        final chord = Chord.get(config.chordType);
        if (chord != null) {
          // Build the voicing to get the exact intervals
          final chordRootNote =
              Note.fromString('${config.root}${config.selectedChordOctave}');
          final voicingMidiNotes = chord.buildVoicing(
            root: chordRootNote,
            inversion: config.chordInversion,
          );

          // Find which interval this note represents in the chord
          int? matchedInterval;
          for (int i = 0; i < voicingMidiNotes.length; i++) {
            if (voicingMidiNotes[i] == midi) {
              // Found the note in the voicing
              // Calculate its interval from the root
              matchedInterval = midi - chordRootNote.midi;
              isRoot = matchedInterval == 0;
              break;
            }
          }

          if (matchedInterval != null && matchedInterval >= 0) {
            displayText = FretboardController.getIntervalLabel(matchedInterval);
          } else {
            // Fallback for notes not in the chord
            final notePc = midi % 12;
            final intervalFromRoot = (notePc - rootPc + 12) % 12;
            displayText =
                FretboardController.getIntervalLabel(intervalFromRoot);
          }
        } else {
          // Fallback if chord not found
          final notePc = midi % 12;
          final intervalFromRoot = (notePc - rootPc + 12) % 12;
          isRoot = intervalFromRoot == 0;
          displayText = FretboardController.getIntervalLabel(intervalFromRoot);
        }
      } else if (config.isIntervalMode) {
        // For interval mode, calculate extended interval
        final sortedOctaves = config.selectedOctaves.toList()..sort();
        final referenceOctave =
            sortedOctaves.isNotEmpty ? sortedOctaves.first : 3;
        final rootNote = Note.fromString('${config.root}$referenceOctave');
        final extendedInterval = midi - rootNote.midi;

        // Only show intervals that are actually selected
        if (config.selectedIntervals.contains(extendedInterval)) {
          isRoot = extendedInterval == 0;
          displayText = FretboardController.getIntervalLabel(extendedInterval);
        } else {
          // This shouldn't happen if highlight map is correct, but fallback to simple interval
          final notePc = midi % 12;
          final intervalFromRoot = (notePc - rootPc + 12) % 12;
          isRoot = intervalFromRoot == 0;
          displayText = FretboardController.getIntervalLabel(intervalFromRoot);
        }
      } else if (config.isScaleMode) {
        // For scale mode, calculate interval within the musical octave
        final scale = Scale.get(config.scale);
        if (scale != null) {
          // Get the effective root considering the mode
          final effectiveRoot = MusicController.getModeRoot(
              config.root, config.scale, config.modeIndex);
          final effectiveRootNote = Note.fromString('${effectiveRoot}0');

          // Find the root note in the same or lower octave as the current note
          final note = Note.fromMidi(midi);
          final noteOctave = note.octave;

          // Start with the root in the note's octave
          var octaveRoot = Note.fromString('${effectiveRoot}$noteOctave');

          // If the note's pitch class is lower than the root's pitch class,
          // it belongs to the previous octave's scale
          if (note.pitchClass < effectiveRootNote.pitchClass) {
            octaveRoot = Note.fromString('${effectiveRoot}${noteOctave - 1}');
          }

          // Calculate the interval from the musical octave root
          final interval = midi - octaveRoot.midi;

          // Only show notes within the musical octave (0-12 semitones from root)
          if (interval >= 0 && interval <= 12) {
            isRoot = interval == 0 || interval == 12;
            displayText = FretboardController.getIntervalLabel(interval);
          } else {
            // This note is outside the musical octave, don't draw it
            return; // Skip drawing this marker
          }
        } else {
          // Fallback if scale not found
          final notePc = midi % 12;
          final intervalFromRoot = (notePc - rootPc + 12) % 12;
          isRoot = intervalFromRoot == 0;
          displayText = FretboardController.getIntervalLabel(intervalFromRoot);
        }
      } else {
        // For other modes, use simple interval
        final notePc = midi % 12;
        final intervalFromRoot = (notePc - rootPc + 12) % 12;
        isRoot = intervalFromRoot == 0;
        displayText = FretboardController.getIntervalLabel(intervalFromRoot);
      }
    }

    final textStyle = TextStyle(
      fontSize: UIConstants.intervalLabelFontSize,
      fontWeight: isRoot ? FontWeight.w800 : FontWeight.w600,
      color: ColorUtils.getContrastingTextColor(markerColor),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: displayText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant FretboardPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.highlightMap != highlightMap;
  }
}
