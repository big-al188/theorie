// lib/views/widgets/keyboard/keyboard_painter.dart
import 'package:flutter/material.dart';
import '../../../models/keyboard/keyboard_config.dart';
import '../../../models/keyboard/key_configuration.dart';

/// Custom painter for rendering piano keyboard with professional appearance
/// Handles both white and black keys with theme-aware colors, shadows, and highlighting
/// Optimized for performance and accessibility across all device types
class KeyboardPainter extends CustomPainter {
  final List<KeyConfiguration> keyConfigurations;
  final KeyboardConfig config;
  final ColorScheme colorScheme;
  final bool isDarkMode;

  KeyboardPainter({
    required this.keyConfigurations,
    required this.config,
    required this.colorScheme,
    required this.isDarkMode,
  });

  // Professional color palette for piano keys
  Color get whiteKeyColor => isDarkMode ? const Color(0xFFF8F8F8) : Colors.white;
  Color get whiteKeyPressedColor => isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFFF0F0F0);
  Color get whiteKeyBorderColor => isDarkMode ? const Color(0xFF666666) : const Color(0xFF999999);
  Color get whiteKeyTextColor => isDarkMode ? const Color(0xFF333333) : const Color(0xFF555555);
  
  Color get blackKeyColor => isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C);
  Color get blackKeyPressedColor => isDarkMode ? const Color(0xFF333333) : const Color(0xFF454545);
  Color get blackKeyTextColor => isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFFE8E8E8);
  
  // Shadow colors for depth
  Color get shadowColor => Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2);
  Color get blackKeyShadowColor => Colors.black.withOpacity(isDarkMode ? 0.6 : 0.3);

  @override
  void paint(Canvas canvas, Size size) {
    // Professional keyboard rendering with shadows and depth
    _drawKeyboardBackground(canvas, size);
    _drawWhiteKeys(canvas, size);
    _drawWhiteKeyShadows(canvas, size);
    _drawBlackKeys(canvas, size);
    _drawBlackKeyShadows(canvas, size);
    _drawLabels(canvas, size);
  }
  
  void _drawKeyboardBackground(Canvas canvas, Size size) {
    // Draw subtle keyboard frame/background
    final backgroundPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
  }

  void _drawWhiteKeys(Canvas canvas, Size size) {
    final whiteKeys = keyConfigurations.where((key) => key.isWhiteKey).toList();
    final whiteKeyWidth = size.width / whiteKeys.length;
    final whiteKeyHeight = size.height;

    for (int i = 0; i < whiteKeys.length; i++) {
      final key = whiteKeys[i];
      final keyRect = Rect.fromLTWH(
        i * whiteKeyWidth,
        0,
        whiteKeyWidth - 1.0, // Small gap between keys
        whiteKeyHeight,
      );

      // Create rounded rectangle for more professional appearance
      final keyPath = Path()
        ..addRRect(RRect.fromRectAndCorners(
          keyRect,
          bottomLeft: const Radius.circular(4.0),
          bottomRight: const Radius.circular(4.0),
        ));

      // Key background with gradient for depth
      Paint keyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: key.isPressed 
            ? [whiteKeyPressedColor.withOpacity(0.95), whiteKeyPressedColor]
            : [whiteKeyColor, whiteKeyColor.withOpacity(0.98)],
        ).createShader(keyRect)
        ..style = PaintingStyle.fill;

      canvas.drawPath(keyPath, keyPaint);

      // Subtle key border
      Paint borderPaint = Paint()
        ..color = whiteKeyBorderColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawPath(keyPath, borderPaint);

      // Music theory highlight
      if (key.isHighlighted && key.highlightColor != null) {
        final highlightColor = key.highlightColor!;
        Paint highlightPaint = Paint()
          ..color = highlightColor.withOpacity(0.45) // Increased from 0.25 for better visibility
          ..style = PaintingStyle.fill;
        
        // Draw highlight with more vibrant border
        final highlightRect = keyRect.deflate(2.0);
        final highlightPath = Path()
          ..addRRect(RRect.fromRectAndCorners(
            highlightRect,
            bottomLeft: const Radius.circular(3.0),
            bottomRight: const Radius.circular(3.0),
          ));
        
        canvas.drawPath(highlightPath, highlightPaint);
        
        // More vibrant highlight border
        Paint highlightBorderPaint = Paint()
          ..color = highlightColor.withOpacity(0.85) // Increased from 0.6 for better visibility
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5; // Slightly thicker border for visibility
        
        canvas.drawPath(highlightPath, highlightBorderPaint);
      }
    }
  }
  
  void _drawWhiteKeyShadows(Canvas canvas, Size size) {
    final whiteKeys = keyConfigurations.where((key) => key.isWhiteKey).toList();
    final whiteKeyWidth = size.width / whiteKeys.length;
    final whiteKeyHeight = size.height;

    for (int i = 0; i < whiteKeys.length; i++) {
      final keyRect = Rect.fromLTWH(
        i * whiteKeyWidth + 1.0,
        1.0,
        whiteKeyWidth - 2.0,
        whiteKeyHeight - 1.0,
      );

      // Subtle inner shadow for depth
      Paint shadowPaint = Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 1.0);
      
      canvas.drawRect(keyRect, shadowPaint);
    }
  }

  void _drawBlackKeys(Canvas canvas, Size size) {
    final whiteKeys = keyConfigurations.where((key) => key.isWhiteKey).toList();
    final whiteKeyWidth = size.width / whiteKeys.length;
    final blackKeyWidth = whiteKeyWidth * 0.65; // Slightly wider for better touch targets
    final blackKeyHeight = size.height * 0.62; // Professional proportions

    for (final key in keyConfigurations) {
      if (!key.isWhiteKey) {
        final visualPosition = key.getBlackKeyVisualPosition();
        if (visualPosition != null) {
          // Calculate position relative to white keys accounting for keyboard start note
          final whiteKeys = keyConfigurations.where((k) => k.isWhiteKey).toList();
          
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
            // No white key before this black key (edge case)
            relativePosition = 0.0;
          } else {
            final beforeWhiteKey = whiteKeys[beforeWhiteIndex];
            final keySemitone = key.midiNote % 12;
            final beforeSemitone = beforeWhiteKey.midiNote % 12;
            
            // Start with the position of the white key before this black key
            relativePosition = beforeWhiteIndex.toDouble();
            
            // Add 1.0 offset to center the black key between the white keys
            // This positions C# between C and D, D# between D and E, etc.
            if (keySemitone == 1) { // C# - centered between C and D
              relativePosition += 1.0;
            } else if (keySemitone == 3) { // D# - centered between D and E  
              relativePosition += 1.0;
            } else if (keySemitone == 6) { // F# - centered between F and G
              relativePosition += 1.0;
            } else if (keySemitone == 8) { // G# - centered between G and A
              relativePosition += 1.0;
            } else if (keySemitone == 10) { // A# - centered between A and B
              relativePosition += 1.0;
            }
          }
          
          final xPosition = relativePosition * whiteKeyWidth - (blackKeyWidth / 2);

          if (xPosition >= 0 && xPosition + blackKeyWidth <= size.width) {
            final keyRect = Rect.fromLTWH(
              xPosition,
              0,
              blackKeyWidth,
              blackKeyHeight,
            );

            // Create rounded rectangle for professional appearance with slight grouping indication
            final radius = key.isFirstBlackKeyGroup ? 3.0 : 2.5; // Slightly different radius for grouping
            final keyPath = Path()
              ..addRRect(RRect.fromRectAndCorners(
                keyRect,
                bottomLeft: Radius.circular(radius),
                bottomRight: Radius.circular(radius),
              ));

            // Key background with gradient for depth
            Paint keyPaint = Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: key.isPressed
                  ? [blackKeyPressedColor, blackKeyPressedColor.withOpacity(0.9)]
                  : [blackKeyColor, blackKeyColor.withOpacity(0.85)],
              ).createShader(keyRect)
              ..style = PaintingStyle.fill;

            canvas.drawPath(keyPath, keyPaint);

            // Subtle key border with slight variation for grouping
            Paint borderPaint = Paint()
              ..color = Colors.black.withOpacity(key.isFirstBlackKeyGroup ? 0.8 : 0.75)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5;

            canvas.drawPath(keyPath, borderPaint);

            // Music theory highlight
            if (key.isHighlighted && key.highlightColor != null) {
              final highlightColor = key.highlightColor!;
              Paint highlightPaint = Paint()
                ..color = highlightColor.withOpacity(0.65) // Increased from 0.35 for much better visibility on black keys
                ..style = PaintingStyle.fill;
              
              // Draw highlight with more vibrant border
              final highlightRect = keyRect.deflate(2.0);
              final highlightPath = Path()
                ..addRRect(RRect.fromRectAndCorners(
                  highlightRect,
                  bottomLeft: Radius.circular(radius - 0.5),
                  bottomRight: Radius.circular(radius - 0.5),
                ));
              
              canvas.drawPath(highlightPath, highlightPaint);
              
              // Much more vibrant highlight border for black keys
              Paint highlightBorderPaint = Paint()
                ..color = highlightColor.withOpacity(0.95) // Increased from 0.7 for maximum visibility
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8; // Thicker border for better contrast on black keys
              
              canvas.drawPath(highlightPath, highlightBorderPaint);
            }
          }
        }
      }
    }
  }
  
  void _drawBlackKeyShadows(Canvas canvas, Size size) {
    final whiteKeys = keyConfigurations.where((key) => key.isWhiteKey).toList();
    final whiteKeyWidth = size.width / whiteKeys.length;
    final blackKeyWidth = whiteKeyWidth * 0.65;
    final blackKeyHeight = size.height * 0.62;

    for (final key in keyConfigurations) {
      if (!key.isWhiteKey) {
        final visualPosition = key.getBlackKeyVisualPosition();
        if (visualPosition != null) {
          // Use the same positioning logic as the main black key drawing
          final whiteKeys = keyConfigurations.where((k) => k.isWhiteKey).toList();
          
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

          if (xPosition >= 0 && xPosition + blackKeyWidth <= size.width) {
            // Drop shadow for black keys
            final shadowRect = Rect.fromLTWH(
              xPosition + 2.0,
              2.0,
              blackKeyWidth - 2.0,
              blackKeyHeight + 2.0,
            );

            Paint shadowPaint = Paint()
              ..color = blackKeyShadowColor
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
            
            canvas.drawRRect(
              RRect.fromRectAndCorners(
                shadowRect,
                bottomLeft: const Radius.circular(3.0),
                bottomRight: const Radius.circular(3.0),
              ),
              shadowPaint,
            );
          }
        }
      }
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    if (!config.showNoteNames && keyConfigurations.every((key) => !key.isHighlighted)) {
      return; // No labels to draw
    }

    final whiteKeys = keyConfigurations.where((key) => key.isWhiteKey).toList();
    final whiteKeyWidth = size.width / whiteKeys.length;
    final blackKeyWidth = whiteKeyWidth * 0.65;
    
    // Responsive font size based on key width
    final fontSize = _getResponsiveFontSize(whiteKeyWidth);

    for (final key in keyConfigurations) {
      if (key.isHighlighted || config.showNoteNames) {
        final text = key.displayName;
        if (text.isNotEmpty) {
          if (key.isWhiteKey) {
            _drawWhiteKeyLabel(canvas, key, text, whiteKeys, whiteKeyWidth, size, fontSize);
          } else {
            _drawBlackKeyLabel(canvas, key, text, whiteKeyWidth, blackKeyWidth, size, fontSize);
          }
        }
      }
    }
  }
  
  double _getResponsiveFontSize(double keyWidth) {
    // Calculate font size based on key width for better readability
    if (keyWidth < 30) return 10.0;
    if (keyWidth < 50) return 12.0;
    if (keyWidth < 80) return 14.0;
    return 16.0;
  }

  void _drawWhiteKeyLabel(Canvas canvas, KeyConfiguration key, String text, 
                         List<KeyConfiguration> whiteKeys, double whiteKeyWidth, Size size, double fontSize) {
    final index = whiteKeys.indexWhere((k) => k.keyIndex == key.keyIndex);
    if (index >= 0) {
      final centerX = (index * whiteKeyWidth) + (whiteKeyWidth / 2);
      final centerY = size.height - 25; // Slightly higher for better visibility
      
      // Choose color based on highlight status and theme
      Color textColor;
      if (key.isHighlighted && key.highlightColor != null) {
        textColor = _getContrastingTextColor(key.highlightColor!);
      } else {
        textColor = whiteKeyTextColor;
      }

      _drawTextLabel(canvas, text, centerX, centerY, textColor, fontSize, true, key.isHighlighted);
    }
  }

  void _drawBlackKeyLabel(Canvas canvas, KeyConfiguration key, String text,
                         double whiteKeyWidth, double blackKeyWidth, Size size, double fontSize) {
    final visualPosition = key.getBlackKeyVisualPosition();
    if (visualPosition != null) {
      // Use the same positioning logic as the main black key drawing
      final whiteKeys = keyConfigurations.where((k) => k.isWhiteKey).toList();
      
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
      
      final centerX = relativePosition * whiteKeyWidth;
      final centerY = size.height * 0.35; // Slightly lower for better balance

      if (centerX >= blackKeyWidth / 2 && centerX <= size.width - blackKeyWidth / 2) {
        // Choose color based on highlight status
        Color textColor;
        if (key.isHighlighted && key.highlightColor != null) {
          textColor = _getContrastingTextColor(key.highlightColor!);
        } else {
          textColor = blackKeyTextColor;
        }
        
        _drawTextLabel(canvas, text, centerX, centerY, textColor, fontSize, false, key.isHighlighted);
      }
    }
  }

  void _drawTextLabel(Canvas canvas, String text, double x, double y, Color color, double fontSize, bool isWhiteKey, bool isHighlighted) {
    // No background box - clean text labels only
    
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        shadows: isWhiteKey ? null : [
          Shadow(
            offset: const Offset(0.5, 0.5),
            blurRadius: 1.0,
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }
  
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }


  @override
  bool shouldRepaint(KeyboardPainter oldDelegate) {
    return keyConfigurations != oldDelegate.keyConfigurations ||
           config != oldDelegate.config ||
           colorScheme != oldDelegate.colorScheme ||
           isDarkMode != oldDelegate.isDarkMode;
  }
}