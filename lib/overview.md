# Theorie - Project Structure Overview

## Project Description
Theorie is a comprehensive Flutter web application for interactive guitar fretboard theory learning. It provides real-time visualization of scales, chords, and intervals across configurable fretboards, helping musicians understand music theory concepts through visual and interactive learning. The application includes a complete quiz system with multiple question types, progress tracking, and adaptive learning features.

## Architecture
The application follows strict MVC (Model-View-Controller) architecture with clear separation of concerns:

- **Models**: Data structures and domain entities for music theory, fretboard configuration, quiz system, and user management
- **Controllers**: Business logic for music calculations, fretboard rendering, state management, quiz operations, and question generation
- **Views**: UI components including pages, widgets, and dialogs for theory visualization and quiz interfaces
- **Services**: User management, data persistence, progress tracking, and Firebase integration
- **Utils**: Helper functions for music theory calculations, color generation, and quiz utilities
- **Constants**: Configuration values, music theory data, and quiz constants

## Key Architectural Principles
1. **File Size Limit**: All files maintained around or under 500 lines unless strongly justified (e.g., chord.dart with hundreds of chord variations, unified_quiz_generator.dart with comprehensive quiz logic)
2. **MVC Separation**: Clear separation between models, controllers, and views
3. **Separation of Concerns**: Each file has a single, well-defined responsibility
4. **Reusability**: Common functionality extracted into utility modules
5. **Testability**: Business logic isolated from UI for easy unit testing
6. **Performance**: Efficient rendering with CustomPainter and selective repainting

## Core Features

### Music Theory Visualization
- **Multi-Fretboard Display**: Support for multiple simultaneous fretboard instances
- **Three Theory Modes**: Scales, intervals, and chord visualization with real-time switching
- **Interactive Controls**: Live updates for root notes, scale types, modes, octaves, and intervals
- **Visual Learning**: Color-coded notes based on scale degrees and interval relationships
- **Customizable Experience**: Multiple tunings, layouts, themes, and display options
- **Responsive Design**: Optimized for web browsers with adaptive layouts

### Comprehensive Quiz System
- **Multiple Question Types**: Multiple choice questions (single and multi-select) with detailed explanations
- **Topic-Based Learning**: Focused quizzes on specific music theory concepts
- **Section-Based Assessment**: Comprehensive quizzes covering multiple related topics
- **Progressive Difficulty**: Questions that adapt to user skill level (beginner to expert)
- **Performance Tracking**: Detailed quiz results, progress analytics, and learning insights
- **Timed Assessments**: Optional time limits with real-time countdown and time tracking
- **Educational Feedback**: Comprehensive explanations for both correct and incorrect answers
- **Session Management**: Complete lifecycle from quiz start to results analysis

### User Management & Persistence
- **Dual Authentication**: Complete user account system with Firebase authentication and guest access
- **Hybrid Storage**: Local storage with SharedPreferences and Firebase cloud sync
- **Progress Tracking**: Learning progress history and quiz performance analytics
- **User Preferences**: Personalized settings and customizable configurations
- **Data Export/Import**: User data backup and restoration capabilities
- **Offline Support**: Full functionality without internet connection

## Technology Stack
- **Framework**: Flutter 3.24.3 (web-optimized)
- **Language**: Dart 3.5.3
- **State Management**: Provider 6.1.1 with ChangeNotifier pattern
- **Architecture**: Strict MVC (Model-View-Controller) with clear separation of concerns
- **Local Persistence**: SharedPreferences for user data and settings
- **Cloud Storage**: Firebase Firestore for authenticated user data sync
- **Authentication**: Firebase Authentication for user account management
- **Deployment**: GitLab Pages with automated CI/CD pipeline
- **Development Tools**: Flutter DevTools 2.37.3

## State Management Architecture

### Provider Pattern Implementation
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
- **Difficulty Scaling**: Questions adapted to different skill levels
- **Quality Assurance**: Comprehensive validation of question accuracy

### Quiz Session Management
- **Session Lifecycle**: Complete management of quiz sessions from start to finish
- **Progress Tracking**: Real-time progress monitoring and time management
- **Answer Validation**: Sophisticated answer checking and feedback generation
- **Results Calculation**: Detailed scoring and performance analysis

### Learning Content Structure
- **8-Tier System**: Introduction → Fundamentals → Essentials → Intermediate → Advanced → Professional → Master → Virtuoso
- **Topic Organization**: Each section contains multiple focused topics
- **Progressive Learning**: Topics build upon each other for comprehensive understanding
- **Flexible Access**: Users can access topics at their skill level

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

## Performance Optimizations
- **Efficient Rendering**: CustomPainter with selective repainting
- **State Granularity**: Targeted widget updates using Provider selectors
- **Memory Management**: Cached calculations and optimized color generation
- **Responsive UI**: Adaptive layouts and efficient widget composition
- **Quiz Performance**: Optimized question generation and state management
- **Firebase Optimization**: Efficient data synchronization and caching strategies

## Development Workflow
- **Architecture**: Strict MVC pattern enforcement
- **Code Quality**: Comprehensive linting and formatting standards
- **Testing Strategy**: Unit tests for business logic, widget tests for UI
- **CI/CD**: Automated builds and deployment to GitLab Pages
- **Version Control**: GitLab primary, GitHub mirror for lib/ directory
- **Documentation**: Comprehensive inline documentation and architectural guides

## File Organization Standards
- **Naming Conventions**: `snake_case.dart`, `PascalCase` classes, `camelCase` methods
- **Import Organization**: Relative imports for project files, package imports first
- **File Structure**: Logical grouping with clear hierarchies and dependencies
- **Size Constraints**: Maintain files under 500 lines except when strongly justified

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