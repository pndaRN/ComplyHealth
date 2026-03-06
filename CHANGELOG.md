# Changelog

All notable changes to the ComplyHealth project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Added Roboto and MaterialIcons font assets for consistent typography across platforms

### Changed
- Notes fields on condition detail, medication detail, and profile note creation now remain visible after saving — the save button disables until new text is entered, letting users continue adding notes without losing context
- Redesigned Health Overview widget: removed outer container box and made each condition independently collapsible to show/hide related medications
- Migrated from hive to hive_ce package for improved Hive database support
- Simplified profile screen by replacing inline widgets with navigation buttons for Notebook, Adherence Metrics, Help and Feedback, and About Us
- Removed XP/level system display from profile header for a cleaner interface
- Feedback dialog now pre-selects the feedback type when opened from specific Help and Feedback options

### Removed
- Removed Firebase Testing disclaimer from About screen

## [1.6.0] - 2026-02-05

### Added
- Added custom application icons for Android and iOS using the branded ComplyHealth logo.
- Implemented a 1-second splash screen with dynamic theme support (white logo for light mode, blue logo for dark mode).
- Integrated notebook history into the "Notes" tab of the Condition Detail screen, allowing users to view and manage past notes alongside their scratchpad.
- Added note count indicators to condition cards in the Health tab, providing a quick summary of recorded notes for each condition.
- Integrated notebook history into the "Notes" tab of the Medication Detail screen, enabling consistent note management across health conditions and medications.
- Added note count indicators to medication cards in the Medications tab, showing the volume of recorded notes at a glance.
- Added "Time Sensitive" toggle to medications, allowing users to mark meds that shouldn't trigger "Late" alerts if missed.
- Added friendly, cycling notification messages based on time of day (e.g., "Before coffee gets cold ☕").

### Changed
- Reorganized Medication Detail screen to consolidate "Overview" and "Schedule" tabs into a simplified two-tab interface (Overview and Notes).
- Merged medication summary and interactive scheduling/PRN tracking into the unified "Overview" tab for better information density.
- Redesigned the Dose Logging Dialog to be cleaner and friendlier, with a simplified main view for taking doses and a separate, streamlined view for skipping.
- Moved the medication status icon ("checkmark") to the right side of tiles in the MAR tab for better visual flow.
- Added a "More Options" menu button to each medication tile in the MAR tab, providing access to skip reasons and time editing.
- Added a high-quality 800ms "hold-to-take" animation with color inversion and progress tracking to all medication items in the MAR tab.
- Refactored the MAR tab to use a grouped timeline with auto-expanding dropdowns for each medication timing.
- Dropdowns now automatically expand if a medication is due within one hour or is late/unlogged.
- Added a subtle red tint to late time slots in the MAR tab to highlight actions needed.
- Improved the smoothness and visual feedback of the "Next Due" card completion animation (note: Next Due card moved to dropdown structure).
- Defaulted "actually taken" time to the current time in the late dose logging dialog for a more intuitive user experience.
- Replaced collapsible category tiles in the Health screen's "Browse All" view with a direct list of conditions and static category headers for better immediate visibility.
- Improved search results in the Health screen by displaying a flat list of matching conditions directly.
- Renamed "At A Glance" dashboard widget to "Health Overview".
- Updated "Health Overview" widget to be permanently open, removing the expandable/collapsible functionality for better immediate visibility.
- Enclosed each condition within its own styled box inside the "Health Overview" widget to improve visual separation.
- Cleaned up unused imports across `health_screen.dart`, `dashboard_screen.dart`, and `profile_screen.dart`.
- Updated notifications to group multiple medications scheduled for the same time into a single alert.
- Redesigned "Add Medication" and "Edit Medication" flows to use full-screen bottom sheets instead of dialogs for better usability.
- Improved medication form with inline condition selection chips and a clear "Scheduled" vs "As Needed" toggle.
- Updated notification tap behavior to navigate directly to the Medications screen for immediate action.
- Deprecated legacy notification scheduling methods in favor of a new grouped scheduling system.

## [1.5.0] - 2026-02-03

### Changed
- Standardized AppBars across all tabs for global UI consistency.
- Creation of shared `AppMoreMenu` and `AppSearchBar` widgets to unify header actions and search experiences.
- Refactored Dashboard header to use a standard Material 3 AppBar with optimized font sizes.

### Fixed
- Fixed an issue where cancelling the "Mark as Taken (Late)" dialog would leave the medication card in a non-interactive state.
- Resolved "ScrollController has no ScrollPosition attached" exception in medication add/edit forms.
- Fixed visibility issues in late-dose logging and medication detail dialogs for dark mode users.
- Improved auto-selected condition visibility by using theme-aware primary colors.
- Added actual taken time display to the MAR tab timeline for better dose tracking clarity.

## [1.4.1] - 2026-01-28

### Added
- Added "Daily MAR" tab to Medications screen with "Focus & Flow" layout (Next Due card + Daily Timeline).
- Refactored Medications screen to separate daily tracking from medication management.

### Changed
- Dashboard percentage text color updated to white for better visibility.
- Reorganized dashboard layout to place "At A Glance" summary below "Today's Medications".
- Improved Notebook widget responsiveness: Header layout now adapts to small screens (width < 400px) by stacking the Create button and Sort options on a second line.
- Updated Daily MAR "Next Due" card to use a right-aligned checkmark button for consistency with dashboard.
- Daily MAR "quick take" action now skips the confirmation dialog for scheduled doses, streamlining the workflow.
- Added checkmark animation to "Next Due" card in Daily MAR tab.
- Removed "Today's Medications" widget from Dashboard (functionality moved to Daily MAR tab).
- Fixed late dose logging in Daily MAR to prompt for time when medication is overdue.
- Refactored MedicationsScreen for better separation of concerns and maintainability.
- Cleaned up lint warnings and improved logging practices across the app.

### Fixed
- Resolved Hive "box already open with dynamic type" error by synchronizing encryption migration and adding robust provider type checks.
- Fixed "LateInitializationError: Field '_local' has not been initialized" by adding robust timezone initialization with UTC fallback.
- Fixed "unexpected null value error" in Daily MAR tab by safely handling pending medication logs.

## [1.4.0] - 2026-01-27

### Added
- Added progress bar to dashboard to help medication tracking
- Create button on notebook on profile


### Fixed

- Fixed Android 12+ crash caused by missing exact alarm permission (SCHEDULE_EXACT_ALARM)
- Added graceful fallback to inexact alarms when user denies exact alarm permission
- Notebook on medication tab's slow response

### Changed

- Seven day adherence no longer under widget

## [1.3.0] - 2026-01-17

### Removed

- Unused custom widget files (AppButton, AppCard, AppTextField) that were never integrated
- Unused design tokens file that was only referenced by removed widgets

### Added

- Multi-theme selection with 11 theme options across 4 categories (Standard, Accessibility, Calming, Practical)
- Visual theme picker with preview cards showing color swatches for each theme
- New themes: High Contrast Light, High Contrast Dark, AMOLED Black, Ocean, Forest, Lavender, Sepia, and Muted
- Theme persistence with automatic migration from previous light/dark/system preference
- Notebook section in Profile screen to save and organize notes from conditions and medications
- "New Note" floating button in condition and medication Notes tabs to save notes to notebook
- Notes are saved with format "Source Name - DD-MM-YYYY" and confirmation popup "Note saved in notebook in profile"
- Notebook sorting options: chronological (by date) or grouped by condition/medication with expandable cards
- Notes tab added to medication detail screen with auto-save functionality (matching conditions pattern)
- Personal notes field added to medications for tracking medication-specific notes
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
- Improved dashboard gradient with adaptive colors for light/dark modes (blue fade to near-white in light, blue fade to near-black in dark)
- Extended dashboard gradient further down the screen for better visual effect
- Enhanced light mode card styling with better contrast, more visible borders, and neutral shadows

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
