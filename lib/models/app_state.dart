// lib/models/app_state.dart - Updated for separated user models
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
import 'user/user_preferences.dart';  // ADDED: Import separated models
import 'user/user_progress.dart';     // ADDED: Import separated models
import '../services/user_service.dart';
import '../services/progress_tracking_service.dart';
import '../services/firebase_user_service.dart';

/// Central application state management
/// UPDATED: Enhanced for separated user models architecture
class AppState extends ChangeNotifier {
  // ===== USER MANAGEMENT =====
  User? _currentUser;
  UserPreferences? _currentUserPreferences;  // ADDED: Separate preferences
  UserProgress? _currentUserProgress;        // ADDED: Separate progress
  bool _isInitialized = false;

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
  UserPreferences? get currentUserPreferences => _currentUserPreferences;  // ADDED
  UserProgress? get currentUserProgress => _currentUserProgress;          // ADDED
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

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

  // ===== INITIALIZATION =====

  /// UPDATED: Enhanced initialization with separated models
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 [AppState] Initializing app state...');

      // Initialize progress tracking service first
      await ProgressTrackingService.instance.initialize();

      // Load user from Firebase with priority
      _currentUser = await _loadUserWithFirebasePriority();

      if (_currentUser != null) {
        debugPrint('👤 [AppState] User found: ${_currentUser!.username}');

        // UPDATED: Load preferences and progress separately
        await _loadUserData();

        // Initialize section progress if needed
        final existingProgress = await ProgressTrackingService.instance.getCurrentProgress();
        if (existingProgress.sectionProgress.isEmpty) {
          debugPrint('🔧 [AppState] No existing progress found, initializing sections...');
          await ProgressTrackingService.instance.initializeSectionProgress();
        }

        // Listen to progress changes
        ProgressTrackingService.instance.addListener(_onProgressChanged);

        // Sync any pending progress
        if (!_currentUser!.isDefaultUser) {
          ProgressTrackingService.instance.forceSyncToFirebase();
        }

        debugPrint('✅ [AppState] User initialized with separated models');
      } else {
        debugPrint('👤 [AppState] No user found, running in guest mode');
      }

      _isInitialized = true;
      notifyListeners();

      debugPrint('✅ [AppState] App state initialization complete');
    } catch (e) {
      debugPrint('❌ [AppState] Error initializing app state: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// UPDATED: Load user data separately (preferences and progress)
  Future<void> _loadUserData() async {
    try {
      // Load preferences
      _currentUserPreferences = await FirebaseUserService.instance.getUserPreferences();
      _currentUserPreferences ??= UserPreferences.defaults();

      // Load progress
      _currentUserProgress = await FirebaseUserService.instance.getUserProgress();
      _currentUserProgress ??= UserProgress.empty();

      // Load preferences into app state
      await loadUserPreferences(_currentUserPreferences!);

      debugPrint('✅ [AppState] User data loaded successfully');
    } catch (e) {
      debugPrint('❌ [AppState] Error loading user data: $e');
      // Use defaults on error
      _currentUserPreferences = UserPreferences.defaults();
      _currentUserProgress = UserProgress.empty();
      await loadUserPreferences(_currentUserPreferences!);
    }
  }

  /// Load user with Firebase priority
  Future<User?> _loadUserWithFirebasePriority() async {
    try {
      debugPrint('🔍 [AppState] Loading user with Firebase priority...');

      // Try Firebase first
      var user = await FirebaseUserService.instance.getCurrentUser();
      if (user != null) {
        debugPrint('☁️ [AppState] Found user via Firebase: ${user.username}');
        return user;
      }

      // Fallback to UserService
      debugPrint('🔍 [AppState] Firebase empty, trying UserService...');
      user = await UserService.instance.getCurrentUser();
      if (user != null) {
        debugPrint('📱 [AppState] Found user via UserService: ${user.username}');
        return user;
      }

      debugPrint('❌ [AppState] No user found in either service');
      return null;
    } catch (e) {
      debugPrint('❌ [AppState] Error loading user: $e');
      return null;
    }
  }

  // ===== USER MANAGEMENT METHODS =====

  /// UPDATED: Enhanced user setting with separated models
  Future<void> setCurrentUser(User user) async {
    debugPrint('👤 [AppState] Setting current user: ${user.username}');

    // Remove old progress listener
    if (_currentUser != null) {
      ProgressTrackingService.instance.removeListener(_onProgressChanged);
    }

    _currentUser = user;

    // Load user data separately
    await _loadUserData();

    // Setup progress tracking
    try {
      final existingProgress = await ProgressTrackingService.instance.getCurrentProgress();
      if (existingProgress.sectionProgress.isEmpty) {
        await ProgressTrackingService.instance.initializeSectionProgress();
      }

      ProgressTrackingService.instance.addListener(_onProgressChanged);

      if (!user.isDefaultUser) {
        await ProgressTrackingService.instance.onUserAuthenticated();
      }

      debugPrint('✅ [AppState] Enhanced progress tracking setup for user: ${user.username}');
    } catch (e) {
      debugPrint('❌ [AppState] Error setting up progress tracking: $e');
    }

    notifyListeners();
  }

  /// UPDATED: Load user preferences into app state
  Future<void> loadUserPreferences(UserPreferences preferences) async {
    debugPrint('⚙️ [AppState] Loading user preferences');

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

  /// UPDATED: Save current preferences to user
  Future<void> saveUserPreferences() async {
    if (_currentUser != null) {
      final updatedPreferences = (_currentUserPreferences ?? UserPreferences.defaults()).copyWith(
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

      await FirebaseUserService.instance.saveUserPreferences(updatedPreferences);
      _currentUserPreferences = updatedPreferences;
    }
  }

  /// UPDATED: Logout with separated models
  Future<void> logout({bool switchToGuest = true}) async {
    try {
      debugPrint('👤 [AppState] Logging out user...');

      // Clean up progress listener
      if (_currentUser != null) {
        ProgressTrackingService.instance.removeListener(_onProgressChanged);
      }

      // Always logout from UserService first
      await UserService.instance.logout();

      if (switchToGuest) {
        // Switch to guest user
        final guestUser = await UserService.instance.loginAsGuest();
        await setCurrentUser(guestUser);
        debugPrint('👤 [AppState] Switched to guest user');
      } else {
        // Complete logout
        _currentUser = null;
        _currentUserPreferences = null;
        _currentUserProgress = null;
        notifyListeners();
        debugPrint('👤 [AppState] Complete logout - cleared user');
      }
    } catch (e) {
      debugPrint('❌ [AppState] Error during logout: $e');
      ProgressTrackingService.instance.removeListener(_onProgressChanged);
      _currentUser = null;
      _currentUserPreferences = null;
      _currentUserProgress = null;
      notifyListeners();
      rethrow;
    }
  }

  // ===== ENHANCED PROGRESS TRACKING METHODS =====

  /// Handle progress changes and update UI
  void _onProgressChanged() {
    debugPrint('📈 [AppState] Progress changed - updating UI');
    notifyListeners();
    refreshUserProgress();
  }

  /// UPDATED: Force refresh user progress with separated models
  Future<void> refreshUserProgress() async {
    if (_currentUser != null) {
      try {
        debugPrint('🔄 [AppState] Refreshing user progress...');

        final freshProgress = await ProgressTrackingService.instance.getCurrentProgress();
        _currentUserProgress = freshProgress;

        notifyListeners();
        debugPrint('✅ [AppState] User progress refreshed');
      } catch (e) {
        debugPrint('❌ [AppState] Error refreshing user progress: $e');
      }
    }
  }

  /// Get current progress status
  Future<UserProgress> getCurrentProgress() async {
    try {
      return await ProgressTrackingService.instance.getCurrentProgress();
    } catch (e) {
      debugPrint('❌ [AppState] Error getting current progress: $e');
      return UserProgress.empty();
    }
  }

  /// Check if topic is completed
  Future<bool> isTopicCompleted(String topicId) async {
    try {
      return await ProgressTrackingService.instance.isTopicCompleted(topicId);
    } catch (e) {
      debugPrint('❌ [AppState] Error checking topic completion: $e');
      return false;
    }
  }

  /// Check if section is completed
  Future<bool> isSectionCompleted(String sectionId) async {
    try {
      return await ProgressTrackingService.instance.isSectionCompleted(sectionId);
    } catch (e) {
      debugPrint('❌ [AppState] Error checking section completion: $e');
      return false;
    }
  }

  /// Get section progress
  Future<SectionProgress?> getSectionProgress(String sectionId) async {
    try {
      return await ProgressTrackingService.instance.getSectionProgress(sectionId);
    } catch (e) {
      debugPrint('❌ [AppState] Error getting section progress: $e');
      return null;
    }
  }

  /// Force sync progress to Firebase
  Future<bool> syncProgressToFirebase() async {
    try {
      debugPrint('☁️ [AppState] Force syncing progress to Firebase...');
      final success = await ProgressTrackingService.instance.forceSyncToFirebase();

      if (success) {
        debugPrint('✅ [AppState] Progress synced to Firebase successfully');
      } else {
        debugPrint('⚠️ [AppState] Progress sync failed or skipped');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [AppState] Error syncing progress: $e');
      return false;
    }
  }

  /// Get sync status for debugging
  Map<String, dynamic> getSyncStatus() {
    return ProgressTrackingService.instance.getDetailedSyncStatus();
  }

  /// Manual sync debug method
  Future<Map<String, dynamic>> debugManualSync() async {
    return await ProgressTrackingService.instance.manualSyncDebug();
  }

  // ===== FRETBOARD DEFAULTS SETTERS =====
  void setDefaultStringCount(int count) {
    if (count < AppConstants.minStrings || count > AppConstants.maxStrings) return;
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
    final validOctaves = octaves.where((o) => o >= 0 && o <= AppConstants.maxOctaves).toSet();
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
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
  void applyStandardTuning(String tuningName) => applyStandardTuningAsDefault(tuningName);

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
    debugPrint('AppState toggleInterval: $extendedInterval, current intervals: $_selectedIntervals');

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
    final referenceOctave = _selectedOctaves.isEmpty ? 3 : _selectedOctaves.reduce((a, b) => a < b ? a : b);
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
    final validOctaves = octaves.where((o) => o >= 0 && o <= AppConstants.maxOctaves).toSet();
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
    _selectedOctaves = List.generate(AppConstants.maxOctaves + 1, (i) => i).toSet();
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
    _defaultTuning = List.from(MusicConstants.standardTunings['Guitar (6-string)']!);
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

  @override
  void dispose() {
    // Clean up progress listener
    if (_currentUser != null) {
      ProgressTrackingService.instance.removeListener(_onProgressChanged);
    }
    super.dispose();
  }
}