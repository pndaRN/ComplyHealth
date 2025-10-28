# MedSync Agent Guidelines

## Build/Lint/Test Commands
- **Flutter build**: `flutter build apk` (Android) or `flutter build ios` (iOS) or `flutter build web`
- **Flutter run**: `flutter run`
- **Flutter analyze**: `flutter analyze` (linting)
- **Flutter test**: `flutter test` (all tests) or `flutter test test/widget_test.dart` (single test)
- **Code generation**: `flutter pub run build_runner build` (generate Hive adapters)
- **Go build**: `cd backend && go build`
- **Go run**: `cd backend && go run main.go`
- **Go test**: `cd backend && go test ./...`

## Code Style Guidelines

### Flutter/Dart
- **Imports**: Group imports (dart:*, package:*, relative imports) with blank lines between groups
- **Formatting**: Use `flutter format` for consistent formatting
- **Types**: Use explicit types for all variables, parameters, and return values
- **Naming**: camelCase for variables/methods, PascalCase for classes, snake_case for files
- **Error handling**: Use try-catch for async operations, throw exceptions for invalid states
- **State management**: Use Riverpod providers for state, avoid setState in favor of providers
- **Widgets**: Prefer const constructors, use keys for dynamic lists

### Go
- **Formatting**: Use `gofmt` for consistent formatting
- **Naming**: camelCase for variables/functions, PascalCase for exported types
- **Error handling**: Return errors explicitly, use defer for cleanup
- **Imports**: Group standard library, third-party, and local imports with blank lines

### General
- **Comments**: No comments unless explaining complex business logic
- **Dependencies**: Check pubspec.yaml/go.mod before adding new packages
- **Testing**: Write widget tests for UI components, unit tests for business logic