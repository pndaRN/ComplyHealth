# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SmartPatient is a cross-platform medical condition and medication tracker with a Flutter mobile frontend and Go backend API. The app allows users to track chronic conditions (using ICD-10 codes), manage medications, and access educational resources.

## Architecture

### Frontend (Flutter)
- **Structure**: Feature-based architecture with shared core modules
  - `lib/core/`: Shared models, services, and state management
    - `models/`: Hive-based data models (Disease, Medication, Profile)
    - `services/`: Business logic services (e.g., ICDService for condition lookups)
    - `state/`: Riverpod providers for state management
  - `lib/features/`: Feature modules (dashboard, conditions, medications, education, profile)
    - Each feature contains screens, dialogs, widgets, and utilities

- **State Management**: Riverpod with NotifierProvider pattern
  - Providers manage Hive box operations and expose state
  - Example: `conditionsProvider` in `core/state/conditions_provider.dart`

- **Data Persistence**: Hive (local NoSQL database)
  - Models use Hive annotations (`@HiveType`, `@HiveField`)
  - Type adapters generated via `build_runner`
  - Boxes: 'conditions', 'medications', 'profile'

- **Navigation**: Bottom navigation bar with 5 main screens (defined in `main.dart`)

- **ICD-10 Data**: Static JSON asset (`assets/icd10_chronic.json`) containing chronic condition codes
  - Includes code, name, category, commonName, and description fields
  - Searchable by code, name, or commonName via ICDService

### Backend (Go)
- **Framework**: Gin web framework
- **Current State**: Basic API skeleton with health check endpoint (`/ping`)
- **Location**: `backend/main.go`

## Common Commands

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

# Code quality
flutter analyze            # Lint code
flutter format lib/        # Format code
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
go test ./...
```

### Python Scripts (Data Management)
```bash
# Navigate to frontend/scripts directory
cd frontend/scripts

# Setup (one-time)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Update conditions from Google Sheets
source venv/bin/activate
python update_conditions_from_sheets.py

# Deactivate when done
deactivate
```

## Code Style Guidelines

### Flutter/Dart
- **Imports**: Group imports (dart:*, package:*, relative imports) with blank lines between groups
- **Types**: Use explicit types for all variables, parameters, and return values
- **Naming**: camelCase for variables/methods, PascalCase for classes, snake_case for files
- **State Management**: Use Riverpod providers, avoid setState
- **Widgets**: Prefer const constructors, use keys for dynamic lists
- **Error Handling**: Use try-catch for async operations

### Go
- **Formatting**: Use `gofmt`
- **Naming**: camelCase for private, PascalCase for exported
- **Error Handling**: Return errors explicitly, use defer for cleanup
- **Imports**: Group standard library, third-party, and local imports

### General
- **Comments**: Only for complex business logic
- **Dependencies**: Check pubspec.yaml/go.mod before adding packages

## Key Implementation Notes

### Adding New Hive Models
1. Add annotations to model class (`@HiveType(typeId: N)` with unique typeId)
2. Add `@HiveField(N)` to each field
3. Add `part 'model_name.g.dart';` directive
4. Run `flutter pub run build_runner build`
5. Register adapter in `main.dart`: `Hive.registerAdapter(ModelAdapter())`

### Working with Conditions
- Conditions use ICD-10 codes as unique identifiers
- Search includes code, name, and commonName fields
- Data stored in Hive 'conditions' box with code as key
- Static condition database loaded from JSON asset via ICDService

### Working with Medications
- Medications have UUID identifiers
- Each medication links to a condition by conditionName
- Validation logic in `features/medications/utils/medication_validator.dart`

### Provider Pattern
- Providers extend `Notifier<State>`
- Manage Hive box lifecycle (open, cache, close)
- Expose async methods for CRUD operations
- Update state immutably: `state = [...state, newItem]`

## Development Workflow

1. **Model Changes**: Modify model → run build_runner → register adapter if new
2. **New Features**: Create feature directory with screen/dialogs/widgets as needed
3. **State Management**: Create provider in `core/state/` if shared across features
4. **Testing**: Write widget tests for UI, unit tests for business logic
