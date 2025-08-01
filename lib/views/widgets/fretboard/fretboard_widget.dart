// lib/views/widgets/fretboard/fretboard_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../models/music/note.dart';
import '../../../constants/ui_constants.dart';
import '../../../controllers/fretboard_controller.dart';
import 'fretboard_painter.dart';
import 'scale_strip.dart';

class FretboardWidget extends StatefulWidget {
  final FretboardConfig config;
  final Function(int stringIndex, int fretIndex)? onFretTap;
  final Function(int midiNote)? onScaleNoteTap;
  final Function(int start, int end)? onRangeChanged;

  const FretboardWidget({
    super.key,
    required this.config,
    this.onFretTap,
    this.onScaleNoteTap,
    this.onRangeChanged,
  });

  @override
  State<FretboardWidget> createState() => _FretboardWidgetState();
}

class _FretboardWidgetState extends State<FretboardWidget> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Use responsive string height
    final stringHeight = ResponsiveConstants.getStringHeight(screenWidth);
    final boardHeight = widget.config.showFretboard
        ? (widget.config.stringCount + 1) * stringHeight
        : 0.0;

    // Add space for chord name if needed
    final chordNameHeight =
        (widget.config.showChordName && widget.config.isChordMode) ? 30.0 : 0.0;

    // Calculate scale strip height using responsive values
    final octaveCount = widget.config.selectedOctaves.isEmpty
        ? 1
        : widget.config.selectedOctaves.length;
    final scaleStripHeight = widget.config.showScaleStrip
        ? _calculateScaleStripHeight(octaveCount, screenWidth)
        : 0.0;

    // Use responsive spacing between fretboard and scale strip
    final spacingHeight =
        (widget.config.showFretboard && widget.config.showScaleStrip)
            ? ResponsiveConstants.getFretboardScaleStripSpacing(screenWidth)
            : 0.0;

    final totalHeight =
        chordNameHeight + boardHeight + spacingHeight + scaleStripHeight;

    return Container(
      width: widget.config.width,
      height: widget.config.height ?? totalHeight,
      padding: widget.config.padding,
      child: _buildContent(
        context,
        boardHeight + chordNameHeight,
        scaleStripHeight,
        spacingHeight,
        screenWidth,
      ),
    );
  }

  // Updated to use responsive values
  double _calculateScaleStripHeight(int octaveCount, double screenWidth) {
    final noteRowHeight = ResponsiveConstants.getNoteRowHeight(screenWidth);
    final paddingPerOctave =
        ResponsiveConstants.getScaleStripPaddingPerOctave(screenWidth);

    return UIConstants.scaleStripLabelSpace +
        (octaveCount * noteRowHeight) +
        (octaveCount * paddingPerOctave);
  }

  Widget _buildContent(
    BuildContext context,
    double boardHeight,
    double scaleStripHeight,
    double spacingHeight,
    double screenWidth,
  ) {
    if (widget.config.showFretboard && widget.config.showScaleStrip) {
      return _buildWithScaleStrip(
          context, boardHeight, scaleStripHeight, spacingHeight, screenWidth);
    } else if (widget.config.showFretboard && !widget.config.showScaleStrip) {
      return _buildFretboardOnly(context, boardHeight, screenWidth);
    } else if (!widget.config.showFretboard && widget.config.showScaleStrip) {
      return _buildScaleStripOnly(context, scaleStripHeight);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFretboardOnly(
      BuildContext context, double boardHeight, double screenWidth) {
    // Use responsive top padding for fret labels
    final topPadding = ResponsiveConstants.getFretLabelPadding(screenWidth);
    
    // Get theme information for painter
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) =>
            _handleFretboardTap(context, details, boardHeight, screenWidth),
        onPanUpdate: _handlePan,
        child: Container(
          width: double.infinity,
          height: boardHeight,
          padding: EdgeInsets.only(top: topPadding), // Responsive top padding
          child: CustomPaint(
            size: Size(double.infinity, boardHeight),
            painter: FretboardPainter(
              config: widget.config,
              highlightMap: FretboardController.getHighlightMap(widget.config),
              screenWidth: screenWidth, // Pass screen width to painter
              isDarkMode: isDarkMode, // FIXED: Pass theme information
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaleStripOnly(BuildContext context, double scaleStripHeight) {
    return Container(
      height: scaleStripHeight,
      width: double.infinity,
      child: ScaleStrip(
        config: widget.config,
        onNoteTap: widget.onScaleNoteTap,
      ),
    );
  }

  Widget _buildWithScaleStrip(
    BuildContext context,
    double boardHeight,
    double scaleStripHeight,
    double spacingHeight,
    double screenWidth,
  ) {
    // Use responsive top padding for fret labels
    final topPadding = ResponsiveConstants.getFretLabelPadding(screenWidth);
    
    // Get theme information for painter
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Fretboard
        Container(
          height: boardHeight,
          width: double.infinity,
          padding: EdgeInsets.only(top: topPadding), // Responsive top padding
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handleFretboardTap(
                  context, details, boardHeight, screenWidth),
              onPanUpdate: _handlePan,
              child: CustomPaint(
                size: Size(double.infinity, boardHeight),
                painter: FretboardPainter(
                  config: widget.config,
                  highlightMap:
                      FretboardController.getHighlightMap(widget.config),
                  screenWidth: screenWidth, // Pass screen width to painter
                  isDarkMode: isDarkMode, // FIXED: Pass theme information
                ),
              ),
            ),
          ),
        ),

        // Responsive spacing
        if (spacingHeight > 0) SizedBox(height: spacingHeight),

        // Scale strip
        Container(
          height: scaleStripHeight,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 4),
          child: ScaleStrip(
            config: widget.config,
            onNoteTap: widget.onScaleNoteTap,
          ),
        ),
      ],
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && widget.onRangeChanged != null) {
      // Check if Ctrl key is pressed for zoom
      final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.controlLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.controlRight);

      if (isCtrlPressed) {
        // Handle horizontal zoom
        _handleZoom(event.scrollDelta.dy < 0);
      } else {
        // Handle horizontal scroll (pan)
        _handleScroll(event.scrollDelta.dy > 0 ? 1 : -1);
      }
    }
  }

  void _handleZoom(bool isZoomIn) {
    final currentRange =
        widget.config.visibleFretEnd - widget.config.visibleFretStart;
    final newRange = isZoomIn
        ? (currentRange - 1).clamp(1, widget.config.fretCount)
        : (currentRange + 1).clamp(1, widget.config.fretCount);

    if (newRange != currentRange) {
      // Maintain center position
      final center =
          (widget.config.visibleFretStart + widget.config.visibleFretEnd) / 2;
      final newStart = (center - newRange / 2)
          .round()
          .clamp(0, widget.config.fretCount - newRange);
      final newEnd = newStart + newRange;

      widget.onRangeChanged?.call(newStart, newEnd);
    }
  }

  void _handleScroll(int direction) {
    final currentRange =
        widget.config.visibleFretEnd - widget.config.visibleFretStart;
    final newStart = (widget.config.visibleFretStart + direction)
        .clamp(0, widget.config.fretCount - currentRange);
    final newEnd = newStart + currentRange;

    if (newStart != widget.config.visibleFretStart) {
      widget.onRangeChanged?.call(newStart, newEnd);
    }
  }

  void _handlePan(DragUpdateDetails details) {
    if (widget.onRangeChanged == null) return;

    final delta = details.delta.dx;
    final currentRange =
        widget.config.visibleFretEnd - widget.config.visibleFretStart;

    // Calculate pan sensitivity
    final panSensitivity = currentRange / 200.0;
    final fretChange = (-delta * panSensitivity).round();

    if (fretChange != 0) {
      final newStart = (widget.config.visibleFretStart + fretChange)
          .clamp(0, widget.config.fretCount - currentRange);
      final newEnd = newStart + currentRange;

      if (newStart != widget.config.visibleFretStart) {
        widget.onRangeChanged?.call(newStart, newEnd);
      }
    }
  }


// Fixed _handleFretboardTap method for fretboard_widget.dart

void _handleFretboardTap(BuildContext context, TapDownDetails details,
      double boardHeight, double screenWidth) {
    if (widget.onFretTap == null) return;

    final position = details.localPosition;

    // FIXED: Calculate exact same offsets as used in painter
    double topOffset = 0;
    
    // Calculate chord name offset exactly as in painter
    if (widget.config.showChordName && widget.config.isChordMode) {
      final chordName = widget.config.currentChordName;
      if (chordName.isNotEmpty) {
        // Use responsive font size for chord name (same as painter)
        final fontSize = ResponsiveConstants.getScaledFontSize(16.0, screenWidth);
        
        // Estimate text height (approximation of what painter calculates)
        final estimatedTextHeight = fontSize * 1.2; // Rough text height
        topOffset = estimatedTextHeight + 10; // Same as painter: height + 10
      }
    }

    // Use responsive top padding (same as widget building)
    final topPadding = ResponsiveConstants.getFretLabelPadding(screenWidth);
    
    // FIXED: Apply same coordinate transformation as painter
    var adjustedY = position.dy - topOffset - topPadding;

    // Handle left-handed transformation
    final adjustedX = widget.config.isLeftHanded
        ? context.size!.width - position.dx
        : position.dx;

    final renderBox = context.findRenderObject() as RenderBox;
    final width = renderBox.size.width;
    final headWidth = width * UIConstants.headWidthRatio;
    final availableWidth =
        width - (widget.config.visibleFretStart == 0 ? headWidth : 0);

    final correctedFretCount =
        FretboardController.getCorrectedFretCount(widget.config);
    final fretWidth = widget.config.visibleFretStart == 0 
        ? availableWidth / widget.config.visibleFretEnd  // 12 spaces for frets 1-12 (headstock)
        : availableWidth / correctedFretCount;           // Use corrected count for zoom

    // Use responsive string height
    final stringHeight = ResponsiveConstants.getStringHeight(screenWidth);

    // HARDCODED FIX: Move hit regions up by half their total height
    // Original hit zones were from (i + 0.5) to (i + 1.5) * stringHeight
    // Moving up by half the zone height (0.5 * stringHeight) gives us:
    // Hit zones from (i * stringHeight) to ((i + 1) * stringHeight)
    
    int row = -1;
    
    // Check each string's hit zone - moved up by half zone height
    for (int i = 0; i < widget.config.stringCount; i++) {
      final hitZoneStart = i * stringHeight;           // Moved up
      final hitZoneEnd = (i + 1) * stringHeight;       // Moved up
      
      if (adjustedY >= hitZoneStart && adjustedY < hitZoneEnd) {
        row = i;
        break;
      }
    }
    
    // Handle edge cases for clicks outside the main hit zones
    if (row == -1) {
      if (adjustedY < 0) {
        // Click above first string - assign to first string
        row = 0;
      } else if (adjustedY >= widget.config.stringCount * stringHeight) {
        // Click below last string - assign to last string  
        row = widget.config.stringCount - 1;
      }
    }

    if (row < 0 || row >= widget.config.stringCount) {
      debugPrint('Tap outside valid string range: row=$row, adjustedY=$adjustedY, stringHeight=$stringHeight');
      return;
    }

    // Map visual row to actual string index using same logic as painter
    final stringIndex = widget.config.isBassTop 
        ? row 
        : (widget.config.stringCount - 1 - row);

    if (stringIndex < 0 || stringIndex >= widget.config.stringCount) {
      debugPrint('Invalid string index: $stringIndex');
      return;
    }

    debugPrint('Tap detected: row=$row, stringIndex=$stringIndex, adjustedY=$adjustedY, hitZoneCenter=${(row + 0.5) * stringHeight}');

    double fretStartX = widget.config.visibleFretStart == 0 ? headWidth : 0;
    final relativeX = adjustedX - fretStartX;

    if (relativeX < 0) {
      // Tapped in headstock area (open string)
      if (widget.config.visibleFretStart == 0) {
        widget.onFretTap!(stringIndex, 0);
      }
    } else {
      // Calculate which fret was tapped
      final fretIndex = (relativeX / fretWidth).floor();

      if (widget.config.visibleFretStart == 0) {
        // Standard mode: fret numbers start from 1
        final actualFret = fretIndex + 1;
        if (actualFret <= widget.config.visibleFretEnd) {
          widget.onFretTap!(stringIndex, actualFret);
        }
      } else {
        // Zoomed mode: calculate actual fret based on visible range
        final actualFret = widget.config.visibleFretStart + fretIndex;
        if (actualFret <= widget.config.visibleFretEnd) {
          widget.onFretTap!(stringIndex, actualFret);
        }
      }
    }
  }
}