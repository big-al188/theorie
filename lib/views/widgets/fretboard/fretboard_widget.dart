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
    final boardHeight = widget.config.showFretboard
        ? (widget.config.stringCount + 1) * UIConstants.stringHeight
        : 0.0;

    // Add space for chord name if needed
    final chordNameHeight =
        (widget.config.showChordName && widget.config.isChordMode) ? 30.0 : 0.0;

    // Calculate scale strip height
    final octaveCount = widget.config.selectedOctaves.isEmpty
        ? 1
        : widget.config.selectedOctaves.length;
    final scaleStripHeight = widget.config.showScaleStrip
        ? _calculateScaleStripHeight(octaveCount)
        : 0.0;

    // Spacing between fretboard and scale strip
    final spacingHeight =
        (widget.config.showFretboard && widget.config.showScaleStrip)
            ? 24.0
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
      ),
    );
  }

  double _calculateScaleStripHeight(int octaveCount) {
    return UIConstants.scaleStripLabelSpace +
        (octaveCount * UIConstants.noteRowHeight) +
        (octaveCount * UIConstants.scaleStripPaddingPerOctave);
  }

  Widget _buildContent(
    BuildContext context,
    double boardHeight,
    double scaleStripHeight,
    double spacingHeight,
  ) {
    if (widget.config.showFretboard && widget.config.showScaleStrip) {
      return _buildWithScaleStrip(
          context, boardHeight, scaleStripHeight, spacingHeight);
    } else if (widget.config.showFretboard && !widget.config.showScaleStrip) {
      return _buildFretboardOnly(context, boardHeight);
    } else if (!widget.config.showFretboard && widget.config.showScaleStrip) {
      return _buildScaleStripOnly(context, scaleStripHeight);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFretboardOnly(BuildContext context, double boardHeight) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) =>
            _handleFretboardTap(context, details, boardHeight),
        onPanUpdate: _handlePan,
        child: Container(
          width: double.infinity,
          height: boardHeight,
          padding: const EdgeInsets.only(top: 20), // Space for fret labels
          child: CustomPaint(
            size: Size(double.infinity, boardHeight),
            painter: FretboardPainter(
              config: widget.config,
              highlightMap: FretboardController.getHighlightMap(widget.config),
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
  ) {
    return Column(
      children: [
        // Fretboard
        Container(
          height: boardHeight,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 20), // Space for fret labels
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _handleFretboardTap(context, details, boardHeight),
              onPanUpdate: _handlePan,
              child: CustomPaint(
                size: Size(double.infinity, boardHeight),
                painter: FretboardPainter(
                  config: widget.config,
                  highlightMap:
                      FretboardController.getHighlightMap(widget.config),
                ),
              ),
            ),
          ),
        ),

        // Spacing
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

  void _handleFretboardTap(
      BuildContext context, TapDownDetails details, double boardHeight) {
    if (widget.onFretTap == null) return;

    final position = details.localPosition;

    // Account for chord name height if shown
    final chordNameHeight =
        (widget.config.showChordName && widget.config.isChordMode) ? 30.0 : 0.0;
    var adjustedY = position.dy - chordNameHeight;

    if (widget.config.isLeftHanded) {
      // Handle left-handed transformation
      // Implementation depends on how left-handed is rendered
    }

    final renderBox = context.findRenderObject() as RenderBox;
    final width = renderBox.size.width;
    final headWidth = width * UIConstants.headWidthRatio;
    final availableWidth =
        width - (widget.config.visibleFretStart == 0 ? headWidth : 0);
    final correctedFretCount =
        FretboardController.getCorrectedFretCount(widget.config);
    final fretWidth = availableWidth / correctedFretCount;

    final localDy =
        widget.config.isBassTop ? adjustedY : boardHeight - adjustedY;

    final stringIndex = _hitTestString(localDy, widget.config.stringCount);
    if (stringIndex == null) return;

    // Calculate fret index
    double startX = widget.config.visibleFretStart == 0 ? headWidth : 0;
    final fretIndex = ((position.dx - startX) / fretWidth)
        .floor()
        .clamp(0, correctedFretCount - 1);
    final actualFret = widget.config.visibleFretStart + fretIndex;

    widget.onFretTap!(stringIndex, actualFret);
  }

  int? _hitTestString(double dy, int stringCount) {
    for (int i = 0; i < stringCount; i++) {
      final stringY = (i + 1) * UIConstants.stringHeight;
      if ((dy - stringY).abs() <= UIConstants.stringHeight / 2) {
        return i;
      }
    }
    return null;
  }
}
