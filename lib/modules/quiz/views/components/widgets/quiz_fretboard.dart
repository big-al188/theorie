import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/quiz_enums.dart';

/// Interactive fretboard widget for chord quiz questions
class QuizFretboard extends StatefulWidget {
  final String chordName;
  final FretboardMode fretboardMode;
  final Map<String, dynamic> initialState;
  final List<Map<String, dynamic>>? acceptablePositions;
  final bool isReadOnly;
  final Function(Map<String, dynamic>)? onStateChanged;

  const QuizFretboard({
    Key? key,
    required this.chordName,
    required this.fretboardMode,
    required this.initialState,
    this.acceptablePositions,
    this.isReadOnly = false,
    this.onStateChanged,
  }) : super(key: key);

  @override
  State<QuizFretboard> createState() => _QuizFretboardState();
}

class _QuizFretboardState extends State<QuizFretboard> {
  late Map<String, dynamic> _currentState;
  final int _numberOfStrings = 6;
  final int _numberOfFrets = 5;
  final List<String> _stringNotes = ['E', 'B', 'G', 'D', 'A', 'E']; // High to low
  
  // Visual constants
  static const double _fretWidth = 70.0;
  static const double _stringSpacing = 40.0;
  static const double _nutWidth = 8.0;
  static const Color _correctColor = Colors.green;
  static const Color _incorrectColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _currentState = Map<String, dynamic>.from(widget.initialState);
    _initializeFretboard();
  }

  void _initializeFretboard() {
    // Initialize positions if not present
    if (!_currentState.containsKey('positions')) {
      _currentState['positions'] = {};
      
      // If there's a chord position in initial state, use it
      if (_currentState.containsKey('chordPositions')) {
        _currentState['positions'] = Map<String, dynamic>.from(
          _currentState['chordPositions'],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 16),
        _buildFretboard(theme),
        if (_shouldShowFingerNumbers()) ...[
          const SizedBox(height: 16),
          _buildFingerNumberLegend(theme),
        ],
        if (widget.fretboardMode == FretboardMode.singleNote) ...[
          const SizedBox(height: 16),
          _buildNoteIdentification(theme),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _getInstructions(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFretboard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // Fretboard background
                _buildFretboardBackground(theme),
                // Strings
                _buildStrings(theme),
                // Fret markers
                _buildFretMarkers(theme),
                // Interactive positions
                _buildInteractivePositions(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFretboardBackground(ThemeData theme) {
    return Container(
      width: _nutWidth + (_fretWidth * _numberOfFrets),
      height: _stringSpacing * (_numberOfStrings - 1) + 40,
      child: Row(
        children: [
          // Nut
          Container(
            width: _nutWidth,
            color: theme.colorScheme.onSurface,
          ),
          // Frets
          for (int i = 0; i < _numberOfFrets; i++)
            Container(
              width: _fretWidth,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF8B4513),
                  const Color(0xFFD2691E),
                  i / _numberOfFrets,
                ),
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStrings(ThemeData theme) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int string = 0; string < _numberOfStrings; string++)
            Container(
              height: _stringSpacing,
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  // String line
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _stringSpacing / 2 - 1,
                    child: Container(
                      height: 2 + (string * 0.3), // Thicker strings for lower notes
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  // String label
                  Positioned(
                    left: -30,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        _stringNotes[string],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFretMarkers(ThemeData theme) {
    final markerFrets = [3, 5, 7, 9, 12];
    
    return Positioned.fill(
      child: Row(
        children: [
          SizedBox(width: _nutWidth),
          for (int fret = 1; fret <= _numberOfFrets; fret++)
            Container(
              width: _fretWidth,
              child: markerFrets.contains(fret)
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildInteractivePositions(ThemeData theme) {
    final positions = _currentState['positions'] as Map<String, dynamic>? ?? {};
    
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int string = 0; string < _numberOfStrings; string++)
            Container(
              height: _stringSpacing,
              child: Row(
                children: [
                  // Open string area
                  GestureDetector(
                    onTap: !widget.isReadOnly
                        ? () => _handlePositionTap(string + 1, 0)
                        : null,
                    child: Container(
                      width: _nutWidth + 20,
                      height: _stringSpacing,
                      alignment: Alignment.center,
                      child: _buildPositionIndicator(
                        string: string + 1,
                        fret: 0,
                        value: positions['${string + 1}'],
                        theme: theme,
                      ),
                    ),
                  ),
                  // Fret positions
                  for (int fret = 1; fret <= _numberOfFrets; fret++)
                    GestureDetector(
                      onTap: !widget.isReadOnly
                          ? () => _handlePositionTap(string + 1, fret)
                          : null,
                      child: Container(
                        width: _fretWidth,
                        height: _stringSpacing,
                        alignment: Alignment.center,
                        child: _buildPositionIndicator(
                          string: string + 1,
                          fret: fret,
                          value: positions['${string + 1}'],
                          theme: theme,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPositionIndicator({
    required int string,
    required int fret,
    required dynamic value,
    required ThemeData theme,
  }) {
    // Check if this position is active
    bool isActive = false;
    String? fingerNumber;
    bool isMuted = value == 'x';
    bool isOpen = value == 0;
    
    if (value is int && value == fret) {
      isActive = true;
    }
    
    // Get finger number if in chord mode with finger numbers
    if (isActive && _shouldShowFingerNumbers()) {
      fingerNumber = _getFingerNumber(string, fret);
    }

    // Check correctness if in read-only mode
    bool? isCorrect;
    if (widget.isReadOnly && widget.acceptablePositions != null) {
      isCorrect = _checkPositionCorrectness(string, fret, value);
    }

    if (fret == 0) {
      // Open string or muted indicator
      if (isMuted) {
        return Text(
          'X',
          style: theme.textTheme.titleLarge?.copyWith(
            color: isCorrect == false ? _incorrectColor : theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        );
      } else if (isOpen) {
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCorrect == false
                  ? _incorrectColor
                  : theme.colorScheme.primary,
              width: 2,
            ),
          ),
        );
      }
    } else if (isActive) {
      // Fretted position
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCorrect == false
              ? _incorrectColor
              : isCorrect == true
                  ? _correctColor
                  : theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: (isCorrect == false
                      ? _incorrectColor
                      : theme.colorScheme.primary)
                  .withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            fingerNumber ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFingerNumberLegend(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finger Numbers:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFingerChip('1', 'Index', theme),
                const SizedBox(width: 8),
                _buildFingerChip('2', 'Middle', theme),
                const SizedBox(width: 8),
                _buildFingerChip('3', 'Ring', theme),
                const SizedBox(width: 8),
                _buildFingerChip('4', 'Pinky', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerChip(String number, String name, ThemeData theme) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          number,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      label: Text(name),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildNoteIdentification(ThemeData theme) {
    final positions = _currentState['positions'] as Map<String, dynamic>? ?? {};
    final noteNames = _currentState['noteNames'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identify the notes:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: positions.entries.map((entry) {
                final string = int.parse(entry.key);
                final fret = entry.value;
                if (fret == 'x' || fret == null) return const SizedBox.shrink();
                
                final key = entry.key;
                final userNote = noteNames[key];
                
                return SizedBox(
                  width: 80,
                  child: TextField(
                    enabled: !widget.isReadOnly,
                    controller: TextEditingController(text: userNote),
                    decoration: InputDecoration(
                      labelText: 'String $string',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => _handleNoteNameInput(key, value),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getInstructions() {
    switch (widget.fretboardMode) {
      case FretboardMode.chord:
        return 'Place your fingers to form the ${widget.chordName} chord';
      case FretboardMode.scale:
        return 'Mark the notes of the scale on the fretboard';
      case FretboardMode.singleNote:
        return 'Identify the notes at the marked positions';
      case FretboardMode.pattern:
        return 'Complete the pattern on the fretboard';
    }
  }

  bool _shouldShowFingerNumbers() {
    return widget.fretboardMode == FretboardMode.chord &&
        (_currentState['showFingerNumbers'] ?? true);
  }

  String? _getFingerNumber(int string, int fret) {
    // Simplified finger assignment - in a real app, this would be
    // based on proper chord fingering data
    final positions = _currentState['positions'] as Map<String, dynamic>? ?? {};
    final activePositions = positions.entries
        .where((e) => e.value is int && e.value > 0)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (int i = 0; i < activePositions.length; i++) {
      if (activePositions[i].key == string.toString() &&
          activePositions[i].value == fret) {
        return (i + 1).toString();
      }
    }
    return null;
  }

  bool? _checkPositionCorrectness(int string, int fret, dynamic currentValue) {
    if (widget.acceptablePositions == null) return null;
    
    for (final acceptable in widget.acceptablePositions!) {
      final positions = acceptable['positions'] as Map<String, dynamic>?;
      if (positions != null) {
        final expectedValue = positions[string.toString()];
        
        // Check if this is the active position for this string
        if ((currentValue == fret && fret > 0) ||
            (currentValue == 0 && fret == 0) ||
            (currentValue == 'x' && fret == 0)) {
          return currentValue == expectedValue;
        }
      }
    }
    
    return null;
  }

  void _handlePositionTap(int string, int fret) {
    setState(() {
      final positions = Map<String, dynamic>.from(
        _currentState['positions'] ?? {},
      );
      
      final currentValue = positions[string.toString()];
      
      if (fret == 0) {
        // Cycle through: nothing -> open (0) -> muted (x) -> nothing
        if (currentValue == null) {
          positions[string.toString()] = 0;
        } else if (currentValue == 0) {
          positions[string.toString()] = 'x';
        } else {
          positions.remove(string.toString());
        }
      } else {
        // Toggle fret position
        if (currentValue == fret) {
          positions.remove(string.toString());
        } else {
          positions[string.toString()] = fret;
        }
      }
      
      _currentState['positions'] = positions;
    });
    
    widget.onStateChanged?.call(_currentState);
  }

  void _handleNoteNameInput(String string, String value) {
    setState(() {
      final noteNames = Map<String, dynamic>.from(
        _currentState['noteNames'] ?? {},
      );
      
      if (value.isEmpty) {
        noteNames.remove(string);
      } else {
        noteNames[string] = value.toUpperCase();
      }
      
      _currentState['noteNames'] = noteNames;
    });
    
    widget.onStateChanged?.call(_currentState);
  }
}