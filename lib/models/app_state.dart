// lib/models/app_state.dart
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../../controllers/music_controller.dart';
import '../constants/music_constants.dart';
import 'fretboard/fretboard_config.dart';
import 'music/note.dart';

/// Central application state management
class AppState extends ChangeNotifier {
  // Fretboard configuration
  int _stringCount = AppConstants.defaultStringCount;
  int _fretCount = AppConstants.defaultFretCount;
  List<String> _tuning =
      List.from(MusicConstants.standardTunings['Guitar (6-string)']!);
  FretboardLayout _layout = FretboardLayout.rightHandedBassTop;

  // Music theory settings
  String _root = AppConstants.defaultRoot;
  ViewMode _viewMode = ViewMode.intervals;
  String _scale = AppConstants.defaultScale;
  int _modeIndex = 0;

  // Selected octaves and intervals
  Set<int> _selectedOctaves = {AppConstants.defaultOctave};
  Set<int> _selectedIntervals = {0}; // Start with root selected

  // Getters
  int get stringCount => _stringCount;
  int get fretCount => _fretCount;
  List<String> get tuning => List.unmodifiable(_tuning);
  FretboardLayout get layout => _layout;
  String get root => _root;
  ViewMode get viewMode => _viewMode;
  String get scale => _scale;
  int get modeIndex => _modeIndex;

  Set<int> get selectedOctaves => Set.unmodifiable(_selectedOctaves);
  int get octaveCount => _selectedOctaves.length;
  int get maxSelectedOctave => _selectedOctaves.isEmpty
      ? 0
      : _selectedOctaves.reduce((a, b) => a > b ? a : b);
  int get minSelectedOctave => _selectedOctaves.isEmpty
      ? 0
      : _selectedOctaves.reduce((a, b) => a < b ? a : b);

  Set<int> get selectedIntervals => Set.unmodifiable(_selectedIntervals);
  bool get hasSelectedIntervals => _selectedIntervals.isNotEmpty;

  // Derived getters
  bool get isLeftHanded => _layout.isLeftHanded;
  bool get isBassTop => _layout.isBassTop;
  bool get isScaleMode => _viewMode == ViewMode.scales;
  bool get isIntervalMode => _viewMode == ViewMode.intervals;
  bool get isChordMode => _viewMode == ViewMode.chords;

  String get effectiveRoot => isScaleMode
      ? MusicController.getModeRoot(_root, _scale, _modeIndex)
      : _root;

  List<String> get availableModes => MusicController.getAvailableModes(_scale);

  String get currentModeName => availableModes.isNotEmpty
      ? availableModes[_modeIndex % availableModes.length]
      : 'Mode ${_modeIndex + 1}';

  // Setters with validation
  void setStringCount(int count) {
    if (count < AppConstants.minStrings || count > AppConstants.maxStrings)
      return;

    _stringCount = count;
    _adjustTuningLength();
    notifyListeners();
  }

  void setFretCount(int count) {
    if (count < AppConstants.minFrets || count > AppConstants.maxFrets) return;
    _fretCount = count;
    notifyListeners();
  }

  void setTuning(List<String> newTuning) {
    _tuning = List.from(newTuning);
    _adjustTuningLength();
    notifyListeners();
  }

  void setTuningNote(int stringIndex, String note, int octave) {
    if (stringIndex >= 0 && stringIndex < _tuning.length) {
      _tuning[stringIndex] = '$note$octave';
      notifyListeners();
    }
  }

  void setLayout(FretboardLayout layout) {
    _layout = layout;
    notifyListeners();
  }

  void applyStandardTuning(String tuningName) {
    final tuning = MusicConstants.standardTunings[tuningName];
    if (tuning != null) {
      setStringCount(tuning.length);
      setTuning(tuning);
    }
  }

  void setRoot(String root) {
    _root = root;
    if (isIntervalMode) {
      _selectedIntervals = {0};
    }
    notifyListeners();
  }

  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    if (mode == ViewMode.intervals) {
      _selectedIntervals = {0};
    } else if (mode == ViewMode.chords) {
      _ensureSingleOctaveForChords();
    }
    notifyListeners();
  }

  void setScale(String scale) {
    _scale = scale;
    _modeIndex = 0;
    notifyListeners();
  }

  void setModeIndex(int index) {
    _modeIndex = index;
    notifyListeners();
  }

  // Interval management
  void toggleInterval(int extendedInterval) {
    debugPrint(
        'AppState toggleInterval: $extendedInterval, current intervals: $_selectedIntervals');

    if (_selectedIntervals.contains(extendedInterval)) {
      if (_selectedIntervals.length > 1 || extendedInterval != 0) {
        _selectedIntervals.remove(extendedInterval);
      }
    } else {
      _selectedIntervals.add(extendedInterval);
    }
    
    // Check if only one interval is selected and it's not the root
    if (_selectedIntervals.length == 1 && !_selectedIntervals.contains(0)) {
      _handleSingleIntervalAsNewRoot();
    } else {
      notifyListeners();
    }
  }

  void setSelectedIntervals(Set<int> extendedIntervals) {
    final newIntervals = Set<int>.from(extendedIntervals);
    if (newIntervals.isEmpty) {
      newIntervals.add(0);
    }
    _selectedIntervals = newIntervals;
    
    // Check if only one interval is selected and it's not the root
    if (_selectedIntervals.length == 1 && !_selectedIntervals.contains(0)) {
      _handleSingleIntervalAsNewRoot();
    } else {
      notifyListeners();
    }
  }

  // Handle single interval becoming new root
  void _handleSingleIntervalAsNewRoot() {
    if (_selectedIntervals.isEmpty || _selectedIntervals.contains(0)) {
      notifyListeners();
      return;
    }
    
    final selectedInterval = _selectedIntervals.first;
    
    // Calculate the new root based on the selected interval
    final referenceOctave = _selectedOctaves.isEmpty ? 3 : _selectedOctaves.reduce((a, b) => a < b ? a : b);
    final currentRootNote = Note.fromString('$_root$referenceOctave');
    final newRootNote = currentRootNote.transpose(selectedInterval);
    
    // Update the root
    _root = newRootNote.name;
    
    // Reset intervals to just the root
    _selectedIntervals = {0};
    
    // Adjust octaves if needed
    final newOctave = newRootNote.octave;
    if (!_selectedOctaves.contains(newOctave)) {
      _selectedOctaves = {newOctave};
    }
    
    debugPrint('Changed root to ${newRootNote.name} octave $newOctave');
    notifyListeners();
  }

  // Octave management
  void setSelectedOctaves(Set<int> octaves) {
    final validOctaves =
        octaves.where((o) => o >= 0 && o <= AppConstants.maxOctaves).toSet();
    if (validOctaves.isNotEmpty) {
      if (isChordMode && validOctaves.length > 1) {
        _selectedOctaves = {validOctaves.first};
      } else {
        _selectedOctaves = validOctaves;
      }
      notifyListeners();
    }
  }

  void toggleOctave(int octave) {
    if (octave < 0 || octave > AppConstants.maxOctaves) return;

    if (isChordMode) {
      _selectedOctaves = {octave};
      notifyListeners();
      return;
    }

    if (_selectedOctaves.contains(octave)) {
      if (_selectedOctaves.length > 1) {
        _selectedOctaves.remove(octave);
        notifyListeners();
      }
    } else {
      _selectedOctaves.add(octave);
      notifyListeners();
    }
  }

  void setOctaveRange(int start, int end) {
    if (start < 0 || end > AppConstants.maxOctaves || start > end) return;

    if (isChordMode) {
      _selectedOctaves = {start};
    } else {
      final newOctaves = <int>{};
      for (int i = start; i <= end; i++) {
        newOctaves.add(i);
      }
      _selectedOctaves = newOctaves;
    }
    notifyListeners();
  }

  void selectAllOctaves() {
    if (isChordMode) return;

    _selectedOctaves =
        List.generate(AppConstants.maxOctaves + 1, (i) => i).toSet();
    notifyListeners();
  }

  void resetToDefaultOctave() {
    _selectedOctaves = {AppConstants.defaultOctave};
    notifyListeners();
  }

  // Reset to defaults
  void resetToDefaults() {
    _stringCount = AppConstants.defaultStringCount;
    _fretCount = AppConstants.defaultFretCount;
    _tuning = List.from(MusicConstants.standardTunings['Guitar (6-string)']!);
    _layout = FretboardLayout.rightHandedBassTop;
    _root = AppConstants.defaultRoot;
    _viewMode = ViewMode.intervals;
    _scale = AppConstants.defaultScale;
    _modeIndex = 0;
    _selectedOctaves = {AppConstants.defaultOctave};
    _selectedIntervals = {0};
    notifyListeners();
  }

  // Private helpers
  void _adjustTuningLength() {
    while (_tuning.length < _stringCount) {
      _tuning.add('C3');
    }
    if (_tuning.length > _stringCount) {
      _tuning = _tuning.sublist(0, _stringCount);
    }
  }

  void _ensureSingleOctaveForChords() {
    if (_selectedOctaves.length > 1) {
      _selectedOctaves = {_selectedOctaves.first};
    } else if (_selectedOctaves.isEmpty) {
      _selectedOctaves = {AppConstants.defaultOctave};
    }
  }
}