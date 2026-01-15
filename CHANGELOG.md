# Changelog

All notable changes to the ComplyHealth project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced 7-day calendar adherence view on dashboard with date display showing "Today, Jan 14, 2026" format
- Calendar navigation with back button to browse previous weeks and next week button for forward navigation
- Interactive week range display that opens a week picker dialog for selecting specific weeks
- Week picker dialog with full month calendar view, automatic week selection on day tap, and month navigation
- Visual week selection in picker with both background color and border highlighting
- Conditional calendar icon that only appears when user has navigated away from current week
- Interactive calendar days that show medication details dialog when tapped
- Visual selection indicators for tapped days with blue border highlight
- Collapsible calendar widget with expand/collapse functionality and smooth animations
- Slide animations for week transitions with 300ms duration and directional movement
- Loading overlay and button state management during week transitions for professional polish
- Notes tab in condition detail screen for personal notes about each condition with auto-save

### Changed
- Replaced existing AdherenceHistoryWidget with new EnhancedCalendarWidget for improved navigation and user experience
- Updated date display to show selected date with smart formatting ("Today, ..." for current day, full weekday for other days)

### Changed
- Medication name input now auto-capitalizes the first letter of the first word in both add and edit dialogs
- Auto-select single condition in add and edit medication dialogs when only one condition is available
- Auto-selected conditions display with light blue background, blue border, and auto icon with subtle scale animation

## [1.2.4] - 2026-01-12

### Added
- Animated checkmark completion for medications: green outline fills in over 1 second, then card slides off to the right

### Changed
- Refactored Today's Medications widget into smaller, focused components for improved maintainability

### Fixed
- Fixed medication completion not being saved when using checkmark button or late menu (errors were being silently swallowed by AsyncValue.guard)
- Fixed duplicate medication notifications caused by provider rebuilds scheduling notifications multiple times
- Fixed "failed to log dose: type 'null' is not a subtype of type bool" error when logging doses for medications created before the isDismissed field was added

## [1.2.3] - 2026-01-09

### Changed
- Updated medication timing window to clinical standard: 1 hour after scheduled time before marking as missed (previously 30 minutes)

### Fixed
- Fixed adherence showing 0% when auto-mark incorrectly marked all historical doses as missed
- Fixed duplicate medication notifications caused by redundant scheduling at app startup

### Added
- Pull-to-refresh on dashboard to reload all widgets and data
- New "Missed" section in Today's Medications showing recoverable missed doses
- Recovery actions for missed doses: Mark as Taken (with time picker), Mark as Skipped, Dismiss
- Ability to dismiss missed doses to acknowledge them without changing their status

## [1.2.2] - 2026-01-07

### Changed
- Dashboard app bar now scrolls with content (SliverAppBar with floating/snap)
- Dashboard titles adapt to screen size using FittedBox
- Date of birth input now uses date picker instead of text input
- Profile placeholders now show helpful prompts ("Tap Edit to add...")
- Migrated state providers to AsyncNotifierProvider pattern for better async handling
- Replaced deprecated withOpacity() with withValues() for color transparency
- Optimized streak calculation from O(n×365) to O(n) using date grouping
- Optimized medication daily count reset from O(n²) to O(n) using Map lookup

### Fixed
- Removed pre-filled default profile so new users start with empty fields
- Fixed AsyncValue handling across multiple screens preventing runtime errors
- Fixed compliance showing 100% when evening doses were missed (now auto-marks unlogged past doses)
- Fixed JSON typo in Medication.fromJson that caused dosage data loss on import
- Fixed clearAllData() not working with encrypted Hive boxes
- Fixed incorrect AsyncValue.loading() pattern in conditions provider
- Fixed unhandled exceptions in profile XP award background task
- Fixed potential index out of bounds crash in rotating welcome message
- Fixed missing error handling when skipping medication doses
- Fixed unsafe Navigator calls after async operations in medication deletion
- Fixed DateTime.parse crash on invalid date formats in disease/medication import
- Fixed notification time parsing crash on invalid scheduled time format
- Fixed notification ID collisions when medications have many scheduled times
- Fixed dashboard widgets not refreshing when adherence data changes
- Fixed hardcoded colors breaking dark mode in adherence history widget

### Added
- CI/CD & Deployment documentation in CLAUDE.md (branch strategy, Codemagic workflows)
- Changelog requirements section in CLAUDE.md
- Smooth animated expand/collapse transitions on dashboard widgets
- Auto-mark untaken medications as "missed" on app startup for accurate compliance tracking

## [1.2.1] - 2026-01-06

### Changed
- Updated dashboard gradient colors
- Improved "At A Glance" widget formatting

### Added
- Local encryption for all Hive data boxes using AES-256
- Encryption migration service for seamless upgrade from unencrypted data
- Secure key storage using flutter_secure_storage
- Comprehensive encryption tests (40 unit tests)

### Changed
- Updated color scheme to match logo primary color (#0000CC)
- New complementary purple secondary color (#6600CC)
- Improved light mode contrast for better visibility
- Stronger borders, darker secondary text, and better surface distinction
- Updated status colors to match new brand palette

### Fixed
- Condition card text overflow - long medical names now truncate with ellipsis

## [1.1.1] - 2026-01-01

### Added - 2025-12-30
- Firebase beta testing warning on about screen
- Additional text content to website

### Changed - 2025-12-30
- Updated text fields for website content
- Personalized app bar title and removed welcome message from dashboard
- Improved today's medications widget UI

### Changed - 2025-12-26
- Updated group name configuration
- Updated iOS deployment target to 15.0 for Firebase SDK compatibility
- Simplified codemagic.yaml configuration for Firebase distribution
- Renamed codemagic_new.yaml to codemagic.yaml

### Fixed - 2025-12-26
- Fixed Firebase workflow to use DISTRIBUTION_FIREBASE certificate
- Fixed flutter pub get command in CI/CD pipeline
- Added email notifications to build workflow
- Fixed Firebase publishing syntax in codemagic.yaml
- Fixed codemagic.yaml signing and authentication configuration
- Fixed notification timing to use local timezone instead of UTC
- Fixed medication form to show validation errors from top with overlay

### Added - 2025-12-26
- Codemagic YAML configuration for TestFlight and Firebase distribution
- Enhanced medication validation utilities
- UI improvements to conditions and dashboard screens
- Additional ICD-10 chronic condition entries

### Fixed - 2025-12-23
- iOS build configuration in Codemagic
- Android section of codemagic.yaml
- General CI/CD pipeline fixes

### Changed - 2025-12-22
- Updated Codemagic configuration for improved build process

---

## Release Notes

### Recent Highlights
- **UI/UX Improvements**: Enhanced user experience with personalized app bar, improved dashboard layout, and better medication widgets
- **Firebase Integration**: Successfully configured Firebase App Distribution for beta testing with proper iOS and Android builds
- **CI/CD Pipeline**: Streamlined build and deployment process through Codemagic with TestFlight and Firebase distribution
- **Bug Fixes**: Resolved critical timezone issues in notifications and improved medication form validation
- **Platform Support**: Updated iOS deployment target to support latest Firebase SDK features

### Technical Improvements
- Refactored medication validation logic for better error handling
- Optimized Podfile configuration for iOS builds
- Enhanced notification service with proper timezone handling
- Expanded ICD-10 chronic conditions database
