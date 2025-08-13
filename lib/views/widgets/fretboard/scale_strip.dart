// lib/views/widgets/fretboard/scale_strip.dart - Complete fixed version
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
    final screenWidth = MediaQuery.of(context).size.width;

    // SMART OCTAVE DETECTION: For chord modes, show octaves based on actual highlighted notes
    Set<int> displayOctaves;

    if (config.isAnyChordMode) {
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
          displayOctaves = scaleStripOctaves;
          debugPrint(
              'Scale strip: chord mode using scale strip octaves relative to ${config.root}$baseOctave: $displayOctaves (octave-only strips filtered out)');
        } else {
          // Fallback to user selection if no highlights found
          displayOctaves =
              config.selectedOctaves.isEmpty ? {3} : config.selectedOctaves;
          debugPrint(
              'Scale strip: chord mode fallback to user octaves: $displayOctaves');
        }
      } else {
        // No highlights - use user selection
        displayOctaves =
            config.selectedOctaves.isEmpty ? {3} : config.selectedOctaves;
        debugPrint(
            'Scale strip: chord mode no highlights, using user octaves: $displayOctaves');
      }
    } else {
      // For non-chord modes, always use user-selected octaves
      displayOctaves =
          config.selectedOctaves.isEmpty ? {3} : config.selectedOctaves;
      debugPrint(
          'Scale strip: non-chord mode using user octaves: $displayOctaves');
    }

    int actualOctaveCount = displayOctaves.length;

    // Determine number of note positions based on showOctave setting
    final notePositions = config.showOctave ? 13 : 12; // 13 includes octave, 12 excludes it
    
    // Use responsive height calculation
    final noteRowHeight = ResponsiveConstants.getNoteRowHeight(screenWidth);
    final paddingPerOctave =
        ResponsiveConstants.getScaleStripPaddingPerOctave(screenWidth);

    final totalHeight = (actualOctaveCount * noteRowHeight) +
        (actualOctaveCount * paddingPerOctave);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure minimum width for mobile usability
        final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
        final minNoteWidth = deviceType == DeviceType.mobile ? 35.0 : 45.0;
        final minRequiredWidth = notePositions * minNoteWidth;

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
              displayOctaves:
                  displayOctaves, // Now filters out octave-only strips
              highlightMap: FretboardController.getHighlightMap(config),
              screenWidth: screenWidth,
              notePositions: notePositions, // Pass the calculated note positions
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _handleTap(context, details, displayOctaves, screenWidth, notePositions),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, TapDownDetails details,
      Set<int> displayOctaves, double screenWidth, int notePositions) {
    if (onNoteTap == null) return;

    final box = context.findRenderObject() as RenderBox;
    final noteWidth = box.size.width / notePositions.toDouble();
    final noteIndex =
        (details.localPosition.dx / noteWidth).clamp(0, notePositions - 1).floor();

    // Use responsive row height for calculations
    final clickY = details.localPosition.dy;
    final rowHeight = ResponsiveConstants.getNoteRowHeight(screenWidth);
    final octaveRowIndex = (clickY / rowHeight).floor();

    final sortedOctaves = displayOctaves.toList()..sort();

    // Bounds checking for mobile
    if (octaveRowIndex >= 0 && octaveRowIndex < sortedOctaves.length) {
      final clickedOctave = sortedOctaves[octaveRowIndex];

      if (config.isIntervalMode) {
        // Interval mode logic
        final referenceOctave = sortedOctaves.first;

        // Calculate the extended interval based on the click position
        int extendedInterval;
        if (noteIndex == notePositions - 1 && notePositions == 13) {
          // Special handling for the 13th position (octave) when showOctave is true
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
  final double screenWidth;
  final int notePositions;

  ScaleStripPainter({
    required this.config,
    required this.displayOctaves,
    required this.highlightMap,
    required this.screenWidth,
    required this.notePositions,
  });

  /// Calculate responsive font size for scale strip notes
  double _calculateScaleStripFontSize(double noteWidth, double canvasWidth) {
    final baseFontSize =
        ResponsiveConstants.getScaledFontSize(11.0, canvasWidth);
    const desktopThreshold = UIConstants.tabletBreakpoint;

    if (canvasWidth >= desktopThreshold) {
      return baseFontSize;
    }

    // On mobile, scale based on available note width
    const comfortableNoteWidth = 40.0; // More generous threshold for mobile

    if (noteWidth >= comfortableNoteWidth) {
      return baseFontSize;
    }

    // Scale down when notes get cramped
    const minFontSize = 8.5; // Slightly larger minimum for readability
    final scaleFactor = (noteWidth / comfortableNoteWidth)
        .clamp(0.75, 1.0); // More generous scaling
    final widthFactor = (canvasWidth / desktopThreshold)
        .clamp(0.8, 1.0); // More generous width factor
    final finalFactor = math.min(scaleFactor, widthFactor);

    return (baseFontSize * finalFactor).clamp(minFontSize, baseFontSize);
  }

  /// Calculate responsive interval label font size
  double _calculateIntervalLabelFontSize(double noteWidth, double canvasWidth) {
    final baseFontSize =
        ResponsiveConstants.getScaledFontSize(10.0, canvasWidth);
    const desktopThreshold = UIConstants.tabletBreakpoint;

    if (canvasWidth >= desktopThreshold) {
      return baseFontSize;
    }

    const comfortableNoteWidth = 40.0; // More generous threshold

    if (noteWidth >= comfortableNoteWidth) {
      return baseFontSize;
    }

    const minFontSize = 8.0; // Larger minimum
    final scaleFactor = (noteWidth / comfortableNoteWidth)
        .clamp(0.75, 1.0); // More generous scaling
    final widthFactor = (canvasWidth / desktopThreshold)
        .clamp(0.8, 1.0); // More generous width factor
    final finalFactor = math.min(scaleFactor, widthFactor);

    return (baseFontSize * finalFactor).clamp(minFontSize, baseFontSize);
  }

  /// Calculate responsive note circle radius
  double _calculateNoteRadius(double noteWidth, double canvasWidth) {
    final baseRadius = ResponsiveConstants.getScaleStripNoteRadius(canvasWidth);
    const desktopThreshold = UIConstants.tabletBreakpoint;

    if (canvasWidth >= desktopThreshold) {
      return baseRadius;
    }

    const comfortableNoteWidth = 40.0; // More generous threshold
    const minRadius = 10.0; // Larger minimum radius for touch targets

    if (noteWidth >= comfortableNoteWidth) {
      return baseRadius;
    }

    final scaleFactor = (noteWidth / comfortableNoteWidth)
        .clamp(0.75, 1.0); // More generous scaling
    final widthFactor = (canvasWidth / desktopThreshold)
        .clamp(0.8, 1.0); // More generous width factor
    final finalFactor = math.min(scaleFactor, widthFactor);

    return (baseRadius * finalFactor).clamp(minRadius, baseRadius);
  }

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
    final noteWidth = size.width / notePositions.toDouble();

    // Use responsive row height
    final noteRowHeight = ResponsiveConstants.getNoteRowHeight(screenWidth);

    // Draw each octave row
    for (int i = 0; i < sortedOctaves.length; i++) {
      final octave = sortedOctaves[i];
      final rowY = i * noteRowHeight;

      try {
        _drawOctaveRow(
          canvas,
          size,
          octave,
          rowY,
          chromaticSequence,
          rootNote.pitchClass,
          config.isChordMode,
          noteWidth,
          notePositions,
        );
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
    double noteWidth,
    int notePositions,
  ) {
    // Use responsive spacing for mobile optimization
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final verticalOffset =
        deviceType == DeviceType.mobile ? 35.0 : 45.0; // Reduced for mobile
    final intervalOffset = deviceType == DeviceType.mobile
        ? 8.0
        : 10.0; // Moved up more to prevent overlap

    for (int pc = 0; pc < notePositions; pc++) {
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
      Color noteColor = _getUnhighlightedColor(); // FIXED: Theme-aware color
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
          // Get interval from the user's selected octave, not calculated octave
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

      // Draw note circle with responsive sizing and bounds checking
      _drawNoteCircle(canvas, cx, rowY + verticalOffset, noteColor,
          isHighlighted, noteWidth, size.width);

      // Draw interval label with responsive sizing and bounds checking
      _drawIntervalLabel(
        canvas,
        cx,
        rowY + intervalOffset,
        actualPc,
        rootPc,
        octave,
        isHighlighted,
        config.isChordMode,
        intervalForColor,
        midi,
        noteWidth,
        size.width,
      );

      // Draw note name with responsive sizing and bounds checking
      _drawNoteName(
        canvas,
        cx,
        rowY + verticalOffset,
        chromaticSequence[pc % 12],
        noteOctave,
        noteColor,
        isHighlighted,
        noteWidth,
        size.width,
      );
    }
  }

  // FIXED: Theme-aware color for unhighlighted notes
  Color _getUnhighlightedColor() {
    // Use theme-appropriate colors: white for light theme, gray for dark theme
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    return isDarkMode ? Colors.grey.shade600 : Colors.white;
  }

  void _drawNoteCircle(Canvas canvas, double cx, double cy, Color color,
      bool isHighlighted, double noteWidth, double canvasWidth) {
    final radius = _calculateNoteRadius(noteWidth, canvasWidth);

    // Ensure circle doesn't extend beyond canvas bounds
    final safeCx = cx.clamp(radius, canvasWidth - radius);
    final safeRadius = math.min(radius, math.min(safeCx, canvasWidth - safeCx));
    final finalRadius = math.max(safeRadius, 8.0); // Minimum touch target

    canvas.drawCircle(
      Offset(safeCx, cy),
      finalRadius,
      Paint()..color = color,
    );

    // Draw borders based on highlight state and theme
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    if (isHighlighted) {
      // Subtle border for highlighted notes
      final strokeWidth =
          (finalRadius / UIConstants.baseScaleStripNoteRadius).clamp(1.0, 2.0);

      canvas.drawCircle(
        Offset(safeCx, cy),
        finalRadius,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    } else if (!isDarkMode) {
      // Light theme: add subtle border for unhighlighted white notes for visibility
      final strokeWidth =
          (finalRadius / UIConstants.baseScaleStripNoteRadius).clamp(0.5, 1.0);

      canvas.drawCircle(
        Offset(safeCx, cy),
        finalRadius,
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
    // Dark theme unhighlighted notes: no border (indistinguishable from background)
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
    double noteWidth,
    double canvasWidth,
  ) {
    String intervalLabel;

    if (isHighlighted) {
      if (config.isScaleMode) {
        // For scale mode, use the calculated interval
        intervalLabel = FretboardController.getIntervalLabel(intervalForScale);
      } else if (config.isChordMode) {
        // For chord mode, calculate from user's selected octave
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

    final fontSize = _calculateIntervalLabelFontSize(noteWidth, canvasWidth);

    // FIXED: Theme-aware text colors
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    final textColor = isHighlighted
        ? Colors.black
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600);

    final intervalPainter = TextPainter(
      text: TextSpan(
        text: intervalLabel,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // FIXED: Adjust vertical positioning for flat symbols
    double adjustedCy = cy;
    if (intervalLabel.contains('♭')) {
      // Flat symbols have different baseline characteristics, adjust upward more
      adjustedCy = cy - 4.0;
    }

    // Ensure text doesn't extend beyond canvas bounds
    final textWidth = intervalPainter.width;
    final safeX =
        (cx - textWidth / 2).clamp(0, canvasWidth - textWidth).toDouble();
    final intervalOffset = Offset(safeX, adjustedCy);

    // FIXED: Improved background for highlighted intervals - less harsh in dark theme
    if (isHighlighted) {
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          intervalOffset.dx - 2,
          intervalOffset.dy - 1,
          textWidth + 4,
          intervalPainter.height + 2,
        ),
        const Radius.circular(2),
      );
      // Use a more subtle background color
      canvas.drawRRect(bgRect, Paint()..color = Colors.white.withOpacity(0.7));
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
    double noteWidth,
    double canvasWidth,
  ) {
    // Always show note name with octave number
    final noteNameWithOctave = '$noteName$octave';

    final fontSize = _calculateScaleStripFontSize(noteWidth, canvasWidth);

    final notePainter = TextPainter(
      text: TextSpan(
        text: noteNameWithOctave,
        style: TextStyle(
          fontSize: fontSize,
          color: ColorUtils.getContrastingTextColor(noteColor),
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Ensure text doesn't extend beyond canvas bounds
    final textWidth = notePainter.width;
    final textHeight = notePainter.height;
    final safeX =
        (cx - textWidth / 2).clamp(0, canvasWidth - textWidth).toDouble();
    final safeY = math.max(cy - textHeight / 2, 0).toDouble();

    notePainter.paint(canvas, Offset(safeX, safeY));
  }

  @override
  bool shouldRepaint(covariant ScaleStripPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.displayOctaves != displayOctaves ||
        oldDelegate.highlightMap != highlightMap ||
        oldDelegate.screenWidth != screenWidth ||
        oldDelegate.notePositions != notePositions;
  }
}
