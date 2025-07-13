// lib/models/app_state.dart - Updated with user management
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../../controllers/music_controller.dart';
import '../constants/music_constants.dart';
import 'fretboard/fretboard_config.dart';
import 'fretboard/fretboard_instance.dart';
import 'music/chord.dart';
import 'music/note.dart';
import 'user/user.dart';
import '../services/user_service.dart';

/// Central application state management
class AppState extends ChangeNotifier {
  // ===== USER MANAGEMENT =====
  User? _currentUser;

  // ===== FRETBOARD DEFAULTS =====
  // Default fretboard configuration that will be used for new fretboards
  int _defaultStringCount = AppConstants.defaultStringCount;
  int _defaultFretCount = AppConstants.defaultFretCount;
  List<String> _defaultTuning =
      List.from(MusicConstants.standardTunings['Guitar (6-string)']!);
  FretboardLayout _defaultLayout = FretboardLayout.rightHandedBassBottom;

  // Default music theory settings
  String _defaultRoot = AppConstants.defaultRoot;
  ViewMode _defaultViewMode = ViewMode.intervals;
  String _defaultScale = AppConstants.defaultScale;
  int _defaultModeIndex = 0;
  Set<int> _defaultSelectedOctaves = {AppConstants.defaultOctave};
  Set<int> _defaultSelectedIntervals = {0}; // Start with root selected

  // ===== APP PREFERENCES =====
  ThemeMode _themeMode = ThemeMode.light;

  // ===== CURRENT SESSION STATE =====
  // These represent the current working state (used by single fretboard views)
  String _root = AppConstants.defaultRoot;
  ViewMode _viewMode = ViewMode.intervals;
  String _scale = AppConstants.defaultScale;
  int _modeIndex = 0;
  Set<int> _selectedOctaves = {AppConstants.defaultOctave};
  Set<int> _selectedIntervals = {0}; // Start with root selected

  // ===== USER GETTERS =====
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // ===== FRETBOARD DEFAULTS GETTERS =====
  int get defaultStringCount => _defaultStringCount;
  int get defaultFretCount => _defaultFretCount;
  List<String> get defaultTuning => List.unmodifiable(_defaultTuning);
  FretboardLayout get defaultLayout => _defaultLayout;
  String get defaultRoot => _defaultRoot;
  ViewMode get defaultViewMode => _defaultViewMode;
  String get defaultScale => _defaultScale;
  int get defaultModeIndex => _defaultModeIndex;
  Set<int> get defaultSelectedOctaves =>
      Set.unmodifiable(_defaultSelectedOctaves);
  Set<int> get defaultSelectedIntervals =>
      Set.unmodifiable(_defaultSelectedIntervals);

  // ===== APP PREFERENCES GETTERS =====
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;

  // ===== CURRENT SESSION GETTERS (for backward compatibility) =====
  int get stringCount => _defaultStringCount; // Use defaults for global state
  int get fretCount => _defaultFretCount; // Use defaults for global state
  List<String> get tuning => List.unmodifiable(_defaultTuning); // Use defaults
  FretboardLayout get layout => _defaultLayout; // Use defaults
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
  bool get isLeftHanded => _defaultLayout.isLeftHanded;
  bool get isBassTop => _defaultLayout.isBassTop;
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

  // ===== USER MANAGEMENT METHODS =====
  
  /// Set current user and load their preferences
  Future<void> setCurrentUser(User user) async {
    _currentUser = user;
    await loadUserPreferences(user.preferences);
    notifyListeners();
  }

  /// Load user preferences into app state
  Future<void> loadUserPreferences(UserPreferences preferences) async {
    _themeMode = preferences.themeMode;
    _defaultLayout = preferences.defaultLayout;
    _defaultStringCount = preferences.defaultStringCount;
    _defaultFretCount = preferences.defaultFretCount;
    _defaultTuning = List.from(preferences.defaultTuning);
    _defaultRoot = preferences.defaultRoot;
    _defaultViewMode = preferences.defaultViewMode;
    _defaultScale = preferences.defaultScale;
    _defaultSelectedOctaves = Set.from(preferences.defaultSelectedOctaves);
    
    // Also update current session state to match defaults
    _root = _defaultRoot;
    _viewMode = _defaultViewMode;
    _scale = _defaultScale;
    _selectedOctaves = Set.from(_defaultSelectedOctaves);
    
    notifyListeners();
  }

  /// Save current preferences to user
  Future<void> saveUserPreferences() async {
    if (_currentUser != null) {
      final updatedPreferences = _currentUser!.preferences.copyWith(
        themeMode: _themeMode,
        defaultLayout: _defaultLayout,
        defaultStringCount: _defaultStringCount,
        defaultFretCount: _defaultFretCount,
        defaultTuning: _defaultTuning,
        defaultRoot: _defaultRoot,
        defaultViewMode: _defaultViewMode,
        defaultScale: _defaultScale,
        defaultSelectedOctaves: _defaultSelectedOctaves,
      );
      
      await UserService.instance.updateUserPreferences(updatedPreferences);
      _currentUser = _currentUser!.copyWith(preferences: updatedPreferences);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await UserService.instance.logout();
    _currentUser = null;
    notifyListeners();
  }

  // ===== FRETBOARD DEFAULTS SETTERS =====
  void setDefaultStringCount(int count) {
    if (count < AppConstants.minStrings || count > AppConstants.maxStrings)
      return;
    _defaultStringCount = count;
    _adjustDefaultTuningLength();
    saveUserPreferences();
    notifyListeners();
  }

  void setDefaultFretCount(int count) {
    if (count < AppConstants.minFrets || count > AppConstants.maxFrets) return;
    _defaultFretCount = count;
    saveUserPreferences();
    notifyListeners();
  }

  void setDefaultTuning(List<String> newTuning) {
    _defaultTuning = List.from(newTuning);
    _adjustDefaultTuningLength();
    saveUserPreferences();
    notifyListeners();
  }

  void setDefaultTuningNote(int stringIndex, String note, int octave) {
    if (stringIndex >= 0 && stringIndex < _defaultTuning.length) {
      _defaultTuning[stringIndex] = '$note$octave';
      saveUserPreferences();
      notifyListeners();
    }
  }

  void setDefaultLayout(FretboardLayout layout) {
    _defaultLayout = layout;
    saveUserPreferences();
    notifyListeners();
  }

  void setDefaultRoot(String root) {
    _defaultRoot = root;
    saveUserPreferences();
    notifyListeners();
  }

  void setDefaultViewMode(ViewMode mode) {
    _defaultViewMode = mode;
    if (mode == ViewMode.intervals) {
      _defaultSelectedIntervals = {0};
    } else if (mode == ViewMode.chords) {
      _ensureSingleOctaveForDefaults();
    }
    saveUserPreferences();
    notifyListeners();
  }

  void setDefaultScale(String scale) {
    _defaultScale = scale;
    _defaultModeIndex = 0;
    saveUserPreferences();
    notifyListeners();
  }

  void setDefaultModeIndex(int index) {
    _defaultModeIndex = index;
    saveUserPreferences();
    notifyListeners();
  }

  void setDefaultSelectedOctaves(Set<int> octaves) {
    final validOctaves =
        octaves.where((o) => o >= 0 && o <= AppConstants.maxOctaves).toSet();
    if (validOctaves.isNotEmpty) {
      if (_defaultViewMode == ViewMode.chords && validOctaves.length > 1) {
        _defaultSelectedOctaves = {validOctaves.first};
      } else {
        _defaultSelectedOctaves = validOctaves;
      }
      saveUserPreferences();
      notifyListeners();
    }
  }

  void setDefaultSelectedIntervals(Set<int> intervals) {
    final newIntervals = Set<int>.from(intervals);
    if (newIntervals.isEmpty) {
      newIntervals.add(0);
    }
    _defaultSelectedIntervals = newIntervals;
    saveUserPreferences();
    notifyListeners();
  }

  void applyStandardTuningAsDefault(String tuningName) {
    final tuning = MusicConstants.standardTunings[tuningName];
    if (tuning != null) {
      setDefaultStringCount(tuning.length);
      setDefaultTuning(tuning);
    }
  }

  // ===== APP PREFERENCES SETTERS =====
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    saveUserPreferences();
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    saveUserPreferences();
    notifyListeners();
  }

  // ===== CURRENT SESSION SETTERS (for backward compatibility) =====
  void setStringCount(int count) => setDefaultStringCount(count);
  void setFretCount(int count) => setDefaultFretCount(count);
  void setTuning(List<String> newTuning) => setDefaultTuning(newTuning);
  void setTuningNote(int stringIndex, String note, int octave) =>
      setDefaultTuningNote(stringIndex, note, octave);
  void setLayout(FretboardLayout layout) => setDefaultLayout(layout);
  void applyStandardTuning(String tuningName) =>
      applyStandardTuningAsDefault(tuningName);

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
      _ensureSingleOctaveForCurrent();
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

  // Interval management (current session)
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

    if (_selectedIntervals.length == 1 && !_selectedIntervals.contains(0)) {
      _handleSingleIntervalAsNewRoot();
    } else {
      notifyListeners();
    }
  }

  void _handleSingleIntervalAsNewRoot() {
    if (_selectedIntervals.isEmpty || _selectedIntervals.contains(0)) {
      notifyListeners();
      return;
    }

    final selectedInterval = _selectedIntervals.first;
    final referenceOctave = _selectedOctaves.isEmpty
        ? 3
        : _selectedOctaves.reduce((a, b) => a < b ? a : b);
    final currentRootNote = Note.fromString('$_root$referenceOctave');
    final newRootNote = currentRootNote.transpose(selectedInterval);

    _root = newRootNote.name;
    _selectedIntervals = {0};

    final newOctave = newRootNote.octave;
    if (!_selectedOctaves.contains(newOctave)) {
      _selectedOctaves = {newOctave};
    }

    debugPrint('Changed root to ${newRootNote.name} octave $newOctave');
    notifyListeners();
  }

  // Octave management (current session)
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

  // ===== UTILITY METHODS =====
  /// Create a new fretboard instance with current defaults
  FretboardInstance createFretboardWithDefaults(String id) {
    return FretboardInstance(
      id: id,
      root: _defaultRoot,
      viewMode: _defaultViewMode,
      scale: _defaultScale,
      modeIndex: _defaultModeIndex,
      chordType: 'major',
      chordInversion: ChordInversion.root,
      selectedOctaves: Set.from(_defaultSelectedOctaves),
      selectedIntervals: Set.from(_defaultSelectedIntervals),
      tuning: List.from(_defaultTuning),
      stringCount: _defaultStringCount,
      visibleFretEnd: _defaultFretCount,
      showScaleStrip: true,
      showNoteNames: false,
    );
  }

  // Reset methods
  void resetDefaultsToFactorySettings() {
    _defaultStringCount = AppConstants.defaultStringCount;
    _defaultFretCount = AppConstants.defaultFretCount;
    _defaultTuning =
        List.from(MusicConstants.standardTunings['Guitar (6-string)']!);
    _defaultLayout = FretboardLayout.rightHandedBassTop;
    _defaultRoot = AppConstants.defaultRoot;
    _defaultViewMode = ViewMode.intervals;
    _defaultScale = AppConstants.defaultScale;
    _defaultModeIndex = 0;
    _defaultSelectedOctaves = {AppConstants.defaultOctave};
    _defaultSelectedIntervals = {0};
    saveUserPreferences();
    notifyListeners();
  }

  void resetToDefaults() {
    // Reset current session to defaults
    _root = _defaultRoot;
    _viewMode = _defaultViewMode;
    _scale = _defaultScale;
    _modeIndex = _defaultModeIndex;
    _selectedOctaves = Set.from(_defaultSelectedOctaves);
    _selectedIntervals = Set.from(_defaultSelectedIntervals);
    notifyListeners();
  }

  void resetAllToFactorySettings() {
    resetDefaultsToFactorySettings();
    resetToDefaults();
    _themeMode = ThemeMode.light;
    saveUserPreferences();
    notifyListeners();
  }

  // Private helpers
  void _adjustDefaultTuningLength() {
    while (_defaultTuning.length < _defaultStringCount) {
      _defaultTuning.add('C3');
    }
    if (_defaultTuning.length > _defaultStringCount) {
      _defaultTuning = _defaultTuning.sublist(0, _defaultStringCount);
    }
  }

  void _ensureSingleOctaveForDefaults() {
    if (_defaultSelectedOctaves.length > 1) {
      _defaultSelectedOctaves = {_defaultSelectedOctaves.first};
    } else if (_defaultSelectedOctaves.isEmpty) {
      _defaultSelectedOctaves = {AppConstants.defaultOctave};
    }
  }

  void _ensureSingleOctaveForCurrent() {
    if (_selectedOctaves.length > 1) {
      _selectedOctaves = {_selectedOctaves.first};
    } else if (_selectedOctaves.isEmpty) {
      _selectedOctaves = {AppConstants.defaultOctave};
    }
  }
}