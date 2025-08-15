// lib/views/widgets/keyboard/keyboard_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import '../../../models/keyboard/keyboard_config.dart';
import '../../../models/keyboard/key_configuration.dart';
import '../../../controllers/keyboard_controller.dart';
import 'keyboard_painter.dart';
import 'keyboard_scale_strip.dart';

/// Main keyboard widget for rendering and interaction
/// Following the same pattern as FretboardWidget for consistency
class KeyboardWidget extends StatefulWidget {
  final KeyboardConfig config;
  final Function(KeyConfiguration)? onKeyTap;

  const KeyboardWidget({
    super.key,
    required this.config,
    this.onKeyTap,
  });

  @override
  State<KeyboardWidget> createState() => _KeyboardWidgetState();
}

class _KeyboardWidgetState extends State<KeyboardWidget> {
  List<KeyConfiguration> _keyConfigurations = [];

  @override
  void initState() {
    super.initState();
    _updateKeyConfigurations();
  }

  @override
  void didUpdateWidget(KeyboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _updateKeyConfigurations();
    }
  }

  void _updateKeyConfigurations() {
    setState(() {
      _keyConfigurations = KeyboardController.generateKeyConfigurations(widget.config);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Column(
          children: [
            // Chord name display if enabled
            if (widget.config.showChordName && widget.config.isAnyChordMode)
              _buildChordNameSection(),
            
            // Main keyboard
            Expanded(
              flex: widget.config.showScaleStrip ? 4 : 1, // Give more space to keyboard when scale strip is shown
              child: _buildKeyboard(),
            ),
            
            // Scale strip if enabled
            if (widget.config.showScaleStrip)
              Flexible(
                flex: 1, // Allow scale strip to be flexible but limited
                child: _buildScaleStrip(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChordNameSection() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Text(
        widget.config.currentChordName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildKeyboard() {
    return Semantics(
      label: 'Piano keyboard with ${_keyConfigurations.length} keys',
      hint: 'Tap keys to play notes and see music theory',
      child: GestureDetector(
        onTapDown: (TapDownDetails details) => _handleTap(details),
        child: CustomPaint(
          painter: KeyboardPainter(
            keyConfigurations: _keyConfigurations,
            config: widget.config,
            colorScheme: Theme.of(context).colorScheme,
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
          ),
          size: Size(widget.config.width, widget.config.height),
        ),
      ),
    );
  }

  Widget _buildScaleStrip() {
    // Use similar height calculation as fretboard
    final screenWidth = MediaQuery.of(context).size.width;
    final minHeight = 40.0;
    final maxHeight = 60.0;
    final preferredHeight = MediaQuery.of(context).size.height * 0.08; // 8% of screen height
    final scaleStripHeight = preferredHeight.clamp(minHeight, maxHeight);
    
    return Container(
      height: scaleStripHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2.0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: KeyboardScaleStrip(
        config: widget.config,
        onNoteTap: widget.onKeyTap != null 
          ? (midiNote) {
              // Convert MIDI note to KeyConfiguration for consistency
              final keyConfig = _keyConfigurations.firstWhere(
                (key) => key.midiNote == midiNote,
                orElse: () => KeyConfiguration.fromMidiNote(
                  keyIndex: 0,
                  midiNote: midiNote,
                ),
              );
              widget.onKeyTap!(keyConfig);
            }
          : null,
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Find which key was tapped
    final tappedKey = _findKeyAtPosition(localPosition);
    if (tappedKey != null) {
      // Provide haptic feedback for better UX
      HapticFeedback.selectionClick();
      
      // Provide accessibility announcement
      _announceKeyTap(tappedKey);
      
      if (widget.onKeyTap != null) {
        widget.onKeyTap!(tappedKey);
      }
    }
  }
  
  void _announceKeyTap(KeyConfiguration key) {
    final announcement = key.isHighlighted 
        ? '${key.displayName} key, highlighted in scale'
        : '${key.displayName} key';
    
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  KeyConfiguration? _findKeyAtPosition(Offset position) {
    final whiteKeys = _keyConfigurations.where((key) => key.isWhiteKey).toList();
    final whiteKeyWidth = widget.config.width / whiteKeys.length;
    
    // Always check black keys first as they overlap white keys
    if (position.dy < widget.config.height * 0.62) {
      final blackKey = _findBlackKeyAtPosition(position, whiteKeyWidth);
      if (blackKey != null) return blackKey;
    }
    
    // Find white key with better accuracy
    final whiteKeyIndex = (position.dx / whiteKeyWidth).floor();
    if (whiteKeyIndex >= 0 && whiteKeyIndex < whiteKeys.length) {
      return whiteKeys[whiteKeyIndex];
    }
    
    return null;
  }

  KeyConfiguration? _findBlackKeyAtPosition(Offset position, double whiteKeyWidth) {
    final blackKeyWidth = whiteKeyWidth * 0.65; // Match painter dimensions
    
    for (final key in _keyConfigurations) {
      if (!key.isWhiteKey) {
        final visualPosition = key.getBlackKeyVisualPosition();
        if (visualPosition != null) {
          // Use the same positioning logic as the painter
          final whiteKeys = _keyConfigurations.where((k) => k.isWhiteKey).toList();
          
          // Find the white key that comes immediately before this black key
          int beforeWhiteIndex = -1;
          for (int i = whiteKeys.length - 1; i >= 0; i--) {
            if (whiteKeys[i].midiNote < key.midiNote) {
              beforeWhiteIndex = i;
              break;
            }
          }
          
          double relativePosition;
          if (beforeWhiteIndex == -1) {
            relativePosition = 0.0;
          } else {
            final keySemitone = key.midiNote % 12;
            relativePosition = beforeWhiteIndex.toDouble();
            
            // Add 1.0 offset to center the black key between white keys
            if (keySemitone == 1) { // C#
              relativePosition += 1.0;
            } else if (keySemitone == 3) { // D#
              relativePosition += 1.0;
            } else if (keySemitone == 6) { // F#
              relativePosition += 1.0;
            } else if (keySemitone == 8) { // G#
              relativePosition += 1.0;
            } else if (keySemitone == 10) { // A#
              relativePosition += 1.0;
            }
          }
          
          final xPosition = relativePosition * whiteKeyWidth - (blackKeyWidth / 2);
          
          // Check if position is within black key bounds
          if (position.dx >= xPosition && 
              position.dx <= xPosition + blackKeyWidth &&
              xPosition >= 0 && 
              xPosition + blackKeyWidth <= widget.config.width) {
            return key;
          }
        }
      }
    }
    return null;
  }

  KeyConfiguration? _findWhiteKeyAtIndex(int index) {
    // Find the nth white key
    int whiteKeyCount = 0;
    for (final key in _keyConfigurations) {
      if (key.isWhiteKey) {
        if (whiteKeyCount == index) {
          return key;
        }
        whiteKeyCount++;
      }
    }
    return null;
  }

  int _getWhiteKeyCount() {
    return _keyConfigurations.where((key) => key.isWhiteKey).length;
  }
}