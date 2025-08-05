# Theorie - Complete Project Structure Overview

## Project Description
Theorie is a comprehensive Flutter web application for interactive guitar fretboard theory learning with full-stack architecture including Firebase Functions backend, Stripe payment integration, and advanced music theory visualization. The application provides real-time visualization of scales, chords, and intervals across configurable fretboards, complete quiz systems, subscription management, audio integration, and cloud-based progress tracking.

## Full System Architecture

### Frontend (Flutter Web - `/lib/`)
Comprehensive Flutter web application with strict MVC architecture, advanced state management, and real-time music theory visualization.

### Backend (Firebase Functions - `/functions/src/`)
**`index.ts`** - Complete Firebase Functions v2 implementation with:
- **Stripe Integration**: Subscription management, payment processing, webhook handling
- **Authentication**: Firebase Auth integration with JWT token verification
- **CORS Handling**: Comprehensive cross-origin request management
- **Error Handling**: Detailed logging and error categorization
- **Payment Flows**: Both web checkout and mobile payment method flows
- **Webhook Processing**: Complete Stripe event handling and data synchronization

### Database & Cloud Services
- **Firebase Firestore**: User data, progress tracking, subscription status
- **Firebase Authentication**: Secure user account management
- **Stripe**: Payment processing and subscription management
- **Firebase Hosting**: Web application deployment

## Detailed Directory Structure

### `/lib/` - Main Application Code

#### **Root Files**
- **`main.dart`** - Application entry point, Provider setup, routing configuration
- **`firebase_options.dart`** - Firebase configuration and initialization

#### **Documentation Files** *(Reference guides for system modifications)*
- **`persistence_integration.md`** - Local storage, Firebase sync, offline support strategies
- **`question_type_integration.md`** - Adding new quiz question types and interactions
- **`quiz_creation.md`** - Quiz content creation workflows and standards
- **`scale_strip_question.md`** - Interactive visual question system documentation
- **`sections_and_topics_creation.md`** - Educational content creation guidelines
- **`stripe_integration.md`** - Payment processing integration with Stripe

### `/lib/constants/` - Configuration & Reference Data
- **`app_constants.dart`** - Application-wide configuration, version info, feature flags
- **`music_constants.dart`** - Scale intervals, chord formulas, tuning presets, MIDI mappings
- **`quiz_constants.dart`** - Quiz timing, scoring, difficulty levels, question limits
- **`ui_constants.dart`** - Layout dimensions, colors, themes, responsive breakpoints

### `/lib/controllers/` - Business Logic & State Management
- **`audio_controller.dart`** - Audio playback, MIDI generation, sound synthesis
- **`chord_controller.dart`** - Chord construction, voicing analysis, inversion handling
- **`fretboard_controller.dart`** - Fretboard logic, note highlighting, visual mapping algorithms
- **`music_controller.dart`** - Core music theory calculations, mode operations, note transformations
- **`quiz_controller.dart`** - Quiz session lifecycle, answer validation, progress tracking
- **`unified_quiz_generator.dart`** - Comprehensive question generation system (>500 lines - justified)

### `/lib/models/` - Data Structures & Domain Entities

#### **Fretboard Models** (`/fretboard/`)
- **`fret_position.dart`** - Individual fret position data structure
- **`fretboard_config.dart`** - Display configuration and user preferences
- **`fretboard_instance.dart`** - Active fretboard state and properties
- **`highlight_info.dart`** - Note highlighting and color mapping data

#### **Learning System Models** (`/learning/`)
- **`learning_content.dart`** - Core learning content structure and repository
- **`learning_tier.dart`** - Base tier structure and progression system

**Learning Tiers** (`/learning/tiers/`) - *8-tier progressive education system*:
- **`introduction_tier.dart`** - Start your musical journey
- **`fundamentals_tier.dart`** - Build essential knowledge  
- **`essentials_tier.dart`** - Core concepts for musicians
- **`intermediate_tier.dart`** - Develop deeper understanding
- **`advanced_tier.dart`** - Master complex concepts
- **`professional_tier.dart`** - Industry-level expertise
- **`master_tier.dart`** - Comprehensive mastery
- **`virtuoso_tier.dart`** - Push the boundaries

#### **Music Theory Models** (`/music/`)
- **`chord.dart`** - Chord construction, voicings, inversions, extensions
- **`interval.dart`** - Interval relationships, quality, compound intervals
- **`note.dart`** - Note representation, MIDI numbers, enharmonic equivalents
- **`scale.dart`** - Scale construction, modes, theoretical analysis
- **`tuning.dart`** - Instrument tunings, alternative configurations

#### **Quiz System Models** (`/quiz/`)
- **`multiple_choice_question.dart`** - Multiple choice question structure and validation
- **`question_result.dart`** - Individual question results and analytics
- **`quiz_question.dart`** - Abstract base class for all question types
- **`quiz_result.dart`** - Complete quiz session results and scoring
- **`quiz_session.dart`** - Quiz session lifecycle and state management
- **`scale_strip_question.dart`** - Interactive visual question system

**Quiz Content** (`/quiz/sections/`) - *Organized by learning tiers*:
- **`fundamentals/`** - All quiz questions for fundamental music theory topics
- **`introduction/`** - All quiz questions for introductory concepts

#### **Subscription & Payment Models** (`/subscription/`)
- **`payment_models.dart`** - Payment data structures, transaction records
- **`subscription_models.dart`** - Subscription tiers, billing cycles, access levels

#### **User System Models** (`/user/`)
- **`user.dart`** - User account information and authentication data
- **`user_preferences.dart`** - Personal settings, display preferences, customizations
- **`user_progress.dart`** - Learning progress, quiz results, achievement tracking

#### **Global State**
- **`app_state.dart`** - Central application state with ChangeNotifier pattern

### `/lib/services/` - External Integrations & Data Management

#### **Audio Services** (`/audio/`)
- **`audio_service.dart`** - Main audio service implementation
- **`audio_service_interface.dart`** - Abstract audio service interface
- **`file_audio_service.dart`** - File-based audio playback
- **`web_audio_service.dart`** - Web Audio API integration

#### **Firebase Services**
- **`firebase_auth_service.dart`** - Authentication state management
- **`firebase_config.dart`** - Firebase configuration and initialization
- **`firebase_database_service.dart`** - Firestore operations and data management
- **`firebase_user_service.dart`** - User data synchronization and cloud storage

#### **Core Services**
- **`progress_tracking_service.dart`** - Learning analytics and progress persistence
- **`quiz_integration_service.dart`** - Quiz system integration and debugging utilities
- **`subscription_service.dart`** - Subscription management and premium feature access
- **`user_service.dart`** - Local user data management and offline support

#### **Payment Integration**
- **`stripe_config.dart`** - Stripe configuration and API setup

### `/lib/utils/` - Helper Functions & Algorithms
- **`chord_utils.dart`** - Chord analysis, progression validation, voicing algorithms
- **`color_utils.dart`** - Color generation for theory visualization, accessibility
- **`music_utils.dart`** - Core music theory calculations and transformations
- **`note_utils.dart`** - Note manipulation, conversion utilities, MIDI operations
- **`scale_strip_question_generator.dart`** - Question generation for scale strip interactions
- **`scale_strip_utils.dart`** - Scale strip calculations and layout algorithms
- **`scale_utils.dart`** - Scale analysis, mode calculations, interval patterns
- **`web_utils.dart`** - Web-specific utilities and browser compatibility

### `/lib/views/` - User Interface Components

#### **Dialog Components** (`/dialogs/`)
- **`audio_settings_section.dart`** - Audio configuration interface
- **`settings_dialog.dart`** - Main settings modal
- **`settings_sections.dart`** - Organized settings categories

#### **Page Components** (`/pages/`) - *Full-screen interfaces*
- **`fretboard_page.dart`** - Main fretboard visualization interface
- **`home_page.dart`** - Application dashboard and navigation
- **`instrument_selection_page.dart`** - Instrument and tuning selection
- **`learning_sections_page.dart`** - Educational content navigation
- **`learning_topics_page.dart`** - Topic-specific learning interface
- **`login_page.dart`** - Authentication and account management
- **`quiz_landing_page.dart`** - Quiz selection and setup
- **`quiz_page.dart`** - Active quiz interface and interaction
- **`quiz_placeholder_page.dart`** - Placeholder for unimplemented quizzes
- **`settings_page.dart`** - Application configuration
- **`subscription_management_page.dart`** - Premium subscription interface
- **`topic_detail_page.dart`** - Detailed topic content and progression
- **`welcome_page.dart`** - Onboarding and first-time user experience

#### **Widget Components** (`/widgets/`)

**Common Widgets** (`/common/`):
- **`app_bar.dart`** - Application header and navigation

**Control Widgets** (`/controls/`) - *User input components*:
- **`chord_selector.dart`** - Chord type and voicing selection
- **`fretboard_controls.dart`** - Fretboard display configuration
- **`interval_selector.dart`** - Interval type and quality selection
- **`mode_selector.dart`** - Musical mode selection interface
- **`octave_selector.dart`** - Octave range configuration
- **`root_selector.dart`** - Root note selection
- **`scale_selector.dart`** - Scale type and pattern selection
- **`tuning_selector.dart`** - Instrument tuning configuration
- **`view_mode_selector.dart`** - Display mode switching (scales/chords/intervals)

**Fretboard Widgets** (`/fretboard/`) - *Core visualization components*:
- **`audio_controls.dart`** - Audio playback controls and settings
- **`fretboard_container.dart`** - Container and layout management
- **`fretboard_painter.dart`** - Custom Canvas-based fretboard rendering
- **`fretboard_widget.dart`** - Main fretboard display component
- **`scale_strip.dart`** - Horizontal scale visualization component

**Quiz Widgets** (`/quiz/`) - *Interactive quiz interfaces*:
- **`multiple_choice_widget.dart`** - Multiple choice question interface
- **`question_widget.dart`** - Centralized question factory and router
- **`quiz_progress_bar.dart`** - Quiz progress visualization
- **`quiz_results_widget.dart`** - Quiz completion and scoring display
- **`scale_strip_question_widget.dart`** - Interactive scale strip question interface

**Subscription Widgets** (`/subscription/`) - *Payment and premium features*:
- **`payment_form_widget.dart`** - Payment method collection and processing
- **`subscription_star_widget.dart`** - Premium feature indicators

## Backend Integration (Firebase Functions)

### **`functions/src/index.ts`** - Complete Firebase Functions Implementation

#### **Core Infrastructure**
- **Firebase Functions v2**: Latest generation with enhanced performance
- **Stripe Integration**: Complete payment processing and subscription management
- **CORS Configuration**: Comprehensive cross-origin request handling
- **Authentication Middleware**: JWT token verification and user validation
- **Error Handling**: Detailed logging and error categorization

#### **HTTP Endpoints**

**Authentication & Testing:**
- **`testAuth`** - Authentication testing and connectivity verification
- **`getSubscriptionStatus`** - Retrieve user subscription status and details

**Subscription Management:**
- **`createSubscriptionSetup`** - Handle both web checkout and mobile payment flows
- **`cancelSubscription`** - Subscription cancellation with period-end handling
- **`resumeSubscription`** - Reactivate canceled subscriptions

**Payment Processing:**
- **`createPaymentIntent`** - One-time payment processing
- **`stripeWebhook`** - Complete webhook event handling and data synchronization

#### **Webhook Event Handling**
Comprehensive Stripe event processing:
- **Subscription Events**: Created, updated, deleted, trial ending
- **Payment Events**: Succeeded, failed, action required
- **Customer Events**: Created, updated, payment method changes
- **Invoice Events**: Payment processing and billing updates

#### **Data Synchronization**
- **Firestore Integration**: Real-time user data synchronization
- **Payment Records**: Complete transaction history and analytics
- **Subscription Status**: Automatic access level updates
- **Error Recovery**: Robust handling of sync failures and conflicts

## Integration Documentation Reference

When modifying specific systems, always reference these documentation files:

### **`persistence_integration.md`**
**Use when**: Adding user data fields, modifying storage strategies, implementing offline features, troubleshooting data synchronization
**Covers**: SharedPreferences, Firebase Firestore, data sync, offline support, conflict resolution

### **`question_type_integration.md`**
**Use when**: Adding new question types, modifying quiz interactions, implementing custom question widgets, extending quiz system capabilities
**Covers**: Question type architecture, polymorphic design, UI widget development, answer validation, quiz integration

### **`quiz_creation.md`**
**Use when**: Creating new quiz content, organizing educational topics, implementing quiz workflows, maintaining quiz quality standards
**Covers**: Quiz content creation, question authoring guidelines, topic organization, quality assurance, session management

### **`scale_strip_question.md`**
**Use when**: Working with Scale Strip questions, implementing visual music theory interfaces, modifying interactive components, debugging scale strip functionality
**Covers**: Scale Strip architecture, interactive visual interface, answer validation, educational content integration

### **`sections_and_topics_creation.md`**
**Use when**: Adding new learning sections, creating educational topics, organizing curriculum content, maintaining educational content quality
**Covers**: Learning content structure, progressive difficulty, content authoring standards, quiz integration, quality assurance

### **`stripe_integration.md`**
**Use when**: Implementing payment features, managing subscriptions, handling billing issues, adding premium content access controls
**Covers**: Stripe payment gateway, subscription management, security compliance, premium features, payment analytics

## Data Flow Architecture

### **User Authentication Flow**
```
User Login → Firebase Auth → Backend Verification → Token Validation → User Service → State Update → UI Refresh
```

### **Subscription Flow**
```
Payment Request → Frontend Validation → Firebase Function → Stripe Processing → Webhook Events → Data Sync → Access Update
```

### **Quiz System Flow**
```
Topic Selection → Question Generation → UI Rendering → User Interaction → Answer Validation → Progress Tracking → Results Display
```

### **Music Theory Visualization Flow**
```
User Input → Controller Logic → Model Updates → State Changes → CustomPainter → Canvas Rendering → Visual Display
```

### **Data Persistence Flow**
```
User Actions → Local Storage (SharedPreferences) → Cloud Sync (Firebase) → Conflict Resolution → State Updates → UI Refresh
```

## Performance Optimizations

### **Frontend Performance**
- **CustomPainter**: High-performance Canvas-based rendering with selective repainting
- **Provider Selectors**: Granular widget updates to minimize rebuilds
- **Color Caching**: Pre-calculated color maps for theory visualization
- **Memory Management**: Proper disposal of controllers and cached data
- **Web Optimization**: Lazy loading, code splitting, efficient asset management

### **Backend Performance**
- **Function Optimization**: Memory allocation and timeout configuration
- **Database Efficiency**: Batched operations and optimized queries
- **Caching Strategies**: Intelligent data caching to reduce API calls
- **Error Handling**: Comprehensive error recovery and retry mechanisms

### **Payment Processing Performance**
- **Stripe Optimization**: Efficient API usage and webhook processing
- **Data Synchronization**: Smart sync strategies to minimize conflicts
- **Security**: PCI compliance and secure payment method handling

## Development Guidelines

### **Code Organization Standards**
- **Naming Conventions**: `snake_case.dart`, `PascalCase` classes, `camelCase` methods
- **Import Organization**: Relative imports for project files, package imports first
- **File Structure**: Logical grouping with clear hierarchies and dependencies
- **Documentation**: Comprehensive inline documentation and integration guides

### **Testing Strategy**
- **Unit Testing**: All business logic and controller methods
- **Widget Testing**: Critical UI interactions and state management
- **Integration Testing**: End-to-end user workflows and payment processing
- **Firebase Testing**: Authentication, database operations, and cloud functions

### **Common Development Tasks**

#### **Music Theory Features**
1. **Adding Scale Types**: Update `music_constants.dart` → Test with `scale_utils.dart` → Verify fretboard rendering
2. **New Chord Types**: Extend `chord.dart` formulas → Update `chord_controller.dart` → Test voicing algorithms
3. **Custom Tunings**: Add to `music_constants.dart` → Update `tuning_selector.dart` → Test fret calculations
4. **Audio Integration**: Modify `audio_controller.dart` → Update audio services → Test playback

#### **Quiz System Features**
5. **Quiz Questions**: Add to appropriate section files → *Reference: `quiz_creation.md`*
6. **Question Types**: Implement new interaction patterns → *Reference: `question_type_integration.md`*
7. **Scale Strip Questions**: Develop visual interactions → *Reference: `scale_strip_question.md`*

#### **User & Data Features**
8. **UI Components**: Follow widget patterns in `/widgets/` → Implement proper state management
9. **Firebase Integration**: Update service layers → *Reference: `persistence_integration.md`*
10. **Learning Content**: Create educational topics → *Reference: `sections_and_topics_creation.md`*
11. **Subscription Features**: Integrate premium functionality → *Reference: `stripe_integration.md`*

### **Testing & Debugging Protocol**
1. **Check Browser Console**: Web-specific errors and performance warnings
2. **Verify Music Constants**: Ensure scales/chords match music theory standards
3. **Test State Updates**: Confirm Provider notifications and widget rebuilds
4. **Validate Calculations**: Check MIDI numbers and interval mathematics
5. **Review Performance**: Profile CustomPainter and state management efficiency
6. **Quiz Validation**: Test question generation and answer checking logic
7. **Payment Testing**: Verify subscription flows and webhook processing
8. **Firebase Testing**: Validate authentication and data synchronization
9. **Audio Testing**: Confirm audio playback and synthesis functionality

## Future Enhancements

### **Planned Features**
- **Advanced Audio**: Real-time audio generation, ear training exercises
- **Interactive Fretboard Questions**: Touch-based quiz interactions
- **Social Learning**: Collaborative sessions and shared progress
- **Mobile Applications**: Native iOS/Android apps with full feature parity
- **Additional Instruments**: Piano, bass, ukulele, mandolin support
- **Advanced Theory**: Jazz harmony, composition tools, modal interchange
- **AI Integration**: Personalized learning paths and intelligent recommendations

### **System Scalability**
- **Microservices**: Potential migration to distributed backend services
- **Content Management**: Dynamic content creation and management system
- **Real-time Collaboration**: Multi-user learning sessions and competitions
- **Advanced Analytics**: Machine learning-based progress analysis
- **Internationalization**: Multi-language support and cultural adaptations

## Security & Compliance

### **Data Protection**
- **Firebase Security Rules**: Comprehensive access control and data validation
- **User Privacy**: GDPR compliance and data anonymization
- **Payment Security**: PCI DSS compliance with Stripe integration
- **Authentication**: Secure JWT token handling and session management

### **Error Handling & Monitoring**
- **Comprehensive Logging**: Detailed error tracking and performance monitoring
- **User Feedback**: Graceful error handling and informative user messages
- **System Recovery**: Automatic retry mechanisms and fallback strategies
- **Performance Monitoring**: Real-time application performance tracking

---

## Summary

Theorie is a full-stack music education platform combining advanced Flutter frontend development with robust Firebase Functions backend, comprehensive Stripe payment integration, and sophisticated music theory visualization. The system provides a complete learning experience from basic note recognition to advanced harmonic analysis, supported by intelligent quiz systems, progress tracking, and premium subscription features.

**When making any system modifications, always consult the relevant integration documentation files listed above to ensure consistency and maintain system integrity.**