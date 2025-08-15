// lib/views/widgets/keyboard/keyboard_scale_strip.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/keyboard/keyboard_config.dart';
import '../../../models/music/note.dart';
import '../../../constants/ui_constants.dart';
import '../../../controllers/keyboard_controller.dart';
import '../../../controllers/music_controller.dart';
import '../../../utils/color_utils.dart';
import '../../../utils/note_utils.dart';

/// Interactive scale strip for keyboard that shows the chromatic scale with highlighted notes
/// Based on the fretboard scale strip but adapted for keyboard layout
class KeyboardScaleStrip extends StatelessWidget {
  final KeyboardConfig config;
  final Function(int midiNote)? onNoteTap;

  const KeyboardScaleStrip({
    super.key,
    required this.config,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // For keyboard, we typically show one octave starting from the effective root
    final displayOctaves = _calculateDisplayOctaves();
    
    // Show 12 or 13 positions based on showOctave setting
    final notePositions = config.showOctave ? 13 : 12;
    
    // Use responsive height calculation similar to fretboard
    final noteRowHeight = ResponsiveConstants.getNoteRowHeight(screenWidth);
    final paddingPerOctave = ResponsiveConstants.getScaleStripPaddingPerOctave(screenWidth);
    
    final totalHeight = (displayOctaves.length * noteRowHeight) + 
                       (displayOctaves.length * paddingPerOctave);

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
          height: math.min(totalHeight, constraints.maxHeight),
          child: CustomPaint(
            size: Size(actualWidth, math.min(totalHeight, constraints.maxHeight)),
            painter: KeyboardScaleStripPainter(
              config: config,
              displayOctaves: displayOctaves,
              highlightMap: KeyboardController.getHighlightMap(config),
              screenWidth: screenWidth,
              notePositions: notePositions,
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

  Set<int> _calculateDisplayOctaves() {
    // For keyboard, show octaves based on the keyboard range
    // Use the middle octave(s) that represent the keyboard's note range
    if (config.isAnyChordMode) {
      // For chord modes, use the user's selected octaves or default to middle octaves
      return config.selectedOctaves.isNotEmpty ? config.selectedOctaves : {4};
    } else {
      // For scale modes, use the effective octave range
      return config.selectedOctaves.isNotEmpty ? config.selectedOctaves : {4};
    }
  }

  void _handleTap(BuildContext context, TapDownDetails details,
      Set<int> displayOctaves, double screenWidth, int notePositions) {
    if (onNoteTap == null) return;

    final box = context.findRenderObject() as RenderBox;
    final noteWidth = box.size.width / notePositions.toDouble();
    final noteIndex = (details.localPosition.dx / noteWidth).clamp(0, notePositions - 1).floor();

    // Use responsive row height for calculations
    final clickY = details.localPosition.dy;
    final rowHeight = ResponsiveConstants.getNoteRowHeight(screenWidth);
    final octaveRowIndex = (clickY / rowHeight).floor();

    final sortedOctaves = displayOctaves.toList()..sort();

    // Bounds checking
    if (octaveRowIndex >= 0 && octaveRowIndex < sortedOctaves.length) {
      final clickedOctave = sortedOctaves[octaveRowIndex];

      // Calculate the MIDI note based on the keyboard's effective root
      final effectiveRoot = config.isChordMode
          ? config.root
          : MusicController.getModeRoot(config.root, config.scale, config.modeIndex);
      
      final rootNote = Note.fromString('$effectiveRoot$clickedOctave');
      final clickedMidi = rootNote.midi + (noteIndex % 12);

      onNoteTap!(clickedMidi);
    }
  }
}

/// Custom painter for the keyboard scale strip
class KeyboardScaleStripPainter extends CustomPainter {
  final KeyboardConfig config;
  final Set<int> displayOctaves;
  final Map<int, Color> highlightMap;
  final double screenWidth;
  final int notePositions;

  KeyboardScaleStripPainter({
    required this.config,
    required this.displayOctaves,
    required this.highlightMap,
    required this.screenWidth,
    required this.notePositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rootForDisplay = config.isChordMode
        ? config.root
        : MusicController.getModeRoot(config.root, config.scale, config.modeIndex);

    final rootNote = Note.fromString('${rootForDisplay}0');
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
    // Use responsive spacing
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final verticalOffset = deviceType == DeviceType.mobile ? 20.0 : 25.0;
    final intervalOffset = deviceType == DeviceType.mobile ? 5.0 : 8.0;

    for (int pc = 0; pc < notePositions; pc++) {
      final cx = pc * noteWidth + noteWidth / 2;
      if (cx < 0 || cx > size.width) continue;

      final actualPc = (rootPc + (pc % 12)) % 12;
      final noteOctave = octave + ((rootPc + pc) ~/ 12);
      final note = Note(pitchClass: actualPc, octave: noteOctave);
      final midi = note.midi;

      // Determine if highlighted
      bool isHighlighted = false;
      Color noteColor = _getUnhighlightedColor();
      int intervalForColor = pc % 12;

      // Check highlight map
      if (highlightMap.containsKey(midi)) {
        isHighlighted = true;
        noteColor = highlightMap[midi]!;

        if (config.isScaleMode) {
          final effectiveRoot = MusicController.getModeRoot(
              config.root, config.scale, config.modeIndex);
          final octaveRoot = Note.fromString('$effectiveRoot$octave');
          intervalForColor = midi - octaveRoot.midi;
          if (intervalForColor < 0) intervalForColor += 12;
          intervalForColor = intervalForColor % 12;
        } else if (config.isChordMode) {
          final userOctave = displayOctaves.first;
          final chordRootNote = Note.fromString('${config.root}$userOctave');
          final extendedInterval = midi - chordRootNote.midi;
          intervalForColor = extendedInterval % 12;
        }
      }

      // Draw note circle
      _drawNoteCircle(canvas, cx, rowY + verticalOffset, noteColor, isHighlighted, noteWidth, size.width);

      // Draw interval label
      _drawIntervalLabel(
        canvas,
        cx,
        rowY + intervalOffset,
        actualPc,
        rootPc,
        octave,
        isHighlighted,
        intervalForColor,
        midi,
        noteWidth,
        size.width,
      );

      // Draw note name
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

  Color _getUnhighlightedColor() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade600 : Colors.white;
  }

  void _drawNoteCircle(Canvas canvas, double cx, double cy, Color color,
      bool isHighlighted, double noteWidth, double canvasWidth) {
    final baseRadius = ResponsiveConstants.getScaleStripNoteRadius(canvasWidth);
    final minRadius = 8.0;
    final radius = math.max(baseRadius * 0.8, minRadius); // Slightly smaller for keyboard

    final safeCx = cx.clamp(radius, canvasWidth - radius);
    final finalRadius = math.max(radius, minRadius);

    canvas.drawCircle(
      Offset(safeCx, cy),
      finalRadius,
      Paint()..color = color,
    );

    // Draw borders
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    if (isHighlighted) {
      final strokeWidth = (finalRadius / UIConstants.baseScaleStripNoteRadius).clamp(1.0, 2.0);
      canvas.drawCircle(
        Offset(safeCx, cy),
        finalRadius,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    } else if (!isDarkMode) {
      final strokeWidth = (finalRadius / UIConstants.baseScaleStripNoteRadius).clamp(0.5, 1.0);
      canvas.drawCircle(
        Offset(safeCx, cy),
        finalRadius,
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  void _drawIntervalLabel(
    Canvas canvas,
    double cx,
    double cy,
    int notePc,
    int rootPc,
    int octave,
    bool isHighlighted,
    int intervalForScale,
    int midi,
    double noteWidth,
    double canvasWidth,
  ) {
    String intervalLabel;

    if (isHighlighted) {
      if (config.isScaleMode) {
        intervalLabel = KeyboardController.getIntervalLabel(intervalForScale);
      } else if (config.isChordMode) {
        final userOctave = displayOctaves.first;
        final chordRootNote = Note.fromString('${config.root}$userOctave');
        final extendedInterval = midi - chordRootNote.midi;
        intervalLabel = KeyboardController.getIntervalLabel(extendedInterval);
      } else {
        final interval = (notePc - rootPc + 12) % 12;
        intervalLabel = KeyboardController.getIntervalLabel(interval);
      }
    } else {
      final interval = (notePc - rootPc + 12) % 12;
      intervalLabel = KeyboardController.getIntervalLabel(interval);
    }

    final baseFontSize = ResponsiveConstants.getScaledFontSize(9.0, canvasWidth);
    final fontSize = baseFontSize.clamp(7.0, 11.0);

    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
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

    double adjustedCy = cy;
    if (intervalLabel.contains('♭')) {
      adjustedCy = cy - 2.0;
    }

    final textWidth = intervalPainter.width;
    final safeX = (cx - textWidth / 2).clamp(0, canvasWidth - textWidth).toDouble();
    final intervalOffset = Offset(safeX, adjustedCy);

    if (isHighlighted) {
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          intervalOffset.dx - 1,
          intervalOffset.dy - 1,
          textWidth + 2,
          intervalPainter.height + 2,
        ),
        const Radius.circular(2),
      );
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
    final noteNameWithOctave = '$noteName$octave';
    final baseFontSize = ResponsiveConstants.getScaledFontSize(10.0, canvasWidth);
    final fontSize = baseFontSize.clamp(8.0, 12.0);

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

    final textWidth = notePainter.width;
    final textHeight = notePainter.height;
    final safeX = (cx - textWidth / 2).clamp(0, canvasWidth - textWidth).toDouble();
    final safeY = math.max(cy - textHeight / 2, 0).toDouble();

    notePainter.paint(canvas, Offset(safeX, safeY));
  }

  @override
  bool shouldRepaint(covariant KeyboardScaleStripPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.displayOctaves != displayOctaves ||
        oldDelegate.highlightMap != highlightMap ||
        oldDelegate.screenWidth != screenWidth ||
        oldDelegate.notePositions != notePositions;
  }
}