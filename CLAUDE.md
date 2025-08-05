# CLAUDE.md - Theorie Development Guidelines & Project Philosophy

## Project Overview & Documentation Structure

### **Primary Project Reference: `overview.md`**
**`overview.md`** is the **central architectural reference** for the entire Theorie system. It provides:
- **Complete project structure** with detailed directory listings and file purposes
- **Full-stack architecture overview** including Flutter frontend, Firebase Functions backend, and Stripe integration
- **System integration points** and data flow diagrams
- **Technology stack specifications** and deployment architecture
- **Performance optimization strategies** for both frontend and backend components

**When to consult `overview.md`**: Start here for any development task to understand the complete system context, locate relevant files, and understand how components interact.

### **Specialized Integration Documentation**
The following documentation files provide detailed implementation guidance for specific system components. **Always reference these when working on their respective systems:**

#### **`persistence_integration.md`** - Data Storage & Synchronization
**Purpose**: Complete guide for data persistence, storage strategies, and synchronization systems
**Use when**: 
- Adding new user data fields or preferences
- Modifying local storage (SharedPreferences) implementation
- Implementing offline functionality or data caching
- Working with Firebase Firestore integration
- Troubleshooting data synchronization issues
- Handling data conflicts between local and cloud storage

#### **`question_type_integration.md`** - Quiz System Extension
**Purpose**: Framework for creating and integrating new interactive question types
**Use when**:
- Adding new question types beyond multiple choice
- Creating custom question widgets and interactions
- Implementing visual or audio-based quiz elements
- Extending the quiz system's capabilities
- Modifying answer validation logic
- Integrating questions with the unified quiz generator

#### **`quiz_creation.md`** - Educational Content Development
**Purpose**: Standards and workflows for creating high-quality quiz content
**Use when**:
- Creating new quiz questions for any topic
- Organizing educational content and learning paths
- Implementing quiz session workflows
- Maintaining quiz quality and educational standards
- Setting up topic-based quiz organization
- Ensuring quiz content accuracy and pedagogical value

#### **`scale_strip_question.md`** - Interactive Visual Questions
**Purpose**: Specialized documentation for the Scale Strip interactive question system
**Use when**:
- Working with Scale Strip visual interfaces
- Implementing interactive music theory exercises
- Creating questions that require visual selection or pattern recognition
- Debugging scale strip functionality
- Modifying the scale strip rendering or interaction logic

#### **`sections_and_topics_creation.md`** - Learning Content Organization
**Purpose**: Guidelines for creating educational sections and progressive learning topics
**Use when**:
- Adding new learning sections or tiers
- Creating educational topics and content
- Organizing curriculum progression and difficulty scaling
- Implementing the 8-tier learning system
- Ensuring content quality and educational progression
- Integrating learning content with quiz systems

#### **`stripe_integration.md`** - Payment Processing & Subscriptions
**Purpose**: Complete Stripe integration guide for payment processing and subscription management
**Use when**:
- Implementing payment features or subscription tiers
- Working with Stripe webhooks or payment flows
- Handling billing, cancellations, or subscription modifications
- Adding premium feature access controls
- Troubleshooting payment processing issues
- Ensuring PCI compliance and payment security

---

## Core Project Philosophy & Design Principles

### **1. Strict MVC Architecture**
Theorie follows a **rigid Model-View-Controller pattern** with absolute separation of concerns:

```
Models (Data & Domain Logic)
    ↓ Pure business operations, no UI dependencies
Controllers (Business Logic & State Management)  
    ↓ All calculations, state updates, no rendering
Views (UI Components & Rendering)
    ↑ User interactions only, no business logic
```

**Fundamental Rules:**
- **No business logic in UI components** - All music theory calculations, quiz logic, and data processing must be in controllers or utilities
- **No UI dependencies in models** - Models contain only data structures and domain logic
- **Controllers manage state** - All state changes flow through controllers using Provider pattern
- **Views are passive** - UI components only render data and report user interactions

### **2. Separation of Concerns & Functional Independence**
Each system component must be **functionally independent** and **single-purpose**:

#### **File Responsibility Principle**
- **One Purpose Per File**: Each file serves exactly one clear, well-defined responsibility
- **No Cross-Cutting Logic**: Business logic doesn't leak between unrelated systems
- **Interface-Based Design**: Systems communicate through well-defined interfaces
- **Testable Isolation**: Each component can be tested independently

#### **System Independence**
- **Music Theory System**: Completely separate from UI rendering
- **Quiz System**: Independent of music theory calculations
- **Persistence Layer**: Isolated from business logic
- **Payment System**: Self-contained with clear boundaries
- **Authentication**: Separate from application business logic

### **3. File Size & Clarity Constraints**
**Maintain files around 500 lines maximum** unless exceptional circumstances justify larger files:

#### **Approved Exceptions:**
- **`chord.dart`**: Contains hundreds of chord variations and formulas - domain complexity justifies size
- **`unified_quiz_generator.dart`**: Comprehensive question generation system - algorithmic complexity justifies size
- **Firebase Functions (`index.ts`)**: Complete backend API with multiple endpoints - functional cohesion justifies size

#### **File Clarity Standards:**
- **Clear Naming**: File names immediately indicate purpose and scope
- **Logical Grouping**: Related functionality grouped in directories
- **Minimal Dependencies**: Each file imports only what it actually needs
- **Comprehensive Documentation**: Complex logic thoroughly documented inline

### **4. State Management Philosophy**
**Provider Pattern Implementation** with **granular state updates**:

```dart
// ✅ Correct: Targeted state access
Consumer<AppState>(
  selector: (context, appState) => appState.currentScale,
  builder: (context, currentScale, child) => ScaleDisplay(scale: currentScale),
)

// ❌ Incorrect: Broad state access causing unnecessary rebuilds
Consumer<AppState>(
  builder: (context, appState, child) => ScaleDisplay(scale: appState.currentScale),
)
```

#### **State Update Principles:**
- **Batch Related Changes**: Multiple related state changes combined into single notifications
- **Minimal Rebuilds**: Use Provider selectors to target specific widget updates
- **Immutable Data**: State objects are immutable; create new instances for changes
- **Clear State Flow**: State changes always flow through controllers, never directly from UI

### **5. Performance & Optimization Philosophy**
**Optimization is architectural, not afterthought**:

#### **Rendering Performance**
- **CustomPainter for Complex Graphics**: Fretboard rendering uses Canvas for maximum performance
- **Selective Repainting**: `shouldRepaint` logic prevents unnecessary rendering cycles
- **Color Caching**: Pre-calculated color maps for instant theory visualization
- **Widget Composition**: Efficient widget trees with minimal nesting

#### **Memory Management**
- **Proper Disposal**: All controllers and listeners properly disposed
- **Cached Calculations**: Expensive operations cached with invalidation strategies
- **Lazy Loading**: Resources loaded only when needed
- **Memory Profiling**: Regular profiling to identify and eliminate memory leaks

### **6. Testing & Quality Assurance Philosophy**
**Testing is integral to development, not optional**:

#### **Testing Strategy**
- **Unit Tests**: All business logic thoroughly tested in isolation
- **Widget Tests**: Critical UI interactions and state management verified
- **Integration Tests**: End-to-end user workflows and system integration tested
- **Performance Tests**: Rendering and state management performance validated

#### **Quality Standards**
- **Educational Accuracy**: All music theory and quiz content verified for correctness
- **Code Review**: All changes reviewed for architectural compliance
- **Documentation Currency**: Documentation updated with every architectural change
- **Accessibility**: UI components tested for accessibility compliance

---

## Development Workflow & Best Practices

### **Before Starting Any Development Task**

1. **Consult `overview.md`** - Understand the complete system context and locate relevant files
2. **Review Relevant Integration Documentation** - Study the specific `.md` file for the system you're modifying
3. **Understand Data Flow** - Trace how data flows through the system for your changes
4. **Plan State Management** - Design how your changes will integrate with Provider pattern
5. **Consider Testing Strategy** - Plan unit tests, widget tests, and integration tests

### **Common Development Patterns**

#### **Adding New Music Theory Features**
1. **Constants**: Update `music_constants.dart` with new theory data
2. **Models**: Create or extend domain models in `/models/music/`
3. **Controllers**: Implement business logic in appropriate controller
4. **Utils**: Add helper functions in relevant utility files
5. **Views**: Create UI components following widget patterns
6. **Testing**: Write comprehensive tests for all business logic

#### **Extending Quiz System**
1. **Reference `quiz_creation.md`** - Follow established quiz content standards
2. **Question Models**: Create question types in `/models/quiz/`
3. **Generation Logic**: Update `unified_quiz_generator.dart`
4. **UI Components**: Create question widgets in `/views/widgets/quiz/`
5. **Integration**: Update `quiz_integration_service.dart`
6. **Testing**: Validate question generation and answer checking

#### **Adding Payment/Subscription Features**
1. **Reference `stripe_integration.md`** - Follow payment security standards
2. **Backend Functions**: Update Firebase Functions in `functions/src/index.ts`
3. **Frontend Models**: Create payment models in `/models/subscription/`
4. **Service Integration**: Update `subscription_service.dart`
5. **UI Components**: Create payment UI in `/views/widgets/subscription/`
6. **Testing**: Test payment flows thoroughly in sandbox environment

### **Code Quality Standards**

#### **Naming Conventions**
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Methods/Variables**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Private Members**: Leading underscore `_privateMember`

#### **Import Organization**
```dart
// 1. Dart/Flutter packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 2. Third-party packages
import 'package:firebase_auth/firebase_auth.dart';

// 3. Project imports (relative paths)
import '../models/music/note.dart';
import '../controllers/music_controller.dart';
```

#### **Documentation Standards**
- **Public APIs**: Comprehensive documentation with examples
- **Complex Logic**: Inline comments explaining algorithms and calculations
- **Music Theory**: Mathematical formulas and theory concepts clearly explained
- **Integration Points**: Clear documentation of system boundaries and interfaces

### **Performance Monitoring & Debugging**

#### **Regular Performance Checks**
1. **Browser Console**: Monitor for errors, warnings, and performance issues
2. **Flutter DevTools**: Profile widget rebuilds and memory usage
3. **CustomPainter Performance**: Verify efficient rendering and selective repainting
4. **State Management**: Confirm minimal rebuilds and proper Provider usage
5. **Firebase Performance**: Monitor database queries and function execution times

#### **Debugging Protocol**
1. **Check System Integration**: Verify all system boundaries and data flow
2. **Validate Music Theory**: Ensure calculations match established music theory
3. **Test State Updates**: Confirm Provider notifications and widget rebuilds
4. **Review Error Handling**: Ensure comprehensive error handling and user feedback
5. **Performance Analysis**: Profile critical paths and optimize bottlenecks

---

## Architecture Compliance & Maintenance

### **Maintaining MVC Boundaries**
- **Models**: Only data structures and domain logic - no UI dependencies
- **Views**: Only UI rendering and user interaction handling - no business logic
- **Controllers**: All business logic, state management, and data processing

### **System Integration Rules**
- **Always use designated interfaces** - No direct cross-system dependencies
- **Respect abstraction layers** - Don't bypass service layers or controllers
- **Maintain functional independence** - Systems must work independently
- **Clear error boundaries** - Failures in one system don't cascade to others

### **Code Review Checklist**
- [ ] Follows MVC architecture strictly
- [ ] Maintains separation of concerns
- [ ] File size within guidelines (exceptions justified)
- [ ] Comprehensive testing included
- [ ] Documentation updated appropriately
- [ ] Performance implications considered
- [ ] Integration boundaries respected
- [ ] Educational accuracy verified (for quiz/theory content)

---

## Summary

Theorie's architecture emphasizes **clarity, maintainability, and educational excellence**. Every development decision should prioritize:

1. **Architectural Integrity** - Maintain MVC boundaries and separation of concerns
2. **System Independence** - Keep systems functionally independent with clear interfaces
3. **Code Clarity** - Write clear, concise, well-documented code
4. **Educational Quality** - Ensure all content is educationally valuable and theoretically accurate
5. **Performance Excellence** - Design for performance from the beginning
6. **Comprehensive Testing** - Test all business logic and critical interactions

**Remember**: Always consult the appropriate integration documentation files when working on specific systems. The documentation exists to maintain consistency, quality, and architectural integrity across the entire project.

When in doubt, prioritize **clarity over cleverness**, **maintainability over performance**, and **educational value over feature complexity**.