# Theorie - Interactive Guitar Fretboard Theory App

## Project Overview
Theorie is a Flutter web application for learning and exploring music theory on guitar fretboards. It provides interactive visualization of scales, chords, and intervals across multiple configurable fretboards, helping musicians understand the relationships between notes, patterns, and musical concepts.

## Core Features
- **Multi-Fretboard Display**: Support for multiple simultaneous fretboard instances
- **Music Theory Modes**: Scales, intervals, and chord visualization
- **Interactive Controls**: Real-time updates for root notes, scale types, modes, and octaves
- **Customizable Tunings**: Support for various guitar tunings
- **Visual Learning**: Color-coded notes based on scale degrees and intervals
- **Responsive Design**: Optimized for web browsers

## Technology Stack
- **Flutter**: 3.24.3 (stable channel)
- **Dart**: 3.5.3
- **State Management**: Provider 6.1.1
- **Architecture**: MVC (Model-View-Controller)
- **Deployment**: GitLab Pages (web build)
- **Development Tools**: DevTools 2.37.3

## Project Architecture

### MVC Pattern Implementation
```
Models (Data & Domain Logic)
    ↓
Controllers (Business Logic)
    ↓
Views (UI Components)
    ↑
Provider (State Management)
```

### Key Architectural Principles
1. **Separation of Concerns**: Each file has a single responsibility
2. **File Size Limit**: ~500 lines max for maintainability
3. **Reusability**: Common functionality extracted to utilities
4. **Testability**: Business logic isolated from UI
5. **Scalability**: Modular structure for easy feature additions

## Directory Structure
```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models and domain entities
│   ├── music/                     # Music theory models
│   │   ├── note.dart             # Note representation (pitch, octave, MIDI)
│   │   ├── interval.dart         # Musical intervals
│   │   ├── scale.dart            # Scale formulas and modes
│   │   ├── chord.dart            # Chord structures and voicings
│   │   └── tuning.dart           # Instrument tunings
│   ├── fretboard/                # Fretboard-specific models
│   │   ├── fretboard_config.dart # Fretboard configuration
│   │   ├── fretboard_instance.dart # Individual fretboard state
│   │   └── fret_position.dart    # Fret position calculations
│   └── app_state.dart            # Global application state
├── controllers/                   # Business logic layer
│   ├── music_controller.dart     # Music theory operations
│   ├── fretboard_controller.dart # Fretboard calculations
│   └── chord_controller.dart     # Chord building logic
├── views/                        # UI components
│   ├── pages/                    # Full-screen pages
│   ├── widgets/                  # Reusable components
│   └── dialogs/                  # Dialog windows
├── utils/                        # Helper functions
│   ├── note_utils.dart          # Note calculations
│   ├── scale_utils.dart         # Scale generation
│   ├── chord_utils.dart         # Chord utilities
│   ├── color_utils.dart         # Color generation
│   └── music_utils.dart         # General music utilities
└── constants/                    # Application constants
    ├── app_constants.dart       # App configuration
    ├── music_constants.dart     # Music theory data
    └── ui_constants.dart        # UI measurements
```

## Key Components

### Models
- **Note**: Represents musical notes with pitch class, octave, and MIDI conversion
- **Scale**: Contains scale formulas, modes, and pitch class sets
- **Chord**: Defines chord formulas, inversions, and voicings
- **FretboardInstance**: Manages individual fretboard state and configuration
- **AppState**: Central state management using ChangeNotifier

### Controllers
- **MusicController**: Handles music theory calculations and transformations
- **FretboardController**: Manages fretboard logic, note highlighting, and interactions
- **ChordController**: Builds chord voicings and analyzes fingering patterns

### Views
- **FretboardWidget**: Main fretboard display component
- **FretboardPainter**: Custom canvas painter for fretboard rendering
- **Control Widgets**: Dropdowns and selectors for user input
- **ScaleStrip**: Horizontal note display for scales/intervals

## State Management

### Provider Pattern
```dart
// Global state access
final appState = Provider.of<AppState>(context);

// State updates
appState.updateRootNote(newNote);
appState.notifyListeners();
```

### State Flow
1. User interacts with control widgets
2. Controllers process the input
3. Models/State are updated
4. Provider notifies listeners
5. UI widgets rebuild with new data

## Development Guidelines

### Code Style
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Methods/Variables**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE` or `camelCase` for const
- **Private members**: `_prefixWithUnderscore`

### Widget Best Practices
- Extract widgets when > 100 lines
- Use `const` constructors where possible
- Implement `Key` parameters for list items
- Separate business logic from UI code

### Music Theory Implementation
- All calculations should go through utility functions
- Use MIDI numbers for internal note representation
- Support enharmonic equivalents (C# = Db)
- Maintain chromatic scale as source of truth

## Common Commands

```bash
# Development
flutter run -d chrome              # Run in Chrome browser
flutter run --web-port=8080       # Run on specific port
flutter run --web-renderer html   # Use HTML renderer
flutter run --web-renderer canvaskit # Use CanvasKit renderer

# Testing
flutter test                      # Run all tests
flutter test test/unit/          # Run unit tests only
flutter test --coverage          # Generate coverage report

# Building
flutter build web                # Build for production
flutter build web --release      # Build optimized release
flutter build web --web-renderer html # Build with HTML renderer

# Analysis
flutter analyze                  # Run static analysis
flutter format .                # Format all Dart files
dart fix --apply               # Apply automated fixes

# Maintenance
flutter clean                   # Clean build artifacts
flutter pub get                # Install dependencies
flutter pub upgrade            # Upgrade dependencies
flutter doctor                 # Check Flutter setup
```

## Music Theory Implementation Details

### Note System
- Uses chromatic scale (12 semitones)
- MIDI note numbers for calculations (60 = Middle C)
- Supports sharps and flats with enharmonic awareness
- Octave numbering follows scientific pitch notation

### Scale System
- Scales defined as interval patterns (e.g., Major: [2,2,1,2,2,2,1])
- Supports all standard modes (Ionian, Dorian, etc.)
- Pitch class sets for scale membership testing
- Mode rotation handled automatically

### Chord System
- Chords defined as interval formulas from root
- Supports inversions and voicings
- Chord-scale relationships maintained
- Voice leading calculations available

### Fretboard Calculations
- Standard tuning: E-A-D-G-B-E (low to high)
- Fret positions calculated from nut (0) to body
- Support for custom tunings
- Capo support through transposition

## Performance Considerations

### Rendering Optimization
- Use `CustomPainter` for fretboard rendering
- Implement `shouldRepaint` efficiently
- Cache calculated positions
- Minimize widget rebuilds

### State Management
- Use `selector` for granular updates
- Avoid unnecessary `notifyListeners()` calls
- Batch state updates when possible

## Testing Approach

### Unit Tests
- Test music theory calculations
- Verify note/scale/chord operations
- Test utility functions independently

### Widget Tests
- Test control widget interactions
- Verify state updates propagate correctly
- Test responsive behavior

### Integration Tests
- Test full user workflows
- Verify multi-fretboard synchronization
- Test settings persistence

## Known Patterns & Solutions

### Common Tasks
1. **Adding a new scale type**: Update `music_constants.dart` and `scale_utils.dart`
2. **Adding a new tuning**: Add to `music_constants.dart` tuning presets
3. **Customizing colors**: Modify `color_utils.dart` generation algorithms
4. **Adding new view mode**: Update `ViewMode` enum and related controllers

### Debugging Tips
- Use Flutter Inspector for widget tree analysis
- Enable `debugPaintSizeEnabled` for layout debugging
- Check browser console for web-specific errors
- Use `print()` statements in controllers for logic flow

## Important Considerations

### Web-Specific
- No access to device file system
- Browser compatibility considerations
- Performance varies by renderer choice
- Handle keyboard/mouse input appropriately

### Music Theory Accuracy
- Verify all interval calculations
- Test edge cases (B# = C, Cb = B)
- Ensure mode relationships are correct
- Validate chord formula implementations

## CI/CD Notes
- GitLab CI/CD builds and deploys to GitLab Pages
- Only `lib/` and `test/` directories synced to GitHub
- Assets and build artifacts remain in GitLab
- Production URL: [GitLab Pages deployment]

## Do Not
- Don't hardcode note names - use constants
- Don't bypass utility functions for calculations
- Don't mix UI logic with music theory logic
- Don't assume standard tuning - always check
- Don't modify this file without updating GitLab source

## Future Considerations
- Audio playback integration
- MIDI input/output support
- Additional instrument support
- Advanced chord voicing algorithms
- Music theory exercises/quizzes