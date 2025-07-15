# Theorie - Project Structure Overview

## Project Description
Theorie is a comprehensive Flutter web application for interactive guitar fretboard theory learning. It provides real-time visualization of scales, chords, and intervals across configurable fretboards, helping musicians understand music theory concepts through visual and interactive learning. The application now includes a complete quiz system for testing and reinforcing music theory knowledge.

## Architecture
The application follows strict MVC (Model-View-Controller) architecture with clear separation of concerns:

- **Models**: Data structures and domain entities for music theory, fretboard configuration, and quiz system
- **Controllers**: Business logic for music calculations, fretboard rendering, state management, and quiz operations
- **Views**: UI components including pages, widgets, and dialogs for theory visualization and quiz interfaces
- **Utils**: Helper functions for music theory calculations, color generation, and quiz utilities
- **Constants**: Configuration values, music theory data, and quiz constants
- **Services**: User management, data persistence, and quiz integration

## Key Architectural Principles
1. **File Size Limit**: All files maintained around or under 500 lines unless strongly justified (e.g., chord.dart with hundreds of chord variations, unified_quiz_generator.dart with comprehensive quiz logic)
2. **MVC Separation**: Clear separation between models, controllers, and views
3. **Separation of Concerns**: Each file has a single, well-defined responsibility
4. **Reusability**: Common functionality extracted into utility modules
5. **Testability**: Business logic isolated from UI for easy unit testing
6. **Scalability**: Modular structure allows easy addition of new features

## Directory Structure

```
lib/
├── main.dart                          # App entry point with user authentication
├── models/                            # Data models and domain entities
│   ├── music/                         # Core music theory models
│   │   ├── note.dart                  # Note representation with MIDI support
│   │   ├── interval.dart              # Musical intervals and calculations
│   │   ├── scale.dart                 # Scale formulas, modes, and pitch classes
│   │   ├── chord.dart                 # Chord structures, inversions, voicings (>500 lines - justified)
│   │   └── tuning.dart               # Instrument tuning definitions
│   ├── fretboard/                     # Fretboard-specific models
│   │   ├── fretboard_config.dart      # Fretboard display configuration
│   │   ├── fretboard_instance.dart    # Individual fretboard state management
│   │   └── fret_position.dart         # Fret position and chord tone calculations
│   ├── user/                          # User management models
│   │   ├── user.dart                  # User profiles and authentication
│   │   ├── user_preferences.dart      # User settings and defaults
│   │   └── user_progress.dart         # Learning progress tracking
│   ├── quiz/                          # Quiz system models (NEW)
│   │   ├── quiz_question.dart         # Abstract base class for all question types
│   │   ├── multiple_choice_question.dart  # Multiple choice question implementation
│   │   ├── quiz_session.dart          # Quiz session state and management
│   │   └── quiz_result.dart           # Quiz results and performance tracking
│   └── app_state.dart                 # Central application state with ChangeNotifier
├── controllers/                       # Business logic layer
│   ├── music_controller.dart          # Music theory operations and calculations
│   ├── fretboard_controller.dart      # Fretboard logic and note highlighting
│   ├── chord_controller.dart          # Chord analysis and voice leading (NEW)
│   ├── quiz_controller.dart           # Quiz session management and flow (NEW)
│   └── unified_quiz_generator.dart    # Comprehensive quiz question generation (NEW, >500 lines - justified)
├── views/                             # User interface components
│   ├── pages/                         # Full-screen page components
│   │   ├── welcome_page.dart          # Landing page with app introduction
│   │   ├── login_page.dart            # User authentication interface
│   │   ├── home_page.dart             # Main navigation and feature access
│   │   ├── fretboard_page.dart        # Primary fretboard interaction interface
│   │   ├── settings_page.dart         # User preferences and configuration
│   │   ├── learning_topics_page.dart  # Educational content navigation (NEW)
│   │   ├── quiz_page.dart             # Interactive quiz taking interface (NEW)
│   │   └── quiz_placeholder_page.dart # Placeholder for future quiz content (NEW)
│   └── widgets/                       # Reusable UI components
│       ├── fretboard/                 # Fretboard visualization widgets
│       │   ├── fretboard_widget.dart  # Main fretboard display component
│       │   ├── fretboard_painter.dart # Custom painter for fretboard rendering
│       │   ├── scale_strip.dart       # Horizontal note display widget
│       │   └── note_display.dart      # Individual note visualization
│       ├── controls/                  # User input and control widgets
│       │   ├── theory_controls.dart   # Music theory selection controls
│       │   ├── fretboard_controls.dart # Fretboard configuration controls
│       │   ├── user_controls.dart     # User management controls
│       │   ├── root_note_selector.dart # Root note selection widget
│       │   ├── scale_selector.dart    # Scale type selection widget
│       │   ├── mode_selector.dart     # Mode selection widget
│       │   ├── octave_selector.dart   # Octave selection widget
│       │   ├── interval_controls.dart # Interval configuration controls
│       │   └── tuning_selector.dart   # Tuning selection widget
│       ├── dialogs/                   # Modal dialog components
│       │   ├── settings_dialog.dart   # Settings configuration modal
│       │   ├── user_dialog.dart       # User account management modal
│       │   └── about_dialog.dart      # Application information modal
│       └── quiz/                      # Quiz-specific widgets (NEW)
│           ├── quiz_progress_bar.dart # Quiz progress visualization
│           ├── multiple_choice_widget.dart # Multiple choice question interface
│           └── quiz_results_widget.dart    # Quiz results and statistics display
├── utils/                             # Helper functions and utilities
│   ├── music_utils.dart               # Music theory calculation helpers
│   ├── color_utils.dart               # Color generation and theme utilities
│   ├── note_utils.dart                # Note manipulation and conversion utilities
│   ├── scale_utils.dart               # Scale calculation and analysis utilities
│   ├── chord_utils.dart               # Chord analysis and construction utilities
│   └── quiz_utils.dart                # Quiz-related helper functions (NEW)
├── constants/                         # Configuration and constant values
│   ├── music_constants.dart           # Music theory data and scales
│   ├── ui_constants.dart              # UI configuration and styling constants
│   ├── app_constants.dart             # Application-wide configuration
│   └── quiz_constants.dart            # Quiz configuration and settings (NEW)
└── services/                          # External services and data management
    ├── user_service.dart              # User data persistence and management
    └── quiz_integration_service.dart  # Quiz system integration (NEW)
```

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

### Quiz State Management (NEW)
```dart
// Quiz controller integration
final quizController = Provider.of<QuizController>(context);

// Quiz session management
quizController.startQuiz(questions: questions, quizType: QuizType.topic);
quizController.submitAnswer(userAnswer);
quizController.navigateToNextQuestion();
```

### Data Flow
1. **User Input** → Control Widgets → State Updates
2. **State Changes** → Provider notifications → Widget rebuilds  
3. **Music Theory** → Controllers → Models → Visual updates
4. **User Actions** → Services → Persistence → State synchronization
5. **Quiz Flow** → Quiz Controller → Quiz Models → Quiz Widgets (NEW)

## Technology Stack
- **Framework**: Flutter 3.24.3 (web-optimized)
- **Language**: Dart 3.5.3
- **State Management**: Provider 6.1.1 with ChangeNotifier
- **Rendering**: Custom Canvas painters for performance
- **Persistence**: SharedPreferences for user data
- **Deployment**: GitLab Pages (CI/CD pipeline)
- **Development**: Flutter DevTools 2.37.3

## Core Features

### Music Theory Visualization
- **Multi-Fretboard Display**: Support for multiple simultaneous fretboard instances
- **Three Theory Modes**: Scales, intervals, and chord visualization with real-time switching
- **Interactive Controls**: Live updates for root notes, scale types, modes, octaves, and intervals
- **Visual Learning**: Color-coded notes based on scale degrees and interval relationships
- **Customizable Experience**: Multiple tunings, layouts, themes, and display options

### Quiz System (NEW)
- **Comprehensive Question Types**: Multiple choice questions with detailed explanations
- **Topic-Based Quizzes**: Focused quizzes on specific music theory topics
- **Section-Based Quizzes**: Comprehensive quizzes covering multiple related topics
- **Progress Tracking**: Quiz results and performance analytics
- **Adaptive Difficulty**: Questions scaled to user skill level
- **Time Management**: Optional time limits and time tracking
- **Detailed Feedback**: Explanations for correct and incorrect answers

### User Management
- **Registration and Login**: Complete user account system
- **Guest Access**: Full functionality without account creation
- **Personalized Settings**: Individual user preferences and configurations
- **Progress Tracking**: Learning progress and quiz performance history

## Performance Optimizations
- **Efficient Rendering**: CustomPainter with selective repainting
- **State Granularity**: Targeted widget updates using Provider selectors
- **Memory Management**: Cached calculations and optimized color generation
- **Responsive UI**: Adaptive layouts and efficient widget composition
- **Quiz Performance**: Optimized question generation and state management

## Development Workflow
- **Architecture**: Strict MVC pattern enforcement
- **Code Quality**: Comprehensive linting and formatting standards
- **Testing Strategy**: Unit tests for business logic, widget tests for UI
- **CI/CD**: Automated builds and deployment to GitLab Pages
- **Version Control**: GitLab primary, GitHub mirror for lib/ directory

## Recent Enhancements
- **Complete Quiz System**: Comprehensive quiz functionality with multiple question types
- **Educational Content**: Structured learning topics and progressive content
- **Quiz Integration**: Seamless integration between theory visualization and quiz system
- **Performance Analytics**: Detailed quiz results and progress tracking
- **User Experience**: Improved navigation and responsive design
- **Advanced Question Generation**: Sophisticated quiz question creation system

## Future Considerations
- **Audio Integration**: MIDI playback and audio generation for quiz questions
- **Advanced Question Types**: Interactive fretboard questions and audio-based questions
- **Social Features**: Shared quiz sessions and collaborative learning
- **Mobile Support**: Native mobile app development
- **Advanced Analytics**: Detailed learning analytics and adaptive content
- **Gamification**: Achievement systems and learning rewards

## Development Guidelines
- **File Organization**: Each file serves a single, clear purpose
- **Size Constraints**: Maintain files under 500 lines except when strongly justified
- **Testing**: Write tests for all business logic and critical UI components
- **Documentation**: Keep inline documentation current with code changes
- **Performance**: Profile and optimize rendering and state management regularly
- **Quiz Quality**: Ensure all quiz questions are educationally valuable and technically accurate

## Quiz System Architecture (NEW)

### Question Generation System
- **Unified Generator**: Central system for creating all quiz question types
- **Topic-Based Generation**: Questions targeted to specific music theory topics
- **Difficulty Scaling**: Questions adapted to different skill levels
- **Quality Assurance**: Comprehensive validation of question accuracy

### Quiz Session Management
- **Session Lifecycle**: Complete management of quiz sessions from start to finish
- **Progress Tracking**: Real-time progress monitoring and time management
- **Answer Validation**: Sophisticated answer checking and feedback generation
- **Results Calculation**: Detailed scoring and performance analysis

### User Experience Design
- **Responsive Interface**: Adaptive quiz interface for different screen sizes
- **Progressive Disclosure**: Information presented when needed
- **Clear Navigation**: Intuitive quiz flow and navigation options
- **Accessibility**: Support for different learning styles and accessibility needs