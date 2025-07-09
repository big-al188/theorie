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

  void _handleFretboardTap(BuildContext context, TapDownDetails details,
      double boardHeight, double screenWidth) {
    if (widget.onFretTap == null) return;

    final position = details.localPosition;

    // Account for chord name height if shown
    final chordNameHeight =
        (widget.config.showChordName && widget.config.isChordMode) ? 30.0 : 0.0;

    // Use responsive top padding
    final topPadding = ResponsiveConstants.getFretLabelPadding(screenWidth);
    var adjustedY = position.dy - chordNameHeight - topPadding;

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
    final fretWidth = availableWidth / correctedFretCount;

    // Use responsive string height for calculations
    final stringHeight = ResponsiveConstants.getStringHeight(screenWidth);

    // Determine which string was clicked with proper centering
    // Strings are drawn at positions: stringHeight, 2*stringHeight, 3*stringHeight, etc.
    // Click regions should be centered around these positions
    final visualRow = (adjustedY / stringHeight).floor();

    // Validate string index with bounds checking
    if (visualRow < 0 || visualRow >= widget.config.stringCount) {
      return; // Click outside valid string range
    }

    // Adjust for bass top/bottom
    final actualStringIndex = widget.config.isBassTop
        ? visualRow
        : widget.config.stringCount - 1 - visualRow;

    // Determine which fret was clicked with precise boundaries
    int fretIndex;

    if (widget.config.visibleFretStart == 0) {
      // With headstock visible
      if (adjustedX < headWidth) {
        // Clicked on headstock - open string (fret 0)
        fretIndex = 0;
      } else {
        // Calculate fret from the nut
        final fretPositionFromNut = (adjustedX - headWidth) / fretWidth;
        fretIndex = fretPositionFromNut.floor() + 1;

        // Clamp to valid range
        fretIndex = fretIndex.clamp(1, widget.config.visibleFretEnd);
      }
    } else {
      // No headstock - calculate from visible start
      final fretPositionInView = adjustedX / fretWidth;
      fretIndex = widget.config.visibleFretStart + fretPositionInView.floor();

      // Clamp to valid range
      fretIndex = fretIndex.clamp(
          widget.config.visibleFretStart, widget.config.visibleFretEnd);
    }

    widget.onFretTap!(actualStringIndex, fretIndex);
  }
}