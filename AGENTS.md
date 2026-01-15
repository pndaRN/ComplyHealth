# AGENTS.md

This file provides guidance to agentic coding assistants working with code in this repository.

## Project Overview

ComplyHealth is a cross-platform medical condition and medication tracker with a Flutter mobile frontend and Go backend API. The app allows users to track chronic conditions (using ICD-10 codes), manage medications, and access educational resources.

## Build/Lint/Test Commands

### Flutter (Frontend)
```bash
# Navigate to frontend directory first
cd frontend

# Install dependencies
flutter pub get

# Generate Hive adapters (required after model changes)
flutter pub run build_runner build

# Run app on connected device/emulator
flutter run

# Build for specific platform
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web

# Testing
flutter test               # Run all tests
flutter test test/widget_test.dart  # Run single test file
flutter test --coverage    # Run tests with coverage

# Code quality
flutter analyze            # Lint code
flutter format lib/        # Format code

# Run single test with specific filter
flutter test --plain-name "test_name"
```

### Go (Backend)
```bash
# Navigate to backend directory first
cd backend

# Install dependencies
go mod download

# Run server (port 8080)
go run main.go

# Build binary
go build

# Run tests
go test ./...              # Run all tests
go test -v ./...            # Run tests with verbose output
go test ./package_name      # Run tests for specific package
```

## Code Style Guidelines

### Flutter/Dart

**Imports**:
- Group imports in order: `dart:*`, `package:*`, then relative imports
- Use blank lines between import groups
- Example:
```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/medication.dart';
import '../widgets/custom_widget.dart';
```

**Types**:
- Use explicit types for all variables, parameters, and return values
- Never use `var` for local variables - use final/const with explicit type
- Example: `final List<Medication> medications = [];` not `var medications = [];`

**Naming**:
- camelCase for variables and methods: `userName`, `getMedicationList()`
- PascalCase for classes: `MedicationModel`, `CustomWidget`
- snake_case for files: `medication_service.dart`, `custom_widget.dart`
- SCREAMING_SNAKE_CASE for constants: `const int MAX_RETRY_COUNT = 3;`

**State Management**:
- Use Riverpod providers, avoid setState
- Create providers in `core/state/` if shared across features
- Follow NotifierProvider pattern: `final myProvider = NotifierProvider<MyNotifier, MyState>(MyNotifier.new);`
- Update state immutably: `state = [...state, newItem];`

**Widgets**:
- Prefer const constructors whenever possible
- Use keys for dynamic lists: `ListView.builder(key: ValueKey('medications'), ...)`
- ConsumerStatefulWidget for widgets that need to watch providers
- Use Builder widget for context-dependent operations

**Error Handling**:
- Use try-catch for async operations
- Log errors with context: `debugPrint('Failed to load medications: $error');`
- Return appropriate error states from providers
- Use Result types where appropriate for complex error handling

### Go

**Formatting**:
- Always use `gofmt` before committing
- Follow Go conventions for line length (80-120 characters)

**Naming**:
- camelCase for private names: `privateVariable`
- PascalCase for exported names: `PublicVariable`
- Use short, clear variable names in small scopes

**Error Handling**:
- Always handle errors explicitly
- Return errors as last return value: `(result, error)`
- Use defer for cleanup operations
- Wrap errors with context: `fmt.Errorf("failed to save medication: %w", err)`

**Imports**:
- Group standard library, third-party, and local imports
- Use blank lines between groups

### General Guidelines

**Comments**:
- Only add comments for complex business logic
- Explain "why" not "what" - code should be self-documenting
- Use doc comments for public APIs

**Dependencies**:
- Always check pubspec.yaml/go.mod before adding new packages
- Prefer built-in solutions over external dependencies
- Keep dependencies minimal and well-maintained

**File Organization**:
- Feature-based architecture for Flutter features
- Each feature contains: screens/, widgets/, dialogs/, utils/ subdirectories
- Core functionality in `lib/core/` for shared code
- Models use Hive for local persistence

**Testing**:
- Write widget tests for UI components
- Write unit tests for business logic
- Test files should be in `test/` directory mirroring lib structure
- Use descriptive test names that explain what is being tested

## Key Implementation Patterns

### Adding New Hive Models
1. Add annotations: `@HiveType(typeId: N)` with unique typeId
2. Add `@HiveField(N)` to each field  
3. Add `part 'model_name.g.dart';` directive
4. Run `flutter pub run build_runner build`
5. Register adapter in `main.dart`: `Hive.registerAdapter(ModelAdapter())`

### Provider Pattern
- Providers extend `Notifier<State>`
- Manage Hive box lifecycle: open → cache → close
- Expose async methods for CRUD operations
- Update state immutably: `state = state.copyWith(item: newItem);`

### Working with Date/Time
- Use `DateTime.now()` for current time
- Normalize dates for consistent comparison: `DateTime(year, month, day)`
- Use intl package for formatting: `DateFormat('MMM d, y').format(date)`
- Consider timezone handling with flutter_timezone package

### API Integration Patterns
- Always handle offline scenarios gracefully
- Use retry logic with exponential backoff
- Cache data locally for offline access
- Provide loading and error states to users

## Development Workflow

1. **Model Changes**: Modify model → run build_runner → register adapter if new
2. **New Features**: Create feature directory with screen/dialogs/widgets as needed
3. **State Management**: Create provider in `core/state/` if shared across features  
4. **Testing**: Write widget tests for UI, unit tests for business logic
5. **Code Review**: Run `flutter analyze` and `flutter format` before committing

## Critical Rules

- **Never commit** build artifacts or generated files (except `.g.dart` files)
- **Always run** `flutter pub run build_runner build` after model changes
- **Must update** CHANGELOG.md for all committed changes
- **Never modify** credential references in codemagic.yaml
- **Always use** const constructors for widgets that don't change
- **Prefer explicit types** over `var` in Dart code