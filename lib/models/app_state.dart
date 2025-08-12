// lib/models/app_state.dart - Updated with audio preferences integration and subscription service
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../../controllers/music_controller.dart';
import '../../controllers/audio_controller.dart'; // Audio controller import
import '../constants/music_constants.dart';
import 'fretboard/fretboard_config.dart';
import 'fretboard/fretboard_instance.dart';
import 'music/chord.dart';
import 'music/note.dart';
import 'user/user.dart';
import 'user/user_preferences.dart';  // Separated models
import 'user/user_progress.dart';     // Separated models
import 'subscription/subscription_models.dart'; // NEW: Subscription models
import '../services/user_service.dart';
import '../services/progress_tracking_service.dart';
import '../services/firebase_user_service.dart';
import '../services/subscription_service.dart'; // NEW: Subscription service

/// Central application state management
/// UPDATED: Enhanced for separated user models architecture, audio system, and subscription integration
class AppState extends ChangeNotifier {
  // ===== USER MANAGEMENT =====
  User? _currentUser;
  UserPreferences? _currentUserPreferences;  // Separate preferences
  UserProgress? _currentUserProgress;        // Separate progress
  bool _isInitialized = false;

  // ===== SUBSCRIPTION MANAGEMENT - NEW =====
  SubscriptionService? _subscriptionService;
  bool _subscriptionInitialized = false;

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

  // ===== AUDIO PREFERENCES =====
  AudioBackend _audioBackend = AudioBackend.midi;
  double _audioVolume = 0.7;
  Duration _melodyNoteDuration = const Duration(milliseconds: 500);
  Duration _melodyGapDuration = const Duration(milliseconds: 50);
  Duration _harmonyDuration = const Duration(milliseconds: 2000);
  int _defaultVelocity = 100;
  bool _audioEnabled = true;

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
  UserPreferences? get currentUserPreferences => _currentUserPreferences;
  UserProgress? get currentUserProgress => _currentUserProgress;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  // ===== SUBSCRIPTION GETTERS - NEW =====
  SubscriptionService get subscriptionService => 
      _subscriptionService ??= SubscriptionService.instance;
  
  SubscriptionData get currentSubscription {
    if (_subscriptionService == null || !_subscriptionInitialized) {
      return SubscriptionData.empty();
    }
    return _subscriptionService!.currentSubscription;
  }
  
  bool get hasActiveSubscription {
    if (_subscriptionService == null || !_subscriptionInitialized) {
      return false;
    }
    return _subscriptionService!.hasActiveSubscription;
  }
  
  bool get isSubscriptionInitialized => _subscriptionInitialized;

  String get subscriptionTierDisplayName {
    return currentSubscription.tier.displayName;
  }

  bool get subscriptionNeedsAttention {
    return currentSubscription.needsPaymentUpdate;
  }

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

  // ===== AUDIO PREFERENCES GETTERS =====
  AudioBackend get audioBackend => _audioBackend;
  double get audioVolume => _audioVolume;
  Duration get melodyNoteDuration => _melodyNoteDuration;
  Duration get melodyGapDuration => _melodyGapDuration;
  Duration get harmonyDuration => _harmonyDuration;
  int get defaultVelocity => _defaultVelocity;
  bool get audioEnabled => _audioEnabled;

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

  // Derived getters - UPDATED for new ViewMode structure
  bool get isLeftHanded => _defaultLayout.isLeftHanded;
  bool get isBassTop => _defaultLayout.isBassTop;
  bool get isScaleMode => _viewMode == ViewMode.scales;
  bool get isIntervalMode => _viewMode == ViewMode.intervals;
  bool get isChordMode => _viewMode.isChordMode; // Use ViewMode helper
  bool get isChordInversionMode => _viewMode == ViewMode.chordInversions;
  bool get isOpenChordMode => _viewMode == ViewMode.openChords;
  bool get isBarreChordMode => _viewMode == ViewMode.barreChords;
  bool get isAdvancedChordMode => _viewMode == ViewMode.advancedChords;

  String get effectiveRoot => isScaleMode
      ? MusicController.getModeRoot(_root, _scale, _modeIndex)
      : _root;

  List<String> get availableModes => MusicController.getAvailableModes(_scale);

  String get currentModeName => availableModes.isNotEmpty
      ? availableModes[_modeIndex % availableModes.length]
      : 'Mode ${_modeIndex + 1}';

  // ===== INITIALIZATION =====

  /// UPDATED: Enhanced initialization with separated models, audio system, and subscription service
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

        // Load preferences and progress separately
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

      // Initialize audio system with loaded preferences
      await _initializeAudioSystem();

      // NEW: Initialize subscription service
      await _initializeSubscriptionService();

      _isInitialized = true;
      notifyListeners();

      debugPrint('✅ [AppState] App state initialization complete');
    } catch (e) {
      debugPrint('❌ [AppState] Error initializing app state: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Initialize audio system with user preferences
  Future<void> _initializeAudioSystem() async {
    try {
      debugPrint('🎵 [AppState] Initializing audio system...');
      
      // Initialize audio controller with current backend
      await AudioController.instance.initialize(_audioBackend);
      await AudioController.instance.setVolume(_audioVolume);
      
      debugPrint('✅ [AppState] Audio system initialized successfully');
    } catch (e) {
      debugPrint('❌ [AppState] Error initializing audio system: $e');
      // Continue without audio - the system will gracefully handle this
    }
  }

  /// NEW: Initialize subscription service
  Future<void> _initializeSubscriptionService() async {
    try {
      debugPrint('💳 [AppState] Initializing subscription service...');
      
      // Only initialize for authenticated users
      if (_currentUser == null || _currentUser!.isDefaultUser) {
        debugPrint('ℹ️ [AppState] Skipping subscription service for guest user');
        _subscriptionInitialized = true;
        return;
      }
      
      _subscriptionService = SubscriptionService.instance;
      
      // Initialize the subscription service
      await _subscriptionService!.initialize();
      
      // Listen to subscription changes
      _subscriptionService!.addListener(_onSubscriptionChanged);
      
      _subscriptionInitialized = true;
      debugPrint('✅ [AppState] Subscription service initialized successfully');
    } catch (e) {
      debugPrint('❌ [AppState] Error initializing subscription service: $e');
      _subscriptionInitialized = true;
      // Continue without subscription service - graceful degradation
    }
  }

  /// NEW: Handle subscription changes
  void _onSubscriptionChanged() {
    debugPrint('🔄 [AppState] Subscription status changed - updating UI');
    notifyListeners();
  }


  /// NEW: Check if user has access to premium features
  bool hasAccessToFeature(String featureId) {
    // For now, just check if user has active subscription
    // You can expand this to check specific features
    switch (featureId) {
      case 'advanced_analytics':
      case 'cloud_sync':
      case 'premium_themes':
      case 'audio_playback':
      case 'offline_mode':
      case 'priority_support':
      case 'advanced_quiz_features':
      case 'learning_path_recommendations':
        return hasActiveSubscription;
      case 'basic_features':
      case 'basic_quizzes':
      case 'basic_fretboard':
        return true; // Always available
      default:
        return hasActiveSubscription;
    }
  }

  /// Load user data separately (preferences and progress)
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

  /// UPDATED: Enhanced user setting with separated models and subscription service
  Future<void> setCurrentUser(User user) async {
    try {
      debugPrint('👤 [AppState] Setting current user: ${user.isDefaultUser ? 'Guest' : user.username}');
      
      // Clean up previous user if switching users (not initial load)
      if (_currentUser != null && _currentUser!.id != user.id) {
        debugPrint('🔄 [AppState] Switching users - cleaning up previous user data');
        
        // Remove progress listener for previous user
        ProgressTrackingService.instance.removeListener(_onProgressChanged);
        
        // NEW: Clean up subscription service for previous user
        if (_subscriptionService != null) {
          _subscriptionService!.removeListener(_onSubscriptionChanged);
          await _subscriptionService!.clearSubscription();
          await _subscriptionService!.resetForUserSwitch();
        }
        
        // NEW: Clear all cached data for the previous user (including subscription data)
        await UserService.instance.clearUserSpecificData(_currentUser!.id);
        
        _subscriptionInitialized = false;
      }
      
      _currentUser = user;
      
      // Load user data for non-guest users
      if (!user.isDefaultUser) {
        await _loadUserData();
        
        // Start listening to progress changes
        ProgressTrackingService.instance.addListener(_onProgressChanged);
        
        // NEW: Re-initialize subscription service for new user
        await _initializeSubscriptionService();
      } else {
        // For guest users, use defaults
        _currentUserPreferences = UserPreferences.defaults();
        _currentUserProgress = UserProgress.empty();
        
        // NEW: Ensure guest users have empty subscription state
        if (_subscriptionService != null) {
          await _subscriptionService!.clearSubscription();
        }
        _subscriptionInitialized = true; // Mark as initialized but empty
      }
      
      notifyListeners();
      debugPrint('✅ [AppState] Current user set successfully');
    } catch (e) {
      debugPrint('❌ [AppState] Error setting current user: $e');
      rethrow;
    }
  }

  /// Load user preferences into app state with integrated audio preferences
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
    
    // Load audio preferences (use new fields, fallback to existing ones)
    _audioBackend = preferences.audioBackend;
    _audioVolume = preferences.soundVolume; // Use existing soundVolume field
    _melodyNoteDuration = preferences.melodyNoteDuration;
    _melodyGapDuration = preferences.melodyGapDuration;
    _harmonyDuration = preferences.harmonyDuration;
    _defaultVelocity = preferences.defaultVelocity;
    _audioEnabled = preferences.audioEnabled && preferences.playSounds; // Combine both flags

    // Also update current session state to match defaults
    _root = _defaultRoot;
    _viewMode = _defaultViewMode;
    _scale = _defaultScale;
    _selectedOctaves = Set.from(_defaultSelectedOctaves);

    notifyListeners();
  }

  /// Save current preferences to user with integrated audio preferences
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
        // Save audio preferences (update both old and new fields for compatibility)
        audioBackend: _audioBackend,
        soundVolume: _audioVolume, // Update existing soundVolume field
        melodyNoteDuration: _melodyNoteDuration,
        melodyGapDuration: _melodyGapDuration,
        harmonyDuration: _harmonyDuration,
        defaultVelocity: _defaultVelocity,
        audioEnabled: _audioEnabled,
        playSounds: _audioEnabled, // Keep existing playSounds in sync
      );

      await FirebaseUserService.instance.saveUserPreferences(updatedPreferences);
      _currentUserPreferences = updatedPreferences;
    }
  }

  /// UPDATED: Enhanced logout with subscription cleanup
  Future<void> logout({bool switchToGuest = true}) async {
    try {
      debugPrint('👋 [AppState] Logging out user...');

      // Clean up progress listener
      if (_currentUser != null) {
        ProgressTrackingService.instance.removeListener(_onProgressChanged);
      }

      // ENHANCED: Complete subscription cleanup
      if (_subscriptionService != null) {
        debugPrint('🧹 [AppState] Cleaning up subscription service...');
        _subscriptionService!.removeListener(_onSubscriptionChanged);
        await _subscriptionService!.clearSubscription();
        
        // Reset for next user
        await _subscriptionService!.resetForUserSwitch();
        _subscriptionInitialized = false;
      }

      // Stop any playing audio
      await AudioController.instance.stopAll();

      // Always logout from UserService first
      await UserService.instance.logout();

      if (switchToGuest) {
        // Switch to guest user with clean state
        final guestUser = await UserService.instance.loginAsGuest();
        await setCurrentUser(guestUser);
        debugPrint('👤 [AppState] Switched to guest user');
      } else {
        // Complete logout
        _currentUser = null;
        _currentUserPreferences = null;
        _currentUserProgress = null;
        _subscriptionInitialized = false;
        notifyListeners();
        debugPrint('👤 [AppState] Complete logout - cleared user');
      }
    } catch (e) {
      debugPrint('❌ [AppState] Error during logout: $e');
      // Ensure cleanup happens even on error
      ProgressTrackingService.instance.removeListener(_onProgressChanged);
      _currentUser = null;
      _currentUserPreferences = null;
      _currentUserProgress = null;
      _subscriptionInitialized = false;
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

  /// Force refresh user progress with separated models
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
    } else if (mode.isChordMode) {
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
      if (_defaultViewMode.isChordMode && validOctaves.length > 1) {
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

  // ===== AUDIO PREFERENCES SETTERS =====
  Future<void> setAudioBackend(AudioBackend backend) async {
    if (_audioBackend != backend) {
      _audioBackend = backend;
      await AudioController.instance.switchBackend(backend);
      await saveUserPreferences();
      notifyListeners();
    }
  }

  Future<void> setAudioVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    if (_audioVolume != clampedVolume) {
      _audioVolume = clampedVolume;
      await AudioController.instance.setVolume(_audioVolume);
      await saveUserPreferences();
      notifyListeners();
    }
  }

  Future<void> setMelodyNoteDuration(Duration duration) async {
    if (_melodyNoteDuration != duration) {
      _melodyNoteDuration = duration;
      await saveUserPreferences();
      notifyListeners();
    }
  }

  Future<void> setMelodyGapDuration(Duration duration) async {
    if (_melodyGapDuration != duration) {
      _melodyGapDuration = duration;
      await saveUserPreferences();
      notifyListeners();
    }
  }

  Future<void> setHarmonyDuration(Duration duration) async {
    if (_harmonyDuration != duration) {
      _harmonyDuration = duration;
      await saveUserPreferences();
      notifyListeners();
    }
  }

  Future<void> setDefaultVelocity(int velocity) async {
    final clampedVelocity = velocity.clamp(1, 127);
    if (_defaultVelocity != clampedVelocity) {
      _defaultVelocity = clampedVelocity;
      await saveUserPreferences();
      notifyListeners();
    }
  }

  Future<void> setAudioEnabled(bool enabled) async {
    if (_audioEnabled != enabled) {
      _audioEnabled = enabled;
      if (!enabled) {
        await AudioController.instance.stopAll();
      }
      await saveUserPreferences();
      notifyListeners();
    }
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
    } else if (mode.isChordMode) {
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
    // Reset audio preferences to match UserPreferences.defaults()
    _audioBackend = AudioBackend.midi;
    _audioVolume = 0.5; // Match UserPreferences default soundVolume
    _melodyNoteDuration = const Duration(milliseconds: 500);
    _melodyGapDuration = const Duration(milliseconds: 50);
    _harmonyDuration = const Duration(milliseconds: 2000);
    _defaultVelocity = 100;
    _audioEnabled = true;
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
    // Clean up subscription listener
    if (_subscriptionService != null) {
      _subscriptionService!.removeListener(_onSubscriptionChanged);
    }
    // Clean up audio system
    AudioController.instance.dispose();
    super.dispose();
  }
}