# Notification System Tests

This document describes the comprehensive test suite for the SmartPatient notification system.

## Overview

The notification system in SmartPatient handles medication reminders using local notifications. These tests validate the notification logic, medication handling, time formatting, and various edge cases.

## Test File

- **Location**: `test/notification_service_test.dart`
- **Testing**: Notification system logic including medication models, time handling, notification IDs, and payloads

## Running the Tests

### Run all tests
```bash
cd frontend
flutter test
```

### Run notification tests specifically
```bash
cd frontend
flutter test test/notification_service_test.dart
```

### Run tests with verbose output
```bash
cd frontend
flutter test --reporter expanded
```

## Test Coverage

The test suite includes **76 tests** organized into the following groups:

### 1. Medication Model Validation (4 tests)
- Creating scheduled medications
- Creating PRN (as-needed) medications
- Handling multiple scheduled times
- Handling medications with no scheduled times

### 2. PRN Medication Logic (3 tests)
- PRN medications should not have scheduled times
- Handling PRN medications with dose tracking
- Handling PRN medications without max doses

### 3. Scheduled Medication Logic (3 tests)
- Single daily dose handling
- Multiple daily doses handling
- Many scheduled times (10+) handling

### 4. Time Parsing and Validation (3 tests)
- Parsing valid time strings (HH:mm format)
- Handling edge case times (00:00, 12:00, 23:59)
- Validating time format consistency

### 5. Time Formatting Logic (4 tests)
- Formatting AM times correctly
- Formatting PM times correctly
- Padding minutes with zero
- Handling all 24 hours

### 6. Notification ID Generation Logic (4 tests)
- Consistent IDs for same medication and time index
- Different IDs for different time indices
- Different IDs for different medications
- Handling various medication ID formats

### 7. Notification Payload Format (3 tests)
- Creating valid payload format (medicationId|timeStr)
- Handling multiple payloads for same medication
- Parsing payload back to components

### 8. Medication List Operations (3 tests)
- Handling empty medication lists
- Filtering PRN vs scheduled medications
- Counting total scheduled notifications

### 9. Edge Cases and Error Handling (6 tests)
- Very long medication names (200+ characters)
- Special characters in medication names
- Various medication ID formats
- Medications with no conditions
- Medications with multiple conditions

### 10. Time Zone Handling (5 tests)
- Timezone database initialization
- Getting local timezone
- Creating timezone-aware datetime objects
- Handling scheduling times in the future
- Handling past times by scheduling for next day

### 11. Medication JSON Serialization (2 tests)
- Serializing medication to JSON
- Deserializing medication from JSON

## Key Features Tested

### ✅ PRN vs Scheduled Medications
Tests verify that:
- PRN medications do NOT trigger notifications
- Scheduled medications properly generate notifications for each time
- isPRN flag is correctly honored

### ✅ Time Formatting
Tests verify that:
- 24-hour time (HH:mm) is correctly parsed
- Times are displayed in 12-hour format with AM/PM
- Minutes are zero-padded (e.g., 9:05 AM, not 9:5 AM)
- Edge cases like midnight (12:00 AM) and noon (12:00 PM) are correct

### ✅ Notification ID Generation
Tests verify that:
- Same medication + time index always produces same ID (consistency)
- Different time indices produce different IDs (uniqueness)
- Different medications produce different IDs
- Hash collisions are minimal

### ✅ Notification Payload
Tests verify that:
- Payload format is `medicationId|timeStr`
- Payloads can be parsed back to original components
- Multiple notifications for same medication have unique payloads

### ✅ Edge Cases
Tests cover:
- Empty medication lists
- Medications with no scheduled times
- Very long medication names
- Special characters in names
- Multiple conditions per medication
- Timezone-aware scheduling

## Implementation Details

### Helper Functions

The test file includes helper functions that replicate the private methods from `NotificationService`:

```dart
// Format time for display (mimics _formatTime in NotificationService)
String formatTime(int hour, int minute)

// Generate notification ID (mimics _generateNotificationId in NotificationService)
int generateNotificationId(String medicationId, int timeIndex)
```

These functions allow testing the notification logic without requiring access to private methods or mocking.

### Timezone Initialization

Tests initialize the timezone database in `setUpAll()` to ensure timezone-aware datetime operations work correctly:

```dart
setUpAll(() {
  tz.initializeTimeZones();
});
```

## What's NOT Tested

These tests focus on the **logic and data handling** of the notification system. The following are NOT tested:

- ❌ Actual notification scheduling (requires platform integration)
- ❌ Notification display on devices
- ❌ Notification tap handling and navigation
- ❌ Permission requests on Android/iOS
- ❌ Integration with `flutter_local_notifications` plugin

These would require integration tests or mocking the `FlutterLocalNotificationsPlugin`.

## Dependencies

The tests use only standard Flutter testing dependencies:

- `flutter_test` - Flutter testing framework
- `timezone` - Timezone handling (already used by NotificationService)
- Medication model from the app

No additional mocking libraries are required.

## Test Structure

Each test group focuses on a specific aspect:

```
NotificationService - Medication Model Tests
├── Medication Model Validation
├── PRN Medication Logic
├── Scheduled Medication Logic
├── Time Parsing and Validation
├── Time Formatting Logic
├── Notification ID Generation Logic
├── Notification Payload Format
├── Medication List Operations
├── Edge Cases and Error Handling
├── Time Zone Handling
└── Medication JSON Serialization
```

## Future Improvements

Potential enhancements for the test suite:

1. **Integration Tests**: Test actual notification scheduling with mocked plugin
2. **Widget Tests**: Test notification-related UI components
3. **Performance Tests**: Test notification scheduling with large medication lists
4. **Mock Tests**: Use mockito to test NotificationService methods directly
5. **Coverage Reports**: Generate code coverage reports with `flutter test --coverage`

## Troubleshooting

### Tests fail with "timezone not initialized"
- Ensure `setUpAll()` initializes timezones before tests run

### Tests fail with medication model errors
- Ensure Hive adapters are generated: `flutter pub run build_runner build`

### Import errors
- Run `flutter pub get` to install dependencies

## Contributing

When adding new notification features:

1. Add corresponding tests to this file
2. Update this README with new test descriptions
3. Ensure all tests pass before committing
4. Aim for >80% code coverage

## Related Files

- `lib/core/services/notification_service.dart` - NotificationService implementation
- `lib/core/models/medication.dart` - Medication model
- `lib/core/state/medication_provider.dart` - Medication state management
- `test/widget_test.dart` - Main widget tests
