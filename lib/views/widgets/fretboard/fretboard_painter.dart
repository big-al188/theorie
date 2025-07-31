// lib/views/widgets/fretboard/fretboard_painter.dart - Updated with additional octaves support (FIXED)
import 'package:flutter/material.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../models/fretboard/highlight_info.dart'; // NEW: Import highlight types
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
  final bool isDarkMode;

  FretboardPainter({
    required this.config,
    required this.highlightMap,
    required this.screenWidth,
    required this.isDarkMode,
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
    
    // NEW: Use combined highlighting system if additional octaves are enabled
    if (config.showAdditionalOctaves && config.viewMode == ViewMode.chordInversions) {
      final combinedHighlights = FretboardController.getCombinedHighlightMap(config);
      _drawFretMarkersWithCombinedHighlights(canvas, size, canvasWidth, headWidth, 
          fretWidth, boardHeight, correctedFretCount, stringHeight, combinedHighlights);
    } else {
      // Use existing highlighting system
      _drawFretMarkers(canvas, size, canvasWidth, headWidth, fretWidth,
          boardHeight, correctedFretCount, stringHeight);
    }

    canvas.restore();
  }

  /// Calculate responsive font size for note labels based on available space
  double _calculateNoteLabelFontSize(double fretWidth, double canvasWidth) {
    // Use responsive base font size - FIXED: Use correct constant
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

  /// Calculate responsive radius for note markers
  double _calculateNoteMarkerRadius(double fretWidth, double canvasWidth) {
    // FIXED: Use original sizing logic
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

  /// Draw chord name at the top of the fretboard
  double _drawChordName(Canvas canvas, Size size, double headWidth, bool hasHeadstock) {
    final chordName = config.currentChordName;
    if (chordName.isEmpty) return 0;

    // Use responsive font size for chord name
    final fontSize = ResponsiveConstants.getScaledFontSize(16.0, size.width);

    final chordPainter = TextPainter(
      text: TextSpan(
        text: chordName,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

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

  /// EXISTING: Draw fret markers with original highlighting system
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

    for (final stringIndex in stringOrder) {
      final row = stringOrder.indexOf(stringIndex);
      final y = (row + 1) * stringHeight;
      final openNote = Note.fromString(config.tuning[stringIndex]);

      if (stringIndex < config.tuning.length) {
        for (int f = 0; f < correctedFretCount; f++) {
          final actualFret = config.visibleFretStart + f;
          final frettedNote = openNote.transpose(actualFret);

          if (highlightMap.containsKey(frettedNote.midi)) {
            // FIXED: Calculate correct x position based on fret and headstock presence
            double noteX;
            if (config.visibleFretStart == 0) {
              // With headstock: fret 0 is in headstock area, fret 1+ are after headstock
              if (actualFret == 0) {
                noteX = headWidth / 2; // Center in headstock area
              } else {
                noteX = headWidth + (actualFret - 0.5) * fretWidth; // Fret positions after headstock
              }
            } else {
              // Without headstock: standard positioning
              noteX = (f + 0.5) * fretWidth;
            }

            _drawPrimaryNoteMarker(
              canvas,
              noteX,
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

  /// NEW: Draw fret markers with combined highlighting system (primary + additional octaves)
  void _drawFretMarkersWithCombinedHighlights(
    Canvas canvas,
    Size size,
    double canvasWidth,
    double headWidth,
    double fretWidth,
    double boardHeight,
    int correctedFretCount,
    double stringHeight,
    CombinedHighlightMap combinedHighlights,
  ) {
    final effectiveRoot = config.isChordMode
        ? config.root
        : MusicController.getModeRoot(config.root, config.scale, config.modeIndex);

    final rootNote = Note.fromString('${effectiveRoot}0');
    final useFlats = rootNote.preferFlats;

    final stringOrder = config.isBassTop
        ? List.generate(config.stringCount, (i) => i)
        : List.generate(config.stringCount, (i) => config.stringCount - 1 - i);

    for (final stringIndex in stringOrder) {
      final row = stringOrder.indexOf(stringIndex);
      final y = (row + 1) * stringHeight;
      final openNote = Note.fromString(config.tuning[stringIndex]);

      if (stringIndex < config.tuning.length) {
        for (int f = 0; f < correctedFretCount; f++) {
          final actualFret = config.visibleFretStart + f;
          final frettedNote = openNote.transpose(actualFret);
          final midi = frettedNote.midi;

          // FIXED: Calculate correct x position based on fret and headstock presence
          double noteX;
          if (config.visibleFretStart == 0) {
            // With headstock: fret 0 is in headstock area, fret 1+ are after headstock
            if (actualFret == 0) {
              noteX = headWidth / 2; // Center in headstock area
            } else {
              noteX = headWidth + (actualFret - 0.5) * fretWidth; // Fret positions after headstock
            }
          } else {
            // Without headstock: standard positioning
            noteX = (f + 0.5) * fretWidth;
          }

          // Check primary highlights first (higher priority)
          if (combinedHighlights.primary.containsKey(midi)) {
            _drawPrimaryNoteMarker(
              canvas,
              noteX,
              y,
              midi,
              combinedHighlights.primary[midi]!,
              rootNote.pitchClass,
              useFlats,
              fretWidth,
              canvasWidth,
            );
          } 
          // Then check additional octave highlights
          else if (combinedHighlights.additional.containsKey(midi)) {
            _drawAdditionalOctaveMarker(
              canvas,
              noteX,
              y,
              combinedHighlights.additional[midi]!,
              fretWidth,
              canvasWidth,
            );
          }
        }
      }
    }
  }

  void _drawPrimaryNoteMarker(
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
          int? matchingInterval;
          for (final voicingMidi in voicingMidiNotes) {
            if (voicingMidi == midi) {
              matchingInterval = midi - chordRootNote.midi;
              break;
            }
          }

          if (matchingInterval != null) {
            displayText = FretboardController.getIntervalLabel(matchingInterval);
            isRoot = matchingInterval % 12 == 0;
          } else {
            // Fallback if not found in voicing
            displayText = FretboardController.getIntervalLabel(midi - chordRootNote.midi);
            isRoot = false;
          }
        } else {
          displayText = '?';
          isRoot = false;
        }
      } else {
        // FIXED: For scale and interval modes - use correct reference octave
        Note referenceRootNote;
        
        if (config.isIntervalMode) {
          // For interval mode, use the actual selected octave as reference
          final referenceOctave = config.selectedOctaves.isEmpty 
              ? 3 
              : config.selectedOctaves.reduce((a, b) => a < b ? a : b);
          referenceRootNote = Note.fromString('${config.root}$referenceOctave');
        } else {
          // For scale mode, use octave 0 with effective root
          referenceRootNote = Note.fromString('${config.effectiveRoot}0');
        }
        
        final interval = midi - referenceRootNote.midi;
        displayText = FretboardController.getIntervalLabel(interval);
        isRoot = interval % 12 == 0;
      }
    }

    // Draw text with appropriate styling
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

      // Adjust vertical positioning for flat symbols
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

      // Adjust vertical positioning for flat symbols in abbreviated text too
      final adjustedTextY = shortenedText.contains('♭') ? textY - 0.5 : textY;

      // Ensure text doesn't go outside canvas bounds
      final safeTextX =
          textX.clamp(0, canvasWidth - smallerTextWidth).toDouble();
      final safeTextY = math.max(adjustedTextY, 0).toDouble();

      smallerTextPainter.paint(canvas, Offset(safeTextX, safeTextY));
    }
  }

  /// NEW: Draw white circle with black outline for additional octaves
  void _drawAdditionalOctaveMarker(
    Canvas canvas,
    double cx,
    double cy,
    HighlightInfo highlightInfo,
    double fretWidth,
    double canvasWidth,
  ) {
    // Calculate responsive sizes (same as primary markers)
    final markerRadius = _calculateNoteMarkerRadius(fretWidth, canvasWidth);
    final fontSize = _calculateNoteLabelFontSize(fretWidth, canvasWidth);

    // Ensure marker doesn't extend beyond canvas bounds
    final safeRadius = math.min(markerRadius, math.min(cx, canvasWidth - cx));
    final finalRadius = math.max(safeRadius, 8.0); // Minimum readable size

    // Draw white filled circle
    canvas.drawCircle(
      Offset(cx, cy),
      finalRadius,
      Paint()..color = Colors.white,
    );

    // Draw black outline
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

    // Draw text - respects showNoteNames toggle
    _drawAdditionalOctaveText(
      canvas,
      cx,
      cy,
      highlightInfo,
      fontSize,
      finalRadius,
      canvasWidth,
    );
  }

  /// NEW: Draw text for additional octave markers (respects showNoteNames toggle)
  void _drawAdditionalOctaveText(
    Canvas canvas,
    double cx,
    double cy,
    HighlightInfo highlightInfo,
    double fontSize,
    double finalRadius,
    double canvasWidth,
  ) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: Colors.black, // Always black text on white background
    );

    // Determine what text to display based on showNoteNames toggle
    String displayText;
    if (config.showNoteNames) {
      // Show note name (existing behavior)
      displayText = highlightInfo.noteClass;
    } else {
      // Show interval relative to root
      final rootNote = Note.fromString('${config.root}${config.selectedChordOctave}');
      final interval = highlightInfo.midi - rootNote.midi;
      displayText = FretboardController.getIntervalLabel(interval);
    }

    final textPainter = TextPainter(
      text: TextSpan(text: displayText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Ensure text fits within the marker
    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    if (textWidth <= finalRadius * 1.6 && textHeight <= finalRadius * 1.6) {
      // Text fits, center it
      final textX = cx - textWidth / 2;
      final textY = cy - textHeight / 2;

      // Adjust vertical positioning for flat symbols
      final adjustedTextY = displayText.contains('♭') ? textY - 0.5 : textY;

      // Ensure text doesn't go outside canvas bounds
      final safeTextX = textX.clamp(0, canvasWidth - textWidth).toDouble();
      final safeTextY = math.max(adjustedTextY, 0).toDouble();

      textPainter.paint(canvas, Offset(safeTextX, safeTextY));
    } else {
      // Text too large - use abbreviated version
      final shortenedText = displayText.length > 2 ? displayText.substring(0, 2) : displayText;
      final smallerTextPainter = TextPainter(
        text: TextSpan(
          text: shortenedText,
          style: textStyle.copyWith(fontSize: fontSize * 0.8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textX = cx - smallerTextPainter.width / 2;
      final textY = cy - smallerTextPainter.height / 2;

      final adjustedTextY = shortenedText.contains('♭') ? textY - 0.5 : textY;
      final safeTextX = textX.clamp(0, canvasWidth - smallerTextPainter.width).toDouble();
      final safeTextY = math.max(adjustedTextY, 0).toDouble();

      smallerTextPainter.paint(canvas, Offset(safeTextX, safeTextY));
    }
  }

  @override
  bool shouldRepaint(covariant FretboardPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.highlightMap != highlightMap ||
        oldDelegate.screenWidth != screenWidth ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}