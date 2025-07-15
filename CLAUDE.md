# Theorie - Interactive Guitar Fretboard Theory App

## Project Overview
Theorie is a Flutter web application for learning and exploring music theory on guitar fretboards. It provides interactive visualization of scales, chords, and intervals across multiple configurable fretboards, helping musicians understand the relationships between notes, patterns, and musical concepts through visual and hands-on learning. The application now includes a comprehensive quiz system for testing and reinforcing music theory knowledge through interactive educational content.

## Core Features

### Music Theory Visualization
- **Multi-Fretboard Display**: Support for multiple simultaneous fretboard instances
- **Three Theory Modes**: Scales, intervals, and chord visualization with real-time switching
- **Interactive Controls**: Live updates for root notes, scale types, modes, octaves, and intervals
- **Visual Learning**: Color-coded notes based on scale degrees and interval relationships
- **Customizable Experience**: Multiple tunings, layouts, themes, and display options
- **Responsive Design**: Optimized for web browsers with adaptive layouts

### Comprehensive Quiz System (NEW)
- **Multiple Question Types**: Multiple choice questions with detailed explanations and feedback
- **Topic-Based Learning**: Focused quizzes on specific music theory concepts (notes, intervals, scales, chords)
- **Section-Based Assessment**: Comprehensive quizzes covering multiple related topics
- **Progressive Difficulty**: Questions that adapt to user skill level (beginner to expert)
- **Performance Tracking**: Detailed quiz results, progress analytics, and learning insights
- **Timed Assessments**: Optional time limits with real-time countdown and time tracking
- **Educational Feedback**: Comprehensive explanations for both correct and incorrect answers

### User Management
- **Registration and Login**: Complete user account system with secure authentication
- **Guest Access**: Full functionality without account creation for immediate use
- **Personalized Settings**: Individual user preferences and customizable configurations
- **Progress Tracking**: Learning progress history and quiz performance analytics

## Technology Stack
- **Flutter**: 3.24.3 (stable channel, web-optimized)
- **Dart**: 3.5.3
- **State Management**: Provider 6.1.1 with ChangeNotifier pattern
- **Architecture**: Strict MVC (Model-View-Controller) with clear separation of concerns
- **Persistence**: SharedPreferences for user data and settings
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

## Key Components & Responsibilities

### Models (`/models`)
- **Music Theory**: `Note`, `Scale`, `Chord`, `Interval` - Core music domain entities
- **Fretboard**: `FretboardConfig`, `FretboardInstance` - Display and state configuration  
- **User System**: `User`, `UserPreferences`, `UserProgress` - Account and learning management
- **Quiz System** (NEW): `QuizQuestion`, `MultipleChoiceQuestion`, `QuizSession`, `QuizResult` - Quiz infrastructure
- **App State**: `AppState` - Central state management with ChangeNotifier

### Controllers (`/controllers`) 
- **MusicController**: Music theory calculations, mode operations, note transformations
- **FretboardController**: Fretboard logic, note highlighting algorithms, visual mapping
- **ChordController**: Chord construction, voicing analysis, inversion handling
- **QuizController** (NEW): Quiz session management, answer validation, progress tracking
- **UnifiedQuizGenerator** (NEW): Comprehensive question generation system (>500 lines - justified)

### Views (`/views`)
- **Pages**: Full-screen interfaces (`LoginPage`, `WelcomePage`, `HomePage`, `FretboardPage`, `SettingsPage`, `LearningTopicsPage`, `QuizPage`)
- **Fretboard Widgets**: `FretboardWidget`, `FretboardPainter`, `ScaleStrip` - Core visualization
- **Control Widgets**: All user input components (selectors, dropdowns, checkboxes)
- **Quiz Widgets** (NEW): `QuizProgressBar`, `MultipleChoiceWidget`, `QuizResultsWidget` - Quiz interfaces
- **Dialogs**: Modal interfaces for settings and configuration

### Services (`/services`)
- **UserService**: Complete user data management, authentication, persistence, import/export
- **QuizIntegrationService** (NEW): Quiz system integration and coordination

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

### Quiz State Management (NEW)
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

### State Flow & Data Management
1. **User Interactions** → Control Widgets → Controller Methods
2. **Controller Logic** → Model Updates → AppState Changes  
3. **State Notifications** → Provider Updates → Widget Rebuilds
4. **Persistence Layer** → UserService → SharedPreferences Storage
5. **Quiz Flow** → QuizController → Quiz Models → Quiz UI Updates (NEW)

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

## Quiz System Implementation (NEW)

### Question Generation Architecture
- **Unified Generator**: Central system (`UnifiedQuizGenerator`) for creating all question types
- **Topic-Based Generation**: Specialized question creation for each music theory topic
- **Difficulty Progression**: Questions scaled from beginner to expert levels
- **Quality Assurance**: Comprehensive validation of question accuracy and educational value

### Supported Quiz Topics
- **Introduction Section**: What is Music Theory, Reading Musical Notes, Basic Intervals
- **Fundamentals Section**: Note Relationships, Scale Construction, Chord Building
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

### Quiz Performance (NEW)
- **Efficient Question Generation**: Optimized algorithms for creating diverse questions
- **State Optimization**: Minimal rebuilds during quiz navigation and answer submission
- **Memory Management**: Proper cleanup of quiz sessions and cached results
- **Responsive UI**: Smooth transitions and animations during quiz interactions

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
- **Quiz Testing** (NEW): Comprehensive testing of question generation and quiz flow

### Common Development Tasks
1. **Adding Scale Types**: Update `music_constants.dart` intervals, test with `scale_utils.dart`
2. **New Chord Types**: Extend `chord.dart` formulas, update voicing algorithms  
3. **Custom Tunings**: Add to `music_constants.dart` presets, test fret calculations
4. **UI Components**: Follow widget patterns, implement proper state management
5. **Color Schemes**: Modify `color_utils.dart` generation algorithms for theory visualization
6. **Quiz Questions** (NEW): Add questions to `unified_quiz_generator.dart`, ensure educational accuracy

## Debugging & Development Tools

### Debugging Strategies
- **Flutter Inspector**: Widget tree analysis and performance profiling
- **Browser DevTools**: Web-specific debugging and network monitoring
- **Debug Prints**: Controlled logging in controllers for calculation verification
- **Visual Debugging**: `debugPaintSizeEnabled` for layout analysis

### Music Theory Validation
- **Interval Accuracy**: Verify all semitone calculations and enharmonic equivalents
- **Mode Relationships**: Test scale rotation and root note calculations
- **Chord Formulas**: Validate interval patterns and inversion logic
- **Edge Cases**: Handle unusual note names (B#, Cb) and octave boundaries

### Quiz System Validation (NEW)
- **Question Accuracy**: Verify all quiz questions have correct answers and explanations
- **Educational Value**: Ensure questions effectively test music theory knowledge
- **Answer Validation**: Test answer checking logic for all question types
- **Progress Tracking**: Validate score calculation and progress analytics

## Deployment & CI/CD

### Build Configuration
- **Web Optimization**: CanvasKit renderer for performance, HTML renderer for compatibility
- **Asset Management**: Efficient bundling and loading strategies
- **Environment Configuration**: Production vs development build variations

### GitLab Integration
- **Primary Repository**: GitLab with full project including assets and CI/CD
- **GitHub Mirror**: `lib/` and `test/` directories only for public access
- **Automated Deployment**: GitLab Pages with branch-based deployment strategies
- **Build Artifacts**: Optimized web builds with proper caching headers

## Security & User Data

### User Management
- **Guest Access**: Full functionality without account creation
- **Data Privacy**: Local storage only, no external data transmission
- **Session Management**: Secure user state handling and logout procedures
- **Data Export**: User progress and settings backup/restore functionality

### Quiz Data Security (NEW)
- **Local Storage**: All quiz progress stored locally for privacy
- **Session Integrity**: Secure quiz session management and validation
- **Performance Privacy**: User quiz results remain on device only

## Testing Strategy

### Unit Testing Focus Areas
- **Music Theory**: All note, scale, chord, and interval calculations
- **Controllers**: State management logic and theory transformations
- **Utilities**: Helper functions and mathematical operations
- **Edge Cases**: Boundary conditions and error handling
- **Quiz Logic** (NEW): Question generation, answer validation, and scoring algorithms

### Widget Testing Priorities  
- **User Interactions**: Control widget responses and state propagation
- **Fretboard Rendering**: Visual accuracy and performance validation
- **Multi-Instance**: Multiple fretboard coordination and independence
- **Responsive Behavior**: Layout adaptation and screen size handling
- **Quiz Interface** (NEW): Quiz widget interactions and state management

## Known Limitations & Considerations

### Web Platform Constraints
- **File System Access**: No local file operations, SharedPreferences only
- **Audio Limitations**: No native audio, future MIDI/Web Audio API integration needed
- **Performance Variations**: Browser-dependent rendering performance differences
- **Mobile Web**: Touch interaction limitations compared to native mobile apps

### Quiz System Limitations (NEW)
- **Question Types**: Currently limited to multiple choice (expandable architecture)
- **Audio Integration**: No audio-based questions yet (planned for future)
- **Offline Capability**: Requires internet connection for initial load
- **Advanced Analytics**: Basic progress tracking (enhanced analytics planned)

### Future Enhancement Areas
- **Audio Integration**: MIDI playback, chord strumming, scale playing for quiz questions
- **Advanced Question Types**: Interactive fretboard questions, audio identification, ear training
- **Enhanced Analytics**: Detailed learning analytics and adaptive content delivery
- **Social Features**: Shared quiz sessions, leaderboards, collaborative learning
- **Mobile Native**: iOS/Android apps with platform-specific optimizations
- **Gamification**: Achievement systems, learning streaks, and progress rewards

## Critical Development Rules

### Do Not
- **Hardcode Music Data**: Always use constants and utility functions for music theory
- **Mix UI with Logic**: Keep business logic out of widget build methods
- **Bypass Utilities**: Use existing helper functions for calculations
- **Assume Tuning**: Always check current tuning configuration
- **Ignore File Size**: Maintain size limits except for strongly justified cases
- **Create Inaccurate Quiz Content** (NEW): All quiz questions must be musically and theoretically correct

### Always Do  
- **Test Music Theory**: Verify all calculations with known musical examples
- **Document Complex Logic**: Explain non-obvious music theory implementations
- **Handle Edge Cases**: Account for unusual note names and boundary conditions
- **Optimize Performance**: Profile rendering and state management regularly
- **Update Documentation**: Keep this file current with architectural changes
- **Validate Quiz Content** (NEW): Ensure all quiz questions are educationally valuable and accurate

## Emergency Debugging Checklist
1. **Check Browser Console**: Web-specific errors and warnings
2. **Verify Music Constants**: Ensure scales/chords match music theory standards
3. **Test State Updates**: Confirm Provider notifications and widget rebuilds
4. **Validate Calculations**: Check MIDI numbers and interval mathematics
5. **Review Performance**: Profile CustomPainter and state management efficiency
6. **Quiz Validation** (NEW): Test question generation and answer checking logic
7. **User Flow Testing** (NEW): Verify complete quiz session lifecycle and results

## Quiz System Development Guidelines (NEW)

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