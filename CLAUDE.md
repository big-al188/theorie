# Theorie - Interactive Guitar Fretboard Theory App

## Project Overview
Theorie is a comprehensive Flutter web application for learning and exploring music theory on guitar fretboards. It provides interactive visualization of scales, chords, and intervals across multiple configurable fretboards, helping musicians understand the relationships between notes, patterns, and musical concepts through visual and hands-on learning. The application includes a complete quiz system with multiple question types, progress tracking, Firebase integration, and adaptive learning features.

## Core Features

### Music Theory Visualization
- **Multi-Fretboard Display**: Support for multiple simultaneous fretboard instances
- **Three Theory Modes**: Scales, intervals, and chord visualization with real-time switching
- **Interactive Controls**: Live updates for root notes, scale types, modes, octaves, and intervals
- **Visual Learning**: Color-coded notes based on scale degrees and interval relationships
- **Customizable Experience**: Multiple tunings, layouts, themes, and display options
- **Responsive Design**: Optimized for web browsers with adaptive layouts

### Comprehensive Quiz System
- **Multiple Question Types**: Multiple choice questions (single and multi-select) with detailed explanations and feedback
- **Topic-Based Learning**: Focused quizzes on specific music theory concepts (notes, intervals, scales, chords)
- **Section-Based Assessment**: Comprehensive quizzes covering multiple related topics
- **Progressive Difficulty**: Questions that adapt to user skill level (beginner to expert)
- **Performance Tracking**: Detailed quiz results, progress analytics, and learning insights
- **Timed Assessments**: Optional time limits with real-time countdown and time tracking
- **Educational Feedback**: Comprehensive explanations for both correct and incorrect answers
- **Session Management**: Complete lifecycle from quiz initialization to results analysis

### User Management & Persistence
- **Dual Authentication**: Complete user account system with Firebase authentication and guest access
- **Hybrid Storage**: Local storage with SharedPreferences and Firebase cloud synchronization
- **Progress Tracking**: Learning progress history and quiz performance analytics
- **Personalized Settings**: Individual user preferences and customizable configurations
- **Data Export/Import**: User data backup and restoration capabilities
- **Offline Support**: Full functionality without internet connection

## Technology Stack
- **Flutter**: 3.24.3 (stable channel, web-optimized)
- **Dart**: 3.5.3
- **State Management**: Provider 6.1.1 with ChangeNotifier pattern
- **Architecture**: Strict MVC (Model-View-Controller) with clear separation of concerns
- **Local Persistence**: SharedPreferences for user data and settings
- **Cloud Storage**: Firebase Firestore for authenticated user data synchronization
- **Authentication**: Firebase Authentication for user account management
- **Deployment**: GitLab Pages with automated CI/CD pipeline
- **Development Tools**: Flutter DevTools 2.37.3

## Architecture & Design Principles

### MVC Implementation
```
Models (Domain Logic & Data)
    ↓ Business Operations
Controllers (Music Theory & State Logic)  
    ↓ State Updates
Views (UI Components & Rendering)
    ↑ User Interactions
Provider (State Management & Notifications)
```

### Core Architectural Rules
1. **File Size Limit**: ~500 lines maximum for maintainability (exceptions: chord.dart with hundreds of chord variations, unified_quiz_generator.dart with comprehensive quiz logic)
2. **Single Responsibility**: Each file serves one clear, well-defined purpose
3. **Separation of Concerns**: Strict boundaries between models, controllers, and views
4. **No Business Logic in UI**: All music theory calculations isolated in controllers/utils
5. **Testable Design**: Business logic separated for easy unit testing
6. **Reusable Components**: Common functionality extracted to utilities and widgets

### State Flow & Data Management
1. **User Interactions** → Control Widgets → Controller Methods
2. **Controller Logic** → Model Updates → AppState Changes  
3. **State Notifications** → Provider Updates → Widget Rebuilds
4. **Persistence Layer** → UserService/FirebaseUserService → Local/Cloud Storage
5. **Quiz Flow** → QuizController → Quiz Models → Quiz UI Updates

## Music Theory Implementation

### Note System Architecture
- **MIDI Foundation**: All calculations based on MIDI note numbers (60 = Middle C)
- **Enharmonic Support**: Proper handling of sharps/flats (C# = Db, B# = C)
- **Octave Management**: Scientific pitch notation with flexible octave selection
- **Chromatic Base**: 12-tone equal temperament as calculation foundation

### Scale System Features  
- **20+ Scale Types**: Major, minor modes, pentatonic, blues, exotic scales
- **Modal Relationships**: Automatic mode rotation and root calculation
- **Pitch Class Sets**: Efficient scale membership testing and comparison
- **Mode Display**: Proper mode names and interval patterns

### Chord System Capabilities
- **Extensive Database**: Major, minor, diminished, augmented, extended chords
- **Inversion Support**: Root position, 1st, 2nd, 3rd inversions with proper voicing
- **Voice Leading**: Intelligent chord progression and voice movement
- **Fretboard Mapping**: Optimal fingering suggestions and chord shape analysis

### Fretboard Calculations
- **Multiple Tunings**: Standard (E-A-D-G-B-E) plus alternative tunings
- **Layout Options**: Right/left-handed, bass-top/bottom configurations  
- **Fret Positioning**: Accurate mathematical fret spacing and note placement
- **Visual Optimization**: Efficient coordinate calculation and rendering

## Quiz System Implementation

### Question Generation Architecture
- **Unified Generator**: Central system (`UnifiedQuizGenerator`) for creating all question types
- **Topic-Based Generation**: Specialized question creation for each music theory topic
- **Difficulty Progression**: Questions scaled from beginner to expert levels
- **Quality Assurance**: Comprehensive validation of question accuracy and educational value

### Supported Quiz Topics
- **Introduction Section**: What is Music Theory, Why Learn Theory, Practice Tips
- **Fundamentals Section**: Note relationships, scale construction, chord building (planned)
- **Advanced Topics**: Complex intervals, extended chords, modal theory (planned)
- **Progressive Learning**: Topics build upon each other for comprehensive understanding

### Question Types and Features
- **Multiple Choice**: Single and multi-select questions with detailed explanations
- **Rich Content**: Questions with musical examples and theoretical explanations
- **Adaptive Feedback**: Personalized explanations based on chosen answers
- **Performance Analytics**: Detailed tracking of answer patterns and learning progress

### Quiz Session Management
- **Session Lifecycle**: Complete management from initialization to results
- **Real-time Progress**: Live updates of completion status and timing
- **Answer Validation**: Sophisticated checking with immediate feedback
- **Results Analysis**: Comprehensive scoring and performance insights

## Learning Content Structure

### 8-Tier Learning System
- **Introduction**: Start your musical journey
- **Fundamentals**: Build essential knowledge
- **Essentials**: Core concepts for musicians
- **Intermediate**: Develop deeper understanding
- **Advanced**: Master complex concepts
- **Professional**: Industry-level expertise
- **Master**: Comprehensive mastery
- **Virtuoso**: Push the boundaries

### Content Organization
- **Structured Topics**: Each section contains multiple focused topics
- **Progressive Difficulty**: Topics build upon each other systematically
- **Flexible Access**: Users can access topics at their skill level
- **Comprehensive Coverage**: From basic note recognition to advanced harmony

## Persistence & Data Management

### Local Storage Strategy
- **SharedPreferences**: Primary storage for user preferences and offline data
- **Cache Management**: Efficient caching of frequently accessed data
- **Offline Support**: Full functionality without internet connection
- **Data Validation**: Comprehensive error handling and data integrity checks

### Cloud Sync Architecture
- **Firebase Integration**: Seamless sync between local and cloud storage
- **User Authentication**: Secure user account management with Firebase Auth
- **Data Synchronization**: Automatic sync of user progress and preferences
- **Conflict Resolution**: Intelligent handling of data conflicts between local and cloud

### Progress Tracking System
- **Real-time Updates**: Live tracking of learning progress and quiz performance
- **Analytics**: Detailed insights into user learning patterns
- **Export Capabilities**: Data backup and migration features
- **Performance Metrics**: Comprehensive tracking of quiz scores and topic completion

## Key Components & Responsibilities

### Models (`/models`)
- **Music Theory**: `Note`, `Scale`, `Chord`, `Interval` - Core music domain entities
- **Fretboard**: `FretboardConfig`, `FretboardInstance` - Display and state configuration  
- **User System**: `User`, `UserPreferences`, `UserProgress` - Account and learning management
- **Quiz System**: `QuizQuestion`, `MultipleChoiceQuestion`, `QuizSession`, `QuizResult` - Quiz infrastructure
- **Learning Content**: `LearningSection`, `LearningTopic`, `LearningLevel` - Educational content structure
- **App State**: `AppState` - Central state management with ChangeNotifier

### Controllers (`/controllers`) 
- **MusicController**: Music theory calculations, mode operations, note transformations
- **FretboardController**: Fretboard logic, note highlighting algorithms, visual mapping
- **ChordController**: Chord construction, voicing analysis, inversion handling
- **QuizController**: Quiz session management, answer validation, progress tracking
- **UnifiedQuizGenerator**: Comprehensive question generation system (>500 lines - justified)

### Views (`/views`)
- **Pages**: Full-screen interfaces (`LoginPage`, `WelcomePage`, `HomePage`, `FretboardPage`, `SettingsPage`, `LearningTopicsPage`, `QuizPage`)
- **Fretboard Widgets**: `FretboardWidget`, `FretboardPainter`, `ScaleStrip` - Core visualization
- **Control Widgets**: All user input components (selectors, dropdowns, checkboxes)
- **Quiz Widgets**: `QuizProgressBar`, `MultipleChoiceWidget`, `QuizResultsWidget` - Quiz interfaces
- **Dialogs**: Modal interfaces for settings and configuration

### Services (`/services`)
- **UserService**: Local user data management, authentication, persistence
- **FirebaseUserService**: Firebase authentication and cloud data sync
- **ProgressTrackingService**: Learning progress and quiz performance tracking
- **FirebaseDatabaseService**: Firebase Firestore operations and data management

## State Management Architecture

### Provider Pattern
```dart
// Global state access
final appState = Provider.of<AppState>(context);

// Targeted updates with selectors  
Consumer<AppState>(
  builder: (context, appState, child) => Widget(),
)

// State modifications
appState.updateRootNote(newNote);
appState.notifyListeners();
```

### Quiz State Management
```dart
// Quiz controller integration
final quizController = Provider.of<QuizController>(context);

// Quiz session lifecycle
await quizController.startQuiz(
  questions: questions,
  quizType: QuizType.topic,
  topicId: 'scales',
  title: 'Scale Knowledge Quiz'
);

// Answer submission and navigation
await quizController.submitAnswer(selectedAnswer);
await quizController.nextQuestion();
final result = await quizController.completeQuiz();
```

### Firebase Integration
```dart
// User authentication
final firebaseUserService = FirebaseUserService.instance;
await firebaseUserService.signInWithEmailPassword(email, password);

// Progress synchronization
final progressService = ProgressTrackingService.instance;
await progressService.syncTopicProgress(topicId, passed, sectionId);
```

## Performance & Optimization

### Rendering Performance
- **CustomPainter**: High-performance Canvas-based fretboard rendering
- **Selective Repainting**: `shouldRepaint` logic to minimize unnecessary updates
- **Color Caching**: Pre-calculated color maps for theory visualization
- **Widget Optimization**: Efficient widget composition and minimal rebuilds

### State Management Efficiency
- **Granular Updates**: Provider selectors for targeted widget rebuilds
- **Batch Operations**: Multiple state changes combined into single notifications
- **Memory Management**: Proper disposal of controllers and cached data
- **Responsive Calculations**: Optimized algorithms for real-time theory updates

### Quiz Performance
- **Efficient Question Generation**: Optimized algorithms for creating diverse questions
- **State Optimization**: Minimal rebuilds during quiz navigation and answer submission
- **Memory Management**: Proper cleanup of quiz sessions and cached results
- **Responsive UI**: Smooth transitions and animations during quiz interactions

### Firebase Optimization
- **Data Caching**: Intelligent caching strategies for reduced network calls
- **Batch Operations**: Efficient bulk updates for progress tracking
- **Offline Support**: Seamless operation without internet connectivity
- **Sync Strategies**: Smart synchronization to minimize data transfer

## Development Practices

### Code Organization Standards
- **Naming Conventions**: `snake_case.dart`, `PascalCase` classes, `camelCase` methods
- **Import Organization**: Relative imports for project files, package imports first
- **File Structure**: Logical grouping with clear hierarchies and dependencies
- **Documentation**: Comprehensive inline docs for complex music theory logic

### Quality Assurance
- **Static Analysis**: Comprehensive Flutter/Dart linting with custom rules
- **Unit Testing**: All music theory calculations and controller logic tested
- **Widget Testing**: Critical UI interactions and state management verified
- **Integration Testing**: End-to-end user workflows and multi-fretboard operations
- **Quiz Testing**: Comprehensive testing of question generation and quiz flow

### Common Development Tasks
1. **Adding Scale Types**: Update `music_constants.dart` intervals, test with `scale_utils.dart`
2. **New Chord Types**: Extend `chord.dart` formulas, update voicing algorithms  
3. **Custom Tunings**: Add to `music_constants.dart` presets, test fret calculations
4. **UI Components**: Follow widget patterns, implement proper state management
5. **Color Schemes**: Modify `color_utils.dart` generation algorithms for theory visualization
6. **Quiz Questions**: Add to appropriate section files, validate educational accuracy
7. **Firebase Integration**: Update service layers, test sync functionality

### Testing and Debugging
1. **Check Browser Console**: Web-specific errors and warnings
2. **Verify Music Constants**: Ensure scales/chords match music theory standards
3. **Test State Updates**: Confirm Provider notifications and widget rebuilds
4. **Validate Calculations**: Check MIDI numbers and interval mathematics
5. **Review Performance**: Profile CustomPainter and state management efficiency
6. **Quiz Validation**: Test question generation and answer checking logic
7. **User Flow Testing**: Verify complete quiz session lifecycle and results
8. **Firebase Testing**: Validate authentication and data synchronization

## Quiz System Development Guidelines

### Question Creation Standards
- **Educational Accuracy**: All questions must be musically and theoretically correct
- **Progressive Difficulty**: Questions should build from basic to advanced concepts
- **Clear Language**: Question text should be unambiguous and accessible
- **Comprehensive Feedback**: Explanations should enhance learning, not just confirm answers

### Quiz Flow Design
- **User Experience**: Smooth, intuitive navigation through quiz sessions
- **Progress Clarity**: Clear indication of progress and remaining time
- **Flexible Navigation**: Allow review of answers when appropriate
- **Meaningful Results**: Provide actionable feedback and learning suggestions

### Performance Considerations
- **Efficient Generation**: Question creation should be fast and memory-efficient
- **State Management**: Minimal rebuilds during quiz interactions
- **Responsive Design**: Quiz interface should work well on all screen sizes
- **Accessibility**: Support for different learning needs and interaction methods

## Recent Enhancements
- **Complete Quiz System**: Comprehensive quiz functionality with multiple question types
- **Firebase Integration**: Cloud storage and authentication system
- **Progress Tracking**: Advanced analytics and learning insights
- **Educational Content**: Structured learning topics and progressive content
- **User Experience**: Improved navigation and responsive design
- **Performance Optimizations**: Enhanced rendering and state management

## Future Considerations
- **Audio Integration**: MIDI playback and audio generation for quiz questions
- **Advanced Question Types**: Interactive fretboard questions, audio-based questions, and visual exercises
- **Social Features**: Shared quiz sessions and collaborative learning
- **Mobile Support**: Native mobile app development
- **Advanced Analytics**: Machine learning-based learning recommendations
- **Gamification**: Achievement systems and learning rewards
- **Content Expansion**: Additional instruments (piano, bass, ukulele)
- **Advanced Theory**: Complex harmony, jazz theory, and composition tools

## Development Guidelines
- **File Organization**: Each file serves a single, clear purpose
- **Size Constraints**: Maintain files under 500 lines except when strongly justified
- **Testing**: Write tests for all business logic and critical UI components
- **Documentation**: Keep inline documentation current with code changes
- **Performance**: Profile and optimize rendering and state management regularly
- **Quiz Quality**: Ensure all quiz questions are educationally valuable and technically accurate
- **User Experience**: Prioritize intuitive navigation and responsive design
- **Data Integrity**: Implement comprehensive error handling and data validation