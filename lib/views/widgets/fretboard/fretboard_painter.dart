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
    final correctedFretCount = FretboardController.getCorrectedFretCount(config);
    final canvasWidth = size.width;
    final headWidth = canvasWidth * UIConstants.headWidthRatio;
    final availableWidth = canvasWidth - (config.visibleFretStart == 0 ? headWidth : 0);
    
    // FIXED: Calculate fretWidth to match how fret structure is drawn
    final fretWidth = config.visibleFretStart == 0 
      ? availableWidth / config.visibleFretEnd  // Headstock: fret structure draws 1-12 (12 spaces)
      : availableWidth / correctedFretCount;    // No headstock: use corrected count

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
    if (config.showAdditionalOctaves && 
        (config.viewMode == ViewMode.chordInversions || config.viewMode == ViewMode.openChords)) {
      final combinedHighlights = FretboardController.getCombinedHighlightMap(config);
      _drawFretMarkersWithCombinedHighlights(canvas, size, canvasWidth, headWidth, 
          fretWidth, boardHeight, correctedFretCount, stringHeight, combinedHighlights);
    } else if (config.viewMode == ViewMode.openChords && !config.showAllPositions) {
      // Special case: Open chord mode with "show all positions" disabled
      // Use position-based highlighting instead of MIDI-based
      _drawOpenChordPositionMarkers(canvas, size, canvasWidth, headWidth, 
          fretWidth, boardHeight, correctedFretCount, stringHeight);
    } else {
      // Use existing highlighting system
      _drawFretMarkers(canvas, size, canvasWidth, headWidth, fretWidth,
          boardHeight, correctedFretCount, stringHeight);
    }

    canvas.restore();
  }

  /// Draw markers for open chord mode - position-based, not MIDI-based
  void _drawOpenChordPositionMarkers(
    Canvas canvas,
    Size size,
    double canvasWidth,
    double headWidth,
    double fretWidth,
    double boardHeight,
    int correctedFretCount,
    double stringHeight,
  ) {
    // Get the specific positions for the open chord
    final positions = _getOpenChordPositions();
    if (positions.isEmpty) return;

    debugPrint('Drawing ${positions.length} open chord position markers');

    // Draw each position specifically
    for (final position in positions) {
      final stringIndex = position['stringIndex'] as int;
      final fret = position['fret'] as int;
      final color = position['color'] as Color;
      final note = position['note'] as Note;

      // Calculate exact position on fretboard with proper bass top/bottom handling
      final visualStringIndex = config.isBassTop 
          ? stringIndex 
          : config.stringCount - 1 - stringIndex;
      final y = (visualStringIndex + 1) * stringHeight;
      
      double x;
      if (config.visibleFretStart == 0) {
        // With headstock - fret 0 is at headWidth, fret positions calculated from there
        x = fret == 0 ? headWidth / 2 : headWidth + (fret - 0.5) * fretWidth;
      } else {
        // Without headstock - fret positions start from 0
        x = (fret - config.visibleFretStart + 0.5) * fretWidth;
      }

      // Only draw if position is within visible range
      if (fret >= config.visibleFretStart && fret <= config.visibleFretEnd) {
        _drawPrimaryNoteMarker(
          canvas,
          x,
          y,
          note.midi,
          color,
          Note.fromString('${config.root}0').pitchClass,
          note.preferFlats,
          fretWidth,
          canvasWidth,
        );
        
        debugPrint('Drew position marker at string $stringIndex, fret $fret (${note.name})');
      }
    }
  }

  /// Get the exact positions for open chord (not MIDI-based)
  List<Map<String, dynamic>> _getOpenChordPositions() {
    final positions = <Map<String, dynamic>>[];
    final chord = Chord.get(config.chordType);
    if (chord == null) return positions;

    final rootNote = Note.fromString('${config.root}0');
    
    // Get chord tones as note classes
    final chordTones = <int>{};
    for (final interval in chord.intervals) {
      final chordNote = rootNote.transpose(interval);
      chordTones.add(chordNote.pitchClass);
    }

    // Determine bass note pitch class for the inversion
    final bassNotePitchClass = chord.intervals.length > config.chordInversion.index
        ? rootNote.transpose(chord.intervals[config.chordInversion.index]).pitchClass
        : rootNote.pitchClass;

    // Sort strings by pitch (lowest to highest)
    final stringIndicesWithTuning = <Map<String, dynamic>>[];
    for (int i = 0; i < config.tuning.length; i++) {
      final openNote = Note.fromString(config.tuning[i]);
      stringIndicesWithTuning.add({
        'index': i,
        'openMidi': openNote.midi,
        'openNote': openNote,
      });
    }
    stringIndicesWithTuning.sort((a, b) => a['openMidi'].compareTo(b['openMidi']));

    // Find bass string first
    int? bassStringIndex;
    for (final stringData in stringIndicesWithTuning) {
      final stringIndex = stringData['index'] as int;
      final openNote = stringData['openNote'] as Note;
      
      for (int fret = config.visibleFretStart; fret <= config.visibleFretStart + 4; fret++) {
        final frettedNote = openNote.transpose(fret);
        if (frettedNote.pitchClass == bassNotePitchClass) {
          bassStringIndex = stringIndex;
          
          // Add bass position
          final chordToneIndex = chord.intervals.indexWhere((interval) {
            final chordToneNote = rootNote.transpose(interval);
            return chordToneNote.pitchClass == bassNotePitchClass;
          });
          final color = ColorUtils.colorForDegree(chordToneIndex >= 0 ? chordToneIndex : 0);
          
          positions.add({
            'stringIndex': stringIndex,
            'fret': fret,
            'note': frettedNote,
            'color': color,
          });
          break;
        }
      }
      if (bassStringIndex != null) break;
    }

    if (bassStringIndex == null) return positions;

    // Find chord tones on higher strings
    final bassStringMidi = Note.fromString(config.tuning[bassStringIndex]).midi;
    
    for (final stringData in stringIndicesWithTuning) {
      final stringIndex = stringData['index'] as int;
      final openNote = stringData['openNote'] as Note;
      
      if (openNote.midi <= bassStringMidi) continue;
      
      for (int fret = config.visibleFretStart; fret <= config.visibleFretStart + 4; fret++) {
        final frettedNote = openNote.transpose(fret);
        if (chordTones.contains(frettedNote.pitchClass)) {
          final chordToneIndex = chord.intervals.indexWhere((interval) {
            final chordToneNote = rootNote.transpose(interval);
            return chordToneNote.pitchClass == frettedNote.pitchClass;
          });
          final color = ColorUtils.colorForDegree(chordToneIndex >= 0 ? chordToneIndex : 0);
          
          positions.add({
            'stringIndex': stringIndex,
            'fret': fret,
            'note': frettedNote,
            'color': color,
          });
          break; // Only one per string
        }
      }
    }

    return positions;
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
      for (int f = 0; f < correctedFretCount; f++) {
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

    // OLD (BROKEN) - This causes 12th fret to disappear:
    // final safeRadius = math.min(markerRadius, math.min(cx, canvasWidth - cx));

    // NEW (FIXED) - Allow markers to extend slightly beyond canvas edges:
    // Only reduce radius if marker center is extremely close to edges
    double safeRadius = markerRadius;
    const edgeBuffer = 5.0; // Allow small extension beyond canvas

    // Only clamp radius if marker center is very close to left edge
    if (cx < edgeBuffer) {
      safeRadius = math.min(safeRadius, cx + edgeBuffer);
    }
    // Only clamp radius if marker center is very close to right edge  
    else if (cx > canvasWidth - edgeBuffer) {
      safeRadius = math.min(safeRadius, (canvasWidth - cx) + edgeBuffer);
    }

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
          // FIXED: For scale mode, use the same approach as interval mode
          // Use the user's selected octave as reference, not octave 0
          final referenceOctave = config.selectedOctaves.isEmpty 
              ? 3 
              : config.selectedOctaves.reduce((a, b) => a < b ? a : b);
          referenceRootNote = Note.fromString('${config.effectiveRoot}$referenceOctave');
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
      // FIXED: Text is too large - scale font instead of truncating
      // Try progressively smaller font sizes until text fits
      double scaledFontSize = fontSize;
      TextPainter scaledTextPainter;
      
      do {
        scaledFontSize *= 0.85; // Reduce by 15% each iteration
        scaledTextPainter = TextPainter(
          text: TextSpan(
            text: displayText, // Keep full text, don't truncate
            style: textStyle.copyWith(fontSize: scaledFontSize),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      } while ((scaledTextPainter.width > finalRadius * 1.6 || 
                scaledTextPainter.height > finalRadius * 1.6) && 
              scaledFontSize > fontSize * 0.5); // Don't go below 50% of original

      final textX = cx - scaledTextPainter.width / 2;
      final textY = cy - scaledTextPainter.height / 2;

      // Adjust vertical positioning for flat symbols
      final adjustedTextY = displayText.contains('♭') ? textY - 0.5 : textY;
      
      // Ensure text doesn't go outside canvas bounds
      final safeTextX = textX.clamp(0, canvasWidth - scaledTextPainter.width).toDouble();
      final safeTextY = math.max(adjustedTextY, 0).toDouble();

      scaledTextPainter.paint(canvas, Offset(safeTextX, safeTextY));
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
    // OLD (BROKEN) - This causes 12th fret to disappear:
    // final safeRadius = math.min(markerRadius, math.min(cx, canvasWidth - cx));

    // NEW (FIXED) - Allow markers to extend slightly beyond canvas edges:
    // Only reduce radius if marker center is extremely close to edges
    double safeRadius = markerRadius;
    const edgeBuffer = 5.0; // Allow small extension beyond canvas

    // Only clamp radius if marker center is very close to left edge
    if (cx < edgeBuffer) {
      safeRadius = math.min(safeRadius, cx + edgeBuffer);
    }
    // Only clamp radius if marker center is very close to right edge  
    else if (cx > canvasWidth - edgeBuffer) {
      safeRadius = math.min(safeRadius, (canvasWidth - cx) + edgeBuffer);
    }

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
      // FIXED: Text is too large - scale font instead of truncating
      // Try progressively smaller font sizes until text fits
      double scaledFontSize = fontSize;
      TextPainter scaledTextPainter;
      
      do {
        scaledFontSize *= 0.85; // Reduce by 15% each iteration
        scaledTextPainter = TextPainter(
          text: TextSpan(
            text: displayText, // Keep full text, don't truncate
            style: textStyle.copyWith(fontSize: scaledFontSize),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      } while ((scaledTextPainter.width > finalRadius * 1.6 || 
                scaledTextPainter.height > finalRadius * 1.6) && 
              scaledFontSize > fontSize * 0.5); // Don't go below 50% of original

      final textX = cx - scaledTextPainter.width / 2;
      final textY = cy - scaledTextPainter.height / 2;

      // Adjust vertical positioning for flat symbols
      final adjustedTextY = displayText.contains('♭') ? textY - 0.5 : textY;
      
      // Ensure text doesn't go outside canvas bounds
      final safeTextX = textX.clamp(0, canvasWidth - scaledTextPainter.width).toDouble();
      final safeTextY = math.max(adjustedTextY, 0).toDouble();

      scaledTextPainter.paint(canvas, Offset(safeTextX, safeTextY));
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