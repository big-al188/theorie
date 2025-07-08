# Guitar Theory App - Project Structure Overview

## Architecture
The app follows the MVC (Model-View-Controller) pattern with clear separation of concerns:

- **Models**: Data structures and domain entities
- **Controllers**: Business logic and state management
- **Views**: UI components (pages, widgets, dialogs)
- **Utils**: Helper functions and calculations
- **Constants**: Configuration and constant values

## Directory Structure

```
lib/
├── main.dart                          # App entry point
├── models/                            # Data models and domain entities
│   ├── music/                         # Music theory models
│   │   ├── note.dart                  # Note representation and operations
│   │   ├── interval.dart              # Musical intervals
│   │   ├── scale.dart                 # Scale definitions and operations
│   │   ├── chord.dart                 # Chord structures and voicings
│   │   └── tuning.dart               # Instrument tuning models
│   ├── fretboard/                     # Fretboard-specific models
│   │   ├── fretboard_config.dart      # Fretboard configuration
│   │   ├── fretboard_instance.dart    # Individual fretboard instance
│   │   └── fret_position.dart         # Fret position and chord tone models
│   └── app_state.dart                 # Global application state
├── controllers/                       # Business logic controllers
│   ├── music_controller.dart          # Music theory operations
│   ├── fretboard_controller.dart      # Fretboard logic and calculations
│   └── chord_controller.dart          # Chord building and analysis
├── views/                             # UI components
│   ├── pages/                         # Full-screen pages
│   │   ├── home_page.dart            # Main landing page
│   │   ├── fretboard_page.dart       # Multi-fretboard view
│   │   └── settings_page.dart        # Settings page
│   ├── widgets/                       # Reusable UI components
│   │   ├── fretboard/                # Fretboard display widgets
│   │   │   ├── fretboard_widget.dart # Main fretboard widget
│   │   │   ├── fretboard_painter.dart # Canvas painter for fretboard
│   │   │   ├── scale_strip.dart      # Scale/interval strip widget
│   │   │   └── fretboard_container.dart # Container with state
│   │   ├── controls/                  # Control widgets
│   │   │   ├── root_selector.dart    # Root note selector
│   │   │   ├── scale_selector.dart   # Scale type selector
│   │   │   ├── chord_selector.dart   # Chord type selector
│   │   │   ├── mode_selector.dart    # Mode selector
│   │   │   ├── octave_selector.dart  # Octave range selector
│   │   │   ├── interval_selector.dart # Interval selector
│   │   │   ├── tuning_selector.dart  # Tuning preset selector
│   │   │   ├─── view_mode_selector.dart # View mode selector
│   │   │   └── fretboard_controls.dart # Fretboard controls
│   │   └── common/                    # Common UI components
│   │       └── app_bar.dart          # Custom app bar
│   └── dialogs/                       # Dialog components
│       ├── settings_dialog.dart       # Settings dialog
│       └── settings_sections.dart     # Settings dialog sections
├── utils/                             # Utility functions
│   ├── note_utils.dart               # Note calculations and conversions
│   ├── scale_utils.dart              # Scale theory utilities
│   ├── chord_utils.dart              # Chord theory utilities
│   ├── color_utils.dart              # Color generation for visualization
│   └── music_utils.dart              # General music utilities
└── constants/                         # Application constants
    ├── app_constants.dart            # General app constants
    ├── music_constants.dart          # Music theory constants
    └── ui_constants.dart             # UI-related constants
```

## File Descriptions

### Models (`/models`)

#### Music Models (`/models/music`)
- **note.dart**: Note class with pitch class, octave, MIDI conversion
- **interval.dart**: Interval representation and calculations
- **scale.dart**: Scale formulas, modes, and pitch class sets
- **chord.dart**: Chord formulas, inversions, and voicings
- **tuning.dart**: Instrument tuning definitions and utilities

#### Fretboard Models (`/models/fretboard`)
- **fretboard_config.dart**: Configuration for fretboard display (strings, frets, layout)
- **fretboard_instance.dart**: Individual fretboard instance with its own settings
- **fret_position.dart**: Models for fret positions and chord tones on fretboard

#### State Management
- **app_state.dart**: Central application state using ChangeNotifier

### Controllers (`/controllers`)
- **music_controller.dart**: Handles music theory calculations and operations
- **fretboard_controller.dart**: Manages fretboard logic, highlighting, and interactions
- **chord_controller.dart**: Builds chord voicings and analyzes fingerings

### Views (`/views`)

#### Pages (`/views/pages`)
- **home_page.dart**: Landing page with global settings
- **fretboard_page.dart**: Multi-fretboard view with individual controls
- **settings_page.dart**: Comprehensive settings management

#### Widgets (`/views/widgets`)

##### Fretboard Widgets (`/views/widgets/fretboard`)
- **fretboard_widget.dart**: Main fretboard display widget
- **fretboard_painter.dart**: Custom painter for rendering fretboard
- **scale_strip.dart**: Horizontal strip showing scale/interval notes
- **fretboard_container.dart**: Stateful container connecting to app state

##### Control Widgets (`/views/widgets/controls`)
- **root_selector.dart**: Dropdown for selecting root note
- **scale_selector.dart**: Dropdown for scale selection
- **chord_selector.dart**: Hierarchical chord type selector
- **mode_selector.dart**: Mode selection within scales
- **octave_selector.dart**: Octave range selection (checkboxes/radio)
- **interval_selector.dart**: Interval selection for interval mode
- **tuning_selector.dart**: Preset tuning selector
- **view_mode_selector.dart**: Switch between scales/intervals/chords

##### Common Widgets (`/views/widgets/common`)
- **app_bar.dart**: Reusable app bar with common actions

#### Dialogs (`/views/dialogs`)
- **settings_dialog.dart**: Main settings dialog container
- **settings_sections.dart**: Individual sections for settings

### Utilities (`/utils`)
- **note_utils.dart**: Note name parsing, MIDI conversion, transposition
- **scale_utils.dart**: Scale generation, mode calculations
- **chord_utils.dart**: Chord building, inversion handling
- **color_utils.dart**: Color generation for music visualization
- **music_utils.dart**: General music theory utilities

### Constants (`/constants`)
- **app_constants.dart**: App-wide settings (limits, defaults)
- **music_constants.dart**: Music theory data (note names, intervals, tunings)
- **ui_constants.dart**: UI measurements, colors, styling

## Key Design Principles

1. **Separation of Concerns**: Each file has a single, clear responsibility
2. **File Size**: All files kept under ~500 lines for maintainability
3. **Reusability**: Common functionality extracted into utilities
4. **Testability**: Business logic separated from UI for easy testing
5. **Scalability**: Modular structure allows easy addition of features

## Data Flow

1. **User Input** → Control Widgets → Controllers
2. **Controllers** → Update Models/State
3. **State Changes** → Notify Widgets
4. **Widgets** → Render UI with Painters

## State Management

- Uses Provider pattern with ChangeNotifier
- Central AppState for global settings
- Local state in individual widgets where appropriate
- Controllers handle complex state updates