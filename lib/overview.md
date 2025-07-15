# Theorie - Project Structure Overview

## Project Description
Theorie is a comprehensive Flutter web application for interactive guitar fretboard theory learning. It provides real-time visualization of scales, chords, and intervals across configurable fretboards, helping musicians understand music theory concepts through visual and interactive learning.

## Architecture
The application follows strict MVC (Model-View-Controller) architecture with clear separation of concerns:

- **Models**: Data structures and domain entities for music theory and fretboard configuration
- **Controllers**: Business logic for music calculations, fretboard rendering, and state management  
- **Views**: UI components including pages, widgets, and dialogs
- **Utils**: Helper functions for music theory calculations and color generation
- **Constants**: Configuration values and music theory data
- **Services**: User management and data persistence

## Key Architectural Principles
1. **File Size Limit**: All files maintained around or under 500 lines unless strongly justified (e.g., chord.dart with hundreds of chord variations)
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
│   └── app_state.dart                 # Central application state with ChangeNotifier
├── controllers/                       # Business logic layer
│   ├── music_controller.dart          # Music theory operations and calculations
│   ├── fretboard_controller.dart      # Fretboard logic and note highlighting
│   └── chord_controller.dart          # Chord building and voicing analysis
├── services/                          # External services and persistence
│   └── user_service.dart             # User data management and persistence
├── views/                             # UI components and presentation layer
│   ├── pages/                         # Full-screen application pages
│   │   ├── login_page.dart           # User authentication interface
│   │   ├── welcome_page.dart         # Landing page and navigation
│   │   ├── home_page.dart            # Single fretboard view with controls
│   │   ├── fretboard_page.dart       # Multi-fretboard workspace
│   │   └── settings_page.dart        # Comprehensive user settings
│   ├── widgets/                       # Reusable UI components
│   │   ├── fretboard/                # Fretboard-specific widgets
│   │   │   ├── fretboard_widget.dart # Main fretboard display component
│   │   │   ├── fretboard_painter.dart # Custom Canvas painter for rendering
│   │   │   ├── scale_strip.dart      # Horizontal note strip display
│   │   │   └── fretboard_container.dart # Stateful fretboard wrapper
│   │   ├── controls/                 # Interactive control widgets
│   │   │   ├── root_selector.dart    # Root note selection dropdown
│   │   │   ├── scale_selector.dart   # Scale type selection
│   │   │   ├── chord_selector.dart   # Hierarchical chord selection
│   │   │   ├── mode_selector.dart    # Scale mode selection
│   │   │   ├── octave_selector.dart  # Octave range selection (checkboxes)
│   │   │   ├── interval_selector.dart # Individual interval selection
│   │   │   ├── tuning_selector.dart  # Instrument tuning presets
│   │   │   ├── view_mode_selector.dart # Mode switching (scales/intervals/chords)
│   │   │   └── fretboard_controls.dart # Unified control panel
│   │   └── common/                   # Shared UI components
│   │       └── app_bar.dart         # Reusable application bar
│   └── dialogs/                      # Modal dialog components
│       ├── settings_dialog.dart     # Main settings interface
│       └── settings_sections.dart   # Organized settings sections
├── utils/                            # Helper functions and calculations
│   ├── note_utils.dart              # Note parsing, MIDI conversion, transposition
│   ├── scale_utils.dart             # Scale generation and mode calculations
│   ├── chord_utils.dart             # Chord building and inversion handling
│   ├── color_utils.dart             # Color generation for theory visualization
│   └── music_utils.dart             # General music theory utilities
└── constants/                        # Application configuration
    ├── app_constants.dart            # General application settings and limits
    ├── music_constants.dart          # Music theory data (notes, intervals, tunings)
    └── ui_constants.dart             # UI measurements, colors, and styling
```

## Core Features Implemented

### Music Theory Engine
- **Comprehensive Note System**: MIDI-based note representation with enharmonic support
- **Scale System**: 20+ scale types with all modal variations and pitch class sets
- **Chord System**: Extensive chord database with inversions, voicings, and voice leading
- **Interval System**: All musical intervals with compound interval support

### Fretboard Visualization  
- **Multi-Fretboard Support**: Display multiple configurable fretboard instances
- **Three View Modes**: 
  - **Intervals**: Individual interval visualization from root
  - **Scales**: Complete scale patterns with modal variations
  - **Chords**: Chord voicings with inversion support
- **Interactive Controls**: Real-time updates for all musical parameters
- **Custom Rendering**: High-performance Canvas-based fretboard painting
- **Responsive Design**: Adaptive layouts for different screen sizes

### User Experience
- **User Management**: Registration, login, and guest access
- **Personalization**: User preferences for defaults and visual settings
- **Progress Tracking**: Learning progress and quiz completion tracking
- **Theme Support**: Light and dark mode themes
- **Persistent State**: Settings and preferences saved across sessions

### Visual Learning System
- **Color-Coded Theory**: Distinct colors for scale degrees and intervals
- **Scale Strip Display**: Horizontal note reference strips
- **Multiple Tunings**: Support for various guitar tunings
- **Layout Options**: Right/left-handed and bass positioning options
- **Note Names**: Optional note name display overlay

## State Management Architecture

### Provider Pattern Implementation
```dart
AppState (ChangeNotifier)
    ├── User Management (currentUser, preferences)
    ├── Global Settings (theme, defaults)
    ├── Session State (current root, scale, mode)
    └── Fretboard Instances (individual configurations)
```

### Data Flow
1. **User Input** → Control Widgets → State Updates
2. **State Changes** → Provider notifications → Widget rebuilds  
3. **Music Theory** → Controllers → Models → Visual updates
4. **User Actions** → Services → Persistence → State synchronization

## Technology Stack
- **Framework**: Flutter 3.24.3 (web-optimized)
- **Language**: Dart 3.5.3
- **State Management**: Provider 6.1.1 with ChangeNotifier
- **Rendering**: Custom Canvas painters for performance
- **Persistence**: SharedPreferences for user data
- **Deployment**: GitLab Pages (CI/CD pipeline)
- **Development**: Flutter DevTools 2.37.3

## Performance Optimizations
- **Efficient Rendering**: CustomPainter with selective repainting
- **State Granularity**: Targeted widget updates using Provider selectors
- **Memory Management**: Cached calculations and optimized color generation
- **Responsive UI**: Adaptive layouts and efficient widget composition

## Development Workflow
- **Architecture**: Strict MVC pattern enforcement
- **Code Quality**: Comprehensive linting and formatting standards
- **Testing Strategy**: Unit tests for business logic, widget tests for UI
- **CI/CD**: Automated builds and deployment to GitLab Pages
- **Version Control**: GitLab primary, GitHub mirror for lib/ directory

## Recent Enhancements
- **User System**: Complete user registration and login functionality
- **Chord Voicing**: Advanced chord building with proper voice leading
- **Scale Strip**: Enhanced horizontal note display with user-selected octaves
- **Multi-Octave Support**: Flexible octave selection for all view modes
- **Settings Persistence**: Comprehensive user preference management
- **Guest Access**: Seamless experience for users without accounts

## Future Considerations
- **Audio Integration**: MIDI playback and audio generation
- **Educational Content**: Interactive theory lessons and exercises
- **Advanced Features**: Chord progressions, voice leading analysis
- **Mobile Support**: Native mobile app development
- **Collaboration**: Shared fretboard sessions and social features

## Development Guidelines
- **File Organization**: Each file serves a single, clear purpose
- **Size Constraints**: Maintain files under 500 lines except when strongly justified
- **Testing**: Write tests for all business logic and critical UI components
- **Documentation**: Keep inline documentation current with code changes
- **Performance**: Profile and optimize rendering and state management regularly