// lib/views/widgets/fretboard/fretboard_painter.dart - Dark theme fixes
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
import 'dart:math' as math;

class FretboardPainter extends CustomPainter {
  final FretboardConfig config;
  final Map<int, Color> highlightMap;
  final double screenWidth;
  final bool isDarkMode; // ADDED: Theme information

  FretboardPainter({
    required this.config,
    required this.highlightMap,
    required this.screenWidth,
    required this.isDarkMode, // ADDED: Theme parameter
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

    // Use responsive string height
    final stringHeight = ResponsiveConstants.getStringHeight(screenWidth);
    final boardHeight = (config.stringCount + 1) * stringHeight;

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
        boardHeight, correctedFretCount, stringHeight);
    _drawStrings(
        canvas, size, canvasWidth, headWidth, boardHeight, stringHeight);
    _drawFretMarkers(canvas, size, canvasWidth, headWidth, fretWidth,
        boardHeight, correctedFretCount, stringHeight);

    canvas.restore();
  }

  /// Calculate responsive font size for note labels based on available space
  double _calculateNoteLabelFontSize(double fretWidth, double canvasWidth) {
    // Use responsive base font size
    final baseFontSize = ResponsiveConstants.getScaledFontSize(
        UIConstants.intervalLabelFontSize, canvasWidth);

    // Desktop threshold - above this width, use full size
    const desktopThreshold = UIConstants.tabletBreakpoint;

    if (canvasWidth >= desktopThreshold) {
      // Desktop: use full size
      return baseFontSize;
    }

    // Mobile/tablet: scale based on available space
    // Minimum comfortable fret width for full-size labels
    const comfortableFretWidth = 45.0; // More generous threshold

    if (fretWidth >= comfortableFretWidth) {
      return baseFontSize;
    }

    // Scale down font size when frets get cramped
    // Minimum font size to maintain readability
    const minFontSize = 10.0; // Increased minimum size for mobile

    // Calculate scale factor based on fret width - more generous range
    final scaleFactor = (fretWidth / comfortableFretWidth).clamp(0.7, 1.0);

    // Also consider overall canvas width - more generous
    final widthFactor = (canvasWidth / desktopThreshold).clamp(0.8, 1.0);

    // Use the more restrictive factor
    final finalFactor = math.min(scaleFactor, widthFactor);

    return (baseFontSize * finalFactor).clamp(minFontSize, baseFontSize);
  }

  /// Calculate responsive note marker radius based on available space
  double _calculateNoteMarkerRadius(double fretWidth, double canvasWidth) {
    final baseRadius = ResponsiveConstants.getNoteMarkerRadius(canvasWidth);
    const desktopThreshold = UIConstants.tabletBreakpoint;

    if (canvasWidth >= desktopThreshold) {
      return baseRadius;
    }

    const comfortableFretWidth = 45.0; // More generous threshold
    const minRadius = 10.0; // Larger minimum radius

    if (fretWidth >= comfortableFretWidth) {
      return baseRadius;
    }

    final scaleFactor = (fretWidth / comfortableFretWidth)
        .clamp(0.7, 1.0); // More generous scaling
    final widthFactor = (canvasWidth / desktopThreshold)
        .clamp(0.8, 1.0); // More generous width factor
    final finalFactor = math.min(scaleFactor, widthFactor);

    return (baseRadius * finalFactor).clamp(minRadius, baseRadius);
  }

  double _drawChordName(
      Canvas canvas, Size size, double headWidth, bool hasHeadstock) {
    final chordName = MusicController.getChordDisplayName(
      config.root,
      config.chordType,
      config.chordInversion,
    );

    // Use responsive font size for chord name
    final fontSize = ResponsiveConstants.getScaledFontSize(18.0, screenWidth);

    final chordPainter = TextPainter(
      text: TextSpan(
        text: chordName,
        style: TextStyle(
          fontSize: fontSize,
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
    double stringHeight,
  ) {
    final fretPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = UIConstants.baseFretWidth;

    final nutPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = UIConstants.baseNutWidth;

    final edgePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = UIConstants.baseEdgeWidth;

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
        _drawFretNumber(canvas, f, startX + (f - 0.5) * fretWidth, canvasWidth);
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
          _drawFretNumber(
              canvas, actualFret, startX + (f + 0.5) * fretWidth, canvasWidth);
        }
      }
    }
  }

  void _drawFretNumber(
      Canvas canvas, int fretNumber, double centerX, double canvasWidth) {
    // Use responsive font size for fret numbers
    final fontSize = ResponsiveConstants.getScaledFontSize(12.0, canvasWidth);

    // FIXED: Use passed theme information instead of platform dispatcher
    final fretNumberColor = isDarkMode ? Colors.grey.shade200 : Colors.black;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$fretNumber',
        style: TextStyle(fontSize: fontSize, color: fretNumberColor),
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
    double stringHeight,
  ) {
    final stringPaint = Paint()..strokeWidth = 2;

    final stringOrder = config.isBassTop
        ? List.generate(config.stringCount, (i) => i)
        : List.generate(config.stringCount, (i) => config.stringCount - 1 - i);

    for (final stringIndex in stringOrder) {
      final row = stringOrder.indexOf(stringIndex);
      final y = (row + 1) * stringHeight; // Use responsive string height

      stringPaint.color = UIConstants
          .stringColors[stringIndex % UIConstants.stringColors.length];

      double startX = config.visibleFretStart == 0 ? headWidth : 0;
      canvas.drawLine(Offset(startX, y), Offset(size.width, y), stringPaint);

      // Draw tuning labels if headstock is visible
      if (config.visibleFretStart == 0) {
        final tuningLabel = config.tuning[stringIndex];

        // Use responsive font size for tuning labels
        final fontSize = ResponsiveConstants.getScaledFontSize(14.0, canvasWidth);

        // FIXED: Use passed theme information instead of platform dispatcher
        final tuningLabelColor = isDarkMode ? Colors.white : Colors.black;

        final textPainter = TextPainter(
          text: TextSpan(
            text: tuningLabel,
            style: TextStyle(
              fontSize: fontSize,
              color: tuningLabelColor,
            ),
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
    double stringHeight,
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
      final y = (row + 1) * stringHeight; // Use responsive string height
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
            fretWidth,
            canvasWidth,
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
              fretWidth,
              canvasWidth,
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
              fretWidth,
              canvasWidth,
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
    double fretWidth,
    double canvasWidth,
  ) {
    // Calculate responsive sizes
    final markerRadius = _calculateNoteMarkerRadius(fretWidth, canvasWidth);
    final fontSize = _calculateNoteLabelFontSize(fretWidth, canvasWidth);

    // Ensure marker doesn't extend beyond canvas bounds
    final safeRadius = math.min(markerRadius, math.min(cx, canvasWidth - cx));
    final finalRadius = math.max(safeRadius, 8.0); // Minimum readable size

    // Draw colored circle
    canvas.drawCircle(
      Offset(cx, cy),
      finalRadius,
      Paint()..color = markerColor,
    );

    // Draw border with responsive stroke width
    final strokeWidth = (UIConstants.noteMarkerStrokeWidth *
            (finalRadius / UIConstants.baseNoteMarkerRadius))
        .clamp(1.0, 3.0);

    canvas.drawCircle(
      Offset(cx, cy),
      finalRadius,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
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
      fontSize: fontSize,
      fontWeight: isRoot ? FontWeight.w800 : FontWeight.w600,
      color: ColorUtils.getContrastingTextColor(markerColor),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: displayText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Ensure text fits within the marker and canvas bounds
    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    // Check if text fits within marker
    if (textWidth <= finalRadius * 1.6 && textHeight <= finalRadius * 1.6) {
      // Text fits, center it
      final textX = cx - textWidth / 2;
      final textY = cy - textHeight / 2;

      // FIXED: Adjust vertical positioning for flat symbols
      final adjustedTextY = displayText.contains('♭') ? textY - 0.5 : textY;

      // Ensure text doesn't go outside canvas bounds
      final safeTextX = textX.clamp(0, canvasWidth - textWidth).toDouble();
      final safeTextY = math.max(adjustedTextY, 0).toDouble();

      textPainter.paint(canvas, Offset(safeTextX, safeTextY));
    } else {
      // Text is too large, use a smaller font or abbreviate
      final shortenedText =
          displayText.length > 2 ? displayText.substring(0, 2) : displayText;
      final smallerFontSize = fontSize * 0.8;

      final smallerTextPainter = TextPainter(
        text: TextSpan(
          text: shortenedText,
          style: textStyle.copyWith(fontSize: smallerFontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final smallerTextWidth = smallerTextPainter.width;
      final smallerTextHeight = smallerTextPainter.height;

      final textX = cx - smallerTextWidth / 2;
      final textY = cy - smallerTextHeight / 2;

      // FIXED: Adjust vertical positioning for flat symbols in abbreviated text too
      final adjustedTextY = shortenedText.contains('♭') ? textY - 0.5 : textY;

      // Ensure text doesn't go outside canvas bounds
      final safeTextX =
          textX.clamp(0, canvasWidth - smallerTextWidth).toDouble();
      final safeTextY = math.max(adjustedTextY, 0).toDouble();

      smallerTextPainter.paint(canvas, Offset(safeTextX, safeTextY));
    }
  }

  @override
  bool shouldRepaint(covariant FretboardPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.highlightMap != highlightMap ||
        oldDelegate.screenWidth != screenWidth ||
        oldDelegate.isDarkMode != isDarkMode; // ADDED: Theme check
  }
}