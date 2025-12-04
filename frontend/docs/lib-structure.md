# SmartPatient Frontend: lib/ Folder Structure

## Introduction

The SmartPatient frontend follows a **feature-based architecture** with centralized **core modules**. This architecture promotes code organization, reusability, and maintainability by separating concerns between shared business logic (core) and feature-specific implementations (features).

### Technology Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (NotifierProvider pattern)
- **Local Database**: Hive (NoSQL with generated type adapters)
- **Backend Integration**: Firebase Core
- **Platform Support**: Cross-platform (mobile and web) with conditional imports

### How to Use This Document
- **Finding a File**: Use the directory tree to locate files by path
- **Understanding a Component**: Read the section corresponding to the file or module
- **Adding New Code**: Refer to the Development Guidelines section

---

## Directory Tree

```
lib/
├── main.dart                           # Application entry point
├── firebase_options.dart               # Firebase configuration (generated)
│
├── core/                               # Shared modules used across features
│   ├── models/                         # Hive data models with type adapters
│   │   ├── disease.dart               # ICD-10 condition model
│   │   ├── disease.g.dart             # Generated Hive adapter
│   │   ├── medication.dart            # Medication tracking model
│   │   ├── medication.g.dart          # Generated Hive adapter
│   │   ├── medication_log.dart        # Medication dose logging model
│   │   ├── medication_log.g.dart      # Generated Hive adapter
│   │   ├── profile.dart               # User profile model
│   │   ├── profile.g.dart             # Generated Hive adapter
│   │   ├── education_content.dart     # Educational resources model
│   │   ├── education_content.g.dart   # Generated Hive adapter
│   │   ├── feedback.dart              # User feedback model
│   │   └── feedback.g.dart            # Generated Hive adapter
│   │
│   ├── services/                       # Business logic services
│   │   ├── icd_service.dart           # ICD-10 code lookup and search
│   │   ├── education_service.dart     # Educational content management
│   │   ├── feedback_service.dart      # User feedback processing
│   │   ├── notification_service.dart  # Push notification handling
│   │   ├── condition_report_service.dart # Condition reporting to backend
│   │   ├── pdf_export_service.dart    # PDF export abstraction layer
│   │   ├── pdf_export_service_mobile.dart # Mobile-specific PDF implementation
│   │   └── pdf_export_service_web.dart    # Web-specific PDF implementation
│   │
│   ├── state/                          # Riverpod state management providers
│   │   ├── conditions_provider.dart   # Disease/condition state
│   │   ├── medication_provider.dart   # Medication state with sorting
│   │   ├── profile_provider.dart      # User profile state
│   │   └── adherence_provider.dart    # Medication adherence tracking
│   │
│   ├── utils/                          # Utility functions and helpers
│   │   ├── condition_helper.dart      # Condition-related helpers
│   │   ├── time_formatting_utils.dart # Date/time formatting utilities
│   │   └── pdf_formatting_utils.dart  # PDF formatting utilities
│   │
│   └── widgets/                        # Shared UI components
│       ├── empty_state_widget.dart    # Empty state display
│       └── pdf_export_button.dart     # Reusable PDF export button
│
└── features/                           # Feature-based modules
    │
    ├── dashboard/                      # Home/Dashboard feature
    │   ├── dashboard_screen.dart       # Main dashboard screen
    │   ├── dialogs/
    │   │   └── dose_logging_dialog.dart # Medication dose logging UI
    │   └── widgets/
    │       ├── rotating_welcome_message.dart # Welcome greeting carousel
    │       ├── adherence_metrics_widget.dart # Adherence statistics display
    │       ├── adherence_history_widget.dart # Adherence history visualization
    │       └── todays_medications_widget.dart # Today's medication schedule
    │
    ├── health/                         # Conditions and education feature
    │   ├── health_screen.dart          # Main health/conditions browser
    │   ├── condition_detail_screen.dart # Condition detail view
    │   ├── dialogs/
    │   │   ├── add_custom_condition_dialog.dart # Custom condition entry
    │   │   └── report_condition_dialog.dart     # Report/diagnose condition
    │   └── widgets/
    │       ├── condition_card.dart     # Condition display card
    │       ├── articles_section.dart   # Educational articles section
    │       ├── video_section.dart      # Educational videos section
    │       └── lifestyle_tips_section.dart # Health tips section
    │
    ├── medications/                    # Medication management feature
    │   ├── medications_screen.dart     # Main medications screen
    │   ├── dialogs/
    │   │   ├── medication_add_dialog.dart  # Add new medication dialog
    │   │   ├── medication_edit_dialog.dart # Edit existing medication
    │   │   └── prn_setup_dialog.dart       # PRN medication setup
    │   ├── utils/
    │   │   ├── medication_validator.dart # Medication validation logic
    │   │   └── medication_sorter.dart    # Medication sorting algorithms
    │   └── widgets/
    │       ├── medication_expansion_tile.dart # Expandable medication item
    │       ├── medication_detail_dialog.dart  # Medication details popup
    │       ├── medication_form_content.dart   # Shared medication form UI
    │       ├── prn_section.dart              # PRN-specific UI components
    │       ├── time_picker_section.dart      # Time selection interface
    │       └── timing_preset_buttons.dart    # Quick timing preset buttons
    │
    └── profile/                        # User profile feature
        ├── profile_screen.dart         # Main profile screen
        ├── xp_gain_popup.dart          # XP/gamification reward popup
        ├── dialogs/
        │   └── feedback_dialog.dart    # User feedback submission form
        └── utils/
            └── feedback_validator.dart # Feedback validation logic
```

---

## Core Modules

The `lib/core/` directory contains shared modules used across all features, including data models, business logic services, state management providers, utility functions, and reusable UI components.

### Entry Points

#### main.dart
**Purpose**: Application initialization and entry point for the SmartPatient app.

**Responsibilities**:
- Initializes Flutter bindings and Hive database
- Registers all Hive type adapters for data models (Disease, Medication, Profile, etc.)
- Initializes notification service for medication reminders
- Configures Firebase with platform-specific options
- Pre-loads providers (profile, conditions, medications) with a 200ms delay to ensure data availability before UI renders
- Sets up the main app widget with bottom navigation bar routing to 4 main screens (Dashboard, Health, Medications, Profile)

**Key Dependencies**: Hive, Riverpod, Firebase Core, NotificationService

#### firebase_options.dart
**Purpose**: Platform-specific Firebase configuration generated by FlutterFire CLI.

**Responsibilities**:
- Provides Firebase configuration constants for each platform (iOS, Android, web)
- Contains API keys, project IDs, and platform-specific identifiers
- Used by Firebase.initializeApp() in main.dart

**Note**: This file is auto-generated and should not be manually edited.

---

### Models (lib/core/models/)

Data models define the structure of objects stored in Hive database. Each model uses Hive annotations (`@HiveType`, `@HiveField`) and has a corresponding generated adapter file (`.g.dart`).

#### disease.dart
**Purpose**: Represents a medical condition using ICD-10 coding standard.

**Key Fields**:
- `code` (String): ICD-10 code (e.g., "E11.9" for Type 2 Diabetes)
- `name` (String): Official medical name from ICD-10
- `category` (String): Condition category (e.g., "Endocrine", "Cardiovascular")
- `commonName` (String): Patient-friendly name (e.g., "Diabetes" instead of "Diabetes mellitus type 2")
- `description` (String): Detailed condition description
- `isCustom` (bool): Flag indicating if this is a user-created custom condition
- `personalNotes` (String?): User's personal notes about the condition
- `createdAt` (DateTime?): Timestamp of when condition was added

**Hive Integration**: TypeId 0, stored in 'conditions' box with `code` as the key

**Usage**: Used by ConditionsProvider, HealthScreen, and ConditionCard to track user's medical conditions.

#### medication.dart
**Purpose**: Represents a medication with scheduling, dosage tracking, and PRN (as-needed) support.

**Key Fields**:
- `id` (String): Unique identifier (UUID)
- `name` (String): Medication name (e.g., "Metformin")
- `dosage` (String): Dosage information (e.g., "500mg")
- `conditionNames` (List<String>): Multiple conditions this medication treats
- `isPRN` (bool): Whether medication is taken as-needed vs. scheduled
- `scheduledTimes` (List<String>): Scheduled times in "HH:mm" format
- `maxDailyDoses` (int?): Maximum doses per day for PRN medications
- `currentDoseCount` (int): Number of doses taken today (for PRN tracking)
- `lastDoseCountReset` (DateTime?): Last time the dose counter was reset

**Hive Integration**: TypeId 1, stored in 'medications' box with `id` as the key. Includes custom adapter (MedicationAdapterCustom) for migrating old single-condition data to multi-condition format.

**Special Features**: Supports migration from old data format, handles both scheduled and PRN medications, tracks daily dose limits.

#### medication_log.dart
**Purpose**: Records individual medication doses taken by the user for adherence tracking.

**Key Fields**:
- `id` (String): Unique log entry identifier
- `medicationId` (String): Reference to medication
- `timestamp` (DateTime): When the dose was taken
- `status` (DoseStatus): Whether the dose was taken, missed, or skipped
- `notes` (String?): Optional notes about this dose

**Hive Integration**: TypeId 3, stored in 'medication_logs' box

**Usage**: Used by AdherenceProvider and AdherenceHistoryWidget to track medication adherence over time.

#### profile.dart
**Purpose**: Stores user profile information and gamification data (XP, streaks).

**Key Fields**:
- `firstName`, `lastName` (String): User's name
- `dob` (String): Date of birth
- `allergies` (String): Known allergies
- `xp` (int): Experience points for gamification
- `streak` (int): Consecutive days of medication adherence
- `levelProgress` (double): Progress toward next XP level (0.0-1.0)
- `lastXpAwardDate` (DateTime?): Last time XP was awarded
- `lastPopupShownDate` (DateTime?): Last time XP popup was displayed
- `lastXpGained` (int): Amount of XP gained in last award

**Hive Integration**: TypeId 2, stored in 'profile' box with key 'user'

**Default Behavior**: ProfileProvider creates a default profile with firstName="User" if none exists.

#### education_content.dart
**Purpose**: Represents educational resources (articles and videos) for medical conditions.

**Key Fields**:
- `conditionCode` (String): ICD-10 code this content relates to
- `articles` (List<Article>): List of educational articles
- `videos` (List<Video>): List of educational videos
- `lifestyleTips` (List<String>): Health and lifestyle recommendations

**Nested Models**:
- `Article`: Title, content, source, lastUpdated
- `Video`: Title, url, duration, thumbnail

**Hive Integration**: TypeId 4, stored in 'education_content' box

**Usage**: Used by ConditionDetailScreen to display relevant educational resources for each condition.

#### feedback.dart
**Purpose**: Stores user feedback submissions for app improvement.

**Key Fields**:
- `id` (String): Unique feedback identifier
- `userId` (String?): Optional user identifier
- `category` (String): Feedback category (bug, feature request, etc.)
- `message` (String): Feedback content
- `timestamp` (DateTime): When feedback was submitted
- `rating` (int?): Optional star rating (1-5)

**Hive Integration**: TypeId 5, stored in 'feedback' box

**Usage**: Used by FeedbackDialog and FeedbackService to collect and submit user feedback.

---

### Services (lib/core/services/)

Services encapsulate business logic and provide interfaces to external resources (APIs, local storage, system services).

#### icd_service.dart
**Purpose**: Loads and searches ICD-10 chronic condition codes from static JSON asset.

**Key Methods**:
- `loadAll()`: Loads all chronic conditions from `assets/icd10_chronic.json`
- `search(all, term)`: Searches conditions by code, name, or commonName

**Data Source**: Static JSON file containing curated list of chronic conditions with ICD-10 codes, categories, and descriptions.

**Usage**: Used by HealthScreen to populate the condition browser and search functionality.

#### education_service.dart
**Purpose**: Manages educational content (articles, videos, lifestyle tips) for medical conditions.

**Key Methods**:
- `getContentForCondition(conditionCode)`: Retrieves education content for a specific ICD-10 code
- `saveContent(content)`: Persists educational content to Hive
- `updateContent(conditionCode, content)`: Updates existing content

**Data Sources**: Combines local Hive storage with potential future API integration for updated educational resources.

**Usage**: Used by ConditionDetailScreen to display relevant educational materials.

#### notification_service.dart
**Purpose**: Manages local push notifications for medication reminders.

**Key Methods**:
- `initialize()`: Sets up notification channels and permissions
- `scheduleMedicationNotifications(medication)`: Schedules recurring notifications for a medication's times
- `scheduleAllMedications(medications)`: Schedules notifications for all medications
- `cancelMedicationNotifications(medicationId)`: Cancels all notifications for a specific medication

**Platform Support**: Uses flutter_local_notifications package with platform-specific configuration.

**Scheduling Logic**: Creates notifications for each scheduled time, handles PRN medications differently (no recurring notifications).

#### pdf_export_service.dart
**Purpose**: Platform-agnostic abstraction layer for exporting medication reports to PDF.

**Key Methods**:
- `generateMedicationsPdf(medications, conditions, profile)`: Creates PDF document with medication list, condition associations, and user info
- `exportAndShare(filePath, bytes, fileName)`: Platform-specific sharing/downloading logic

**Platform Implementations**: Uses conditional imports to load platform-specific implementations (mobile vs. web).

**PDF Content**: Includes user profile, medication list with dosages and schedules, condition associations, and export timestamp.

#### pdf_export_service_mobile.dart
**Purpose**: Mobile-specific PDF export implementation using file system.

**Key Methods**:
- `savePdfToFile(pdf, fileName)`: Saves PDF to device's application documents directory
- `sharePdf(filePath, bytes, fileName)`: Opens system share sheet for PDF

**Dependencies**: path_provider (file system access), share_plus (sharing), dart:io

**Platform**: iOS and Android only (not available on web).

#### pdf_export_service_web.dart
**Purpose**: Web-specific PDF export implementation using browser download.

**Key Methods**:
- `savePdfToFile(pdf, fileName)`: Triggers browser download of PDF using blob URL
- `sharePdf(filePath, bytes, fileName)`: No-op on web (download is immediate)

**Dependencies**: dart:html (browser APIs)

**Platform**: Web only (not available on mobile).

#### condition_report_service.dart
**Purpose**: Sends condition reports to backend for custom conditions and user feedback.

**Key Methods**:
- `reportCondition(conditionName, userId)`: Submits condition report to Firebase backend
- `validateConditionName(name)`: Validates condition name format

**Backend Integration**: Uses Firebase Cloud Firestore to store condition reports for future ICD-10 database updates.

**Usage**: Called from ReportConditionDialog when users add custom conditions not in the ICD-10 database.

#### feedback_service.dart
**Purpose**: Handles user feedback submission to backend.

**Key Methods**:
- `submitFeedback(feedback)`: Sends feedback to Firebase backend
- `getFeedback()`: Retrieves feedback for admin review (future feature)

**Backend Integration**: Stores feedback in Firebase Cloud Firestore for analysis and app improvement.

**Usage**: Used by FeedbackDialog to submit user feedback and bug reports.

---

### State Management (lib/core/state/)

Providers manage application state using Riverpod's NotifierProvider pattern. Each provider manages a Hive box and exposes CRUD operations.

#### conditions_provider.dart
**Purpose**: Manages the list of user's medical conditions with persistence.

**State Type**: `List<Disease>`

**Key Methods**:
- `addCondition(disease)`: Adds a new condition to Hive and updates state
- `removeCondition(disease)`: Removes condition from Hive and updates state
- `build()`: Initializes provider and loads conditions from Hive

**Hive Integration**: Opens and caches 'conditions' box, uses ICD-10 code as key.

**Usage**: Consumed by HealthScreen, DashboardScreen, and condition-related widgets.

#### medication_provider.dart
**Purpose**: Manages medications with advanced features like sorting, PRN dose tracking, and daily resets.

**State Type**: `List<Medication>`

**Key Methods**:
- `addMeds(medication)`: Adds medication and schedules notifications
- `updateMeds(medication)`: Updates medication and re-schedules notifications
- `deleteMeds(medication)`: Removes medication and cancels notifications
- `setSortOption(option)`: Changes sort order (alphabetical, by condition, by due time)
- `incrementDoseCount(medication)`: Increments PRN dose count with validation
- `decrementDoseCount(medication)`: Decrements PRN dose count
- `checkAndResetDailyCounts()`: Resets PRN dose counts at midnight

**Sorting Options**: Alphabetical, grouped by condition, or sorted by next due time.

**Special Logic**: Handles multi-condition medications by avoiding duplication when sorting, uses helper method `_applySorting()` to handle grouped view specially.

**Hive Integration**: Opens 'medications' and 'medication_settings' boxes, stores medications by UUID and sort preference.

#### profile_provider.dart
**Purpose**: Manages user profile data and gamification features (XP, levels, streaks).

**State Type**: `Profile`

**Key Methods**:
- `updateProfile(profile)`: Updates profile data in Hive
- `awardXp(amount)`: Awards XP points and updates level progress
- `getCurrentLevel(xp)`: Calculates current level from XP
- `getXpForNextLevel(level)`: Gets XP required for next level
- `shouldShowXpPopup()`: Determines if XP gain popup should be displayed
- `markPopupShown()`: Records that popup was shown to prevent duplicates
- `checkAndAwardDailyXp()`: Awards XP for daily medication adherence

**Default Creation**: Creates default profile with firstName="User" if none exists.

**Gamification**: Uses exponential XP curve for leveling, awards XP for medication adherence.

#### adherence_provider.dart
**Purpose**: Tracks medication adherence metrics and history.

**State Type**: `Map<String, dynamic>` containing adherence statistics

**Key Methods**:
- `logDose(medicationId, timestamp, status)`: Records a dose taken/missed/skipped
- `getAdherenceRate(days)`: Calculates adherence percentage over time period
- `getStreakDays()`: Gets current consecutive days of adherence
- `getMissedDoses(days)`: Gets list of missed doses in time period

**Storage**: Uses 'medication_logs' Hive box to persist dose logging data.

**Usage**: Consumed by AdherenceMetricsWidget and AdherenceHistoryWidget on dashboard.

---

### Utils (lib/core/utils/)

Utility modules provide helper functions used across the application.

#### condition_helper.dart
**Purpose**: Helper functions for working with Disease objects and display names.

**Key Functions**:
- `getDisplayName(disease)`: Returns commonName if available, otherwise returns name
- `getDisplayNames(conditionNames, conditions)`: Maps condition names to display names for a list
- `getDisplayNameByConditionName(conditionName, conditions)`: Finds and returns display name for a single condition

**Usage**: Used throughout the app to ensure consistent condition name display (preferring friendly commonName over technical ICD-10 name).

#### time_formatting_utils.dart
**Purpose**: Date and time formatting utilities for medication scheduling.

**Key Functions**:
- `parseTimeToMinutes(timeStr)`: Converts "HH:mm" string to minutes since midnight
- `parseTimeGroupToMinutes(groupStr)`: Parses time group labels back to minutes
- `getNextScheduledTime(scheduledTimes, currentTime)`: Determines next upcoming scheduled time
- `formatTimeForDisplay(minutes)`: Formats minutes since midnight to 12-hour AM/PM format

**Constants**: Defines `minutesPerHour` and `noonHour` for time calculations.

**Usage**: Used by MedicationSorter for sorting by due time, and by medication screens for displaying schedules.

#### pdf_formatting_utils.dart
**Purpose**: PDF document formatting utilities for consistent report generation.

**Key Functions**:
- `formatMedicationTable(medications)`: Creates formatted medication table for PDF
- `formatConditionSection(conditions)`: Formats condition list section
- `addHeaderFooter(page, title, pageNumber)`: Adds consistent headers/footers to PDF pages

**PDF Library**: Works with the `pdf` package's widget system.

**Usage**: Used by PdfExportService to generate well-formatted medication reports.

---

### Shared Widgets (lib/core/widgets/)

Reusable UI components used across multiple features.

#### empty_state_widget.dart
**Purpose**: Displays friendly empty state message with icon when lists are empty.

**Props**:
- `icon` (IconData): Icon to display (e.g., Icons.medication_outlined)
- `title` (String): Main empty state message
- `subtitle` (String?): Optional secondary message
- `action` (Widget?): Optional action widget (e.g., button)

**Design**: Centers content vertically and horizontally with consistent spacing and theming.

**Usage**: Used in HealthScreen (no conditions), MedicationsScreen (no medications), and search results (no matches).

#### pdf_export_button.dart
**Purpose**: Reusable button for exporting medication reports to PDF.

**Props**:
- `tooltip` (String): Tooltip text for accessibility

**Functionality**: Reads current medications, conditions, and profile from providers, generates PDF using PdfExportService, shows success/error snackbar.

**UI**: Renders as IconButton with PDF icon in app bar.

**Usage**: Used in MedicationsScreen app bar to allow quick PDF export.

---

## Features Modules

The `lib/features/` directory contains feature-specific code organized by user-facing functionality. Each feature is self-contained with its own screens, dialogs, widgets, and utilities.

### Dashboard Feature (lib/features/dashboard/)

The dashboard serves as the home screen, displaying an overview of conditions, medications, and adherence metrics.

#### dashboard_screen.dart
**Purpose**: Main dashboard screen displaying daily medication schedule and adherence overview.

**UI Components**:
- RotatingWelcomeMessage: Personalized greeting
- TodaysMedicationsWidget: List of medications due today
- AdherenceHistoryWidget: Visual adherence tracking
- Condition cards: Shows each condition with associated medications

**State Dependencies**: Reads from conditionsProvider and medicationProvider.

**User Workflow**: Users see their medication schedule, track doses, and view adherence at a glance. Primary entry point after app launch.

#### dialogs/dose_logging_dialog.dart
**Purpose**: Dialog for logging medication doses as taken, missed, or skipped.

**UI Elements**: Medication name, scheduled time, status buttons (Taken/Missed/Skipped), optional notes field.

**Actions**: Submits dose log to AdherenceProvider, awards XP if applicable, shows success confirmation.

**Trigger**: Opened when user taps on a medication in TodaysMedicationsWidget.

#### widgets/rotating_welcome_message.dart
**Purpose**: Displays rotating personalized welcome messages to engage users.

**Behavior**: Cycles through different greetings and motivational messages based on time of day and user's name from profile.

**Design**: Uses AnimatedSwitcher for smooth transitions between messages.

#### widgets/adherence_metrics_widget.dart
**Purpose**: Displays key adherence statistics (adherence rate, streak days, total doses).

**Metrics**:
- Adherence percentage (last 7/30 days)
- Current streak (consecutive days)
- Total doses taken vs. scheduled

**Data Source**: Reads from AdherenceProvider.

**Visual Design**: Uses color-coded indicators (green for good adherence, red for poor adherence).

#### widgets/adherence_history_widget.dart
**Purpose**: Visual chart showing medication adherence over time.

**Visualization**: Calendar-style view or line chart showing daily adherence over the past month.

**Interactivity**: Users can tap on days to see details of doses taken/missed.

**Data Source**: Reads from AdherenceProvider.

#### widgets/todays_medications_widget.dart
**Purpose**: Lists medications scheduled for today with take/log actions.

**Features**:
- Shows scheduled times
- Indicates if dose was taken (checkmark)
- Allows quick logging via tap
- Groups by time (morning, afternoon, evening)
- Shows PRN medications separately

**Actions**: Tapping a medication opens DoseLoggingDialog.

**Data Source**: Reads from medicationProvider, filters by today's scheduled times.

---

### Health Feature (lib/features/health/)

Manages user's medical conditions and provides educational resources.

#### health_screen.dart
**Purpose**: Main screen for browsing and managing medical conditions.

**View Modes**:
1. **My Conditions**: Shows user's added conditions with medication counts
2. **Browse All**: Shows all ICD-10 chronic conditions grouped by category

**Features**:
- Search bar filters conditions by code, name, or commonName
- Filter chips toggle between view modes
- Expandable category groups in browse mode
- Medication count badges on user's conditions
- Empty state with prompt to add conditions

**Navigation**: Tapping a condition navigates to ConditionDetailScreen.

**Data Sources**: Reads from conditionsProvider and medicationProvider, loads all conditions from ICDService.

#### condition_detail_screen.dart
**Purpose**: Detailed view of a single medical condition with educational resources.

**Sections**:
- Condition overview (name, description, ICD-10 code)
- Associated medications list
- Educational articles (ArticlesSection)
- Educational videos (VideoSection)
- Lifestyle tips (LifestyleTipsSection)

**Actions**: Add/remove condition, add medication for this condition.

**Data Source**: Takes Disease as parameter, reads education content from EducationService.

#### dialogs/add_custom_condition_dialog.dart
**Purpose**: Form for adding custom medical conditions not in ICD-10 database.

**Form Fields**:
- Condition name (required)
- Category selection
- Personal notes
- Description

**Validation**: Ensures name is not empty, generates unique custom code (CUSTOM-XXX).

**Post-Submit**: Shows ReportConditionDialog to optionally report to backend for future database inclusion.

**Result**: Returns Disease object to caller, which adds it to conditionsProvider.

#### dialogs/report_condition_dialog.dart
**Purpose**: Prompts user to report custom condition to backend for database improvement.

**UI**: Explains benefit of reporting (helps other users), optional submission.

**Submission**: Calls ConditionReportService to send condition name and optional user ID to Firebase.

**Privacy**: User ID is optional and only sent if provided.

#### widgets/condition_card.dart
**Purpose**: Displays a condition as a card with name, category, ICD-10 code, and medication count.

**Props**:
- `condition` (Disease): Condition to display
- `isAdded` (bool): Whether user has added this condition
- `medicationCount` (int): Number of associated medications
- `onTap` (VoidCallback): Tap handler (usually navigates to detail)
- `onToggle` (VoidCallback): Add/remove toggle handler
- `showToggle` (bool): Whether to show add/remove button

**Layout**: Title (commonName), colored category badge, ICD-10 code, medication count, add/remove button, navigation arrow.

**Usage**: Used in both "My Conditions" and "Browse All" views with different configurations.

#### widgets/articles_section.dart
**Purpose**: Displays list of educational articles for a condition.

**UI**: List of article cards with title, source, last updated date.

**Actions**: Tapping an article opens full content in a dialog or web view.

**Data Source**: Takes List<Article> as parameter from EducationContent.

#### widgets/video_section.dart
**Purpose**: Displays educational video resources.

**UI**: Grid or list of video thumbnails with title and duration.

**Actions**: Tapping opens video in external player or embedded web view.

**Data Source**: Takes List<Video> as parameter from EducationContent.

#### widgets/lifestyle_tips_section.dart
**Purpose**: Shows lifestyle recommendations and health tips.

**UI**: Bulleted list or card-based display of tips.

**Content**: General health advice, dietary recommendations, exercise suggestions specific to the condition.

**Data Source**: Takes List<String> tips from EducationContent.

---

### Medications Feature (lib/features/medications/)

Comprehensive medication management with scheduling, PRN support, and multiple sorting options.

#### medications_screen.dart
**Purpose**: Main screen for viewing and managing all medications.

**Features**:
- Search bar filters medications by name, dosage, or condition
- Sort options: Alphabetical, Grouped by Condition, Due Times
- Expandable medication tiles showing full details
- PRN dose counters with color indicators
- PDF export button
- Floating action button to add medication

**Sorting Behavior**:
- Alphabetical: Simple A-Z by medication name
- Grouped by Condition: Groups medications under each condition they treat (medications with multiple conditions appear under each)
- Due Times: Groups by next scheduled time with "Tomorrow" suffix for overnight medications

**Empty States**: Different messages for no medications vs. no search results.

**Navigation**: Add button opens MedicationAddDialog, edit button opens MedicationEditDialog.

#### dialogs/medication_add_dialog.dart
**Purpose**: Form dialog for adding a new medication.

**Form Structure**:
- Medication name (text input, required)
- Dosage (text input, required)
- Associated conditions (multi-select, required)
- Medication type toggle (Scheduled vs. PRN)
- Conditional sections based on type:
  - Scheduled: Time picker section with preset buttons
  - PRN: Max daily doses input

**Validation**: Uses MedicationValidator to ensure required fields are filled and values are valid.

**Submit**: Creates new Medication with UUID, adds to MedicationProvider (which also schedules notifications).

**Requires**: At least one condition must exist (shows error dialog if none).

#### dialogs/medication_edit_dialog.dart
**Purpose**: Form dialog for editing existing medication.

**Behavior**: Similar to MedicationAddDialog but pre-fills form with existing medication data.

**Additional Action**: Delete button to remove medication with confirmation.

**Update**: Calls updateMeds() on provider which updates Hive and re-schedules notifications.

#### dialogs/prn_setup_dialog.dart
**Purpose**: Specialized dialog for configuring PRN (as-needed) medications.

**Fields**:
- Max daily doses (number input, required)
- Optional notes about when to take

**Validation**: Ensures max doses is positive integer.

**Usage**: Can be opened from add/edit dialogs when user selects PRN medication type.

#### utils/medication_validator.dart
**Purpose**: Validation logic for medication forms.

**Validation Functions**:
- `validateName(name)`: Ensures name is not empty and reasonable length
- `validateDosage(dosage)`: Validates dosage format
- `validateScheduledTimes(times)`: Ensures at least one time for scheduled meds
- `validateMaxDoses(maxDoses)`: Validates PRN max doses is positive
- `validateConditions(conditions)`: Ensures at least one condition selected

**Error Messages**: Returns user-friendly error messages for each validation failure.

**Usage**: Called from medication add/edit dialogs before submission.

#### utils/medication_sorter.dart
**Purpose**: Sorting algorithms for medication list.

**Enum**: MedicationSortOption (alphabetical, groupedByCondition, dueTime)

**Sorting Methods**:
- `sort(medications, option)`: Main entry point, delegates to specific sorter
- `_sortAlphabetically(medications)`: Simple A-Z by name
- `_sortByConditionGroups(medications)`: Groups by condition, sorts within groups alphabetically (intentionally creates duplicates for multi-condition meds)
- `_sortByDueTime(medications)`: Sorts by next scheduled time, PRN meds go last

**Display Names**: `getDisplayName(option)` provides user-friendly labels.

**Note**: For grouped view, provider now skips sorter's grouping logic (returns alphabetical list), UI creates groups using MapEntry pattern to avoid double duplication.

#### widgets/medication_expansion_tile.dart
**Purpose**: Expandable list item displaying medication with details.

**Collapsed State**: Shows name, dosage, timing summary, dose count (PRN), conditions.

**Expanded State**: Full details including all scheduled times, notes, edit/delete actions.

**Props**:
- `medication` (Medication): Medication to display
- `conditionDisplayNames` (List<String>): Friendly condition names
- `timingSummary` (String): Summary like "3 times daily" or "2/6 doses taken"
- `doseColor` (Color?): Color indicator for PRN dose count
- `onEdit` (VoidCallback): Edit action handler
- `onDelete` (VoidCallback): Delete action handler

**PRN Features**: Shows dose counter with +/- buttons, color-codes based on proximity to max doses (green < 75%, orange 75-100%, red = max).

#### widgets/medication_detail_dialog.dart
**Purpose**: Read-only dialog showing full medication details.

**Content**: Displays all medication fields including name, dosage, conditions, schedule, PRN info, in a formatted view.

**Actions**: Close button, optional edit button.

**Usage**: Opened from medication list for quick reference without editing.

#### widgets/medication_form_content.dart
**Purpose**: Shared form UI components used in both add and edit dialogs.

**Components**: Text fields for name/dosage, condition selector, type toggle, conditional timing sections.

**Reusability**: Reduces code duplication between add and edit dialogs by extracting common form elements.

**Form State**: Managed by parent dialog using TextEditingControllers.

#### widgets/prn_section.dart
**Purpose**: UI components specific to PRN medication configuration.

**Elements**: Max doses input, dose counter display, explanatory text about PRN usage.

**Visibility**: Only shown when isPRN is true in medication forms.

#### widgets/time_picker_section.dart
**Purpose**: Interface for selecting medication times.

**Features**:
- Add time button (opens time picker)
- List of selected times with remove buttons
- Sort times chronologically
- Validate no duplicates

**UI**: Chip-based display of selected times with delete icons.

#### widgets/timing_preset_buttons.dart
**Purpose**: Quick preset buttons for common medication schedules.

**Presets**:
- Once daily (9:00 AM)
- Twice daily (9:00 AM, 9:00 PM)
- Three times daily (9:00 AM, 2:00 PM, 9:00 PM)
- Four times daily (8:00 AM, 12:00 PM, 4:00 PM, 8:00 PM)

**Behavior**: Tapping a preset replaces current times with the preset schedule.

**Customization**: Users can modify preset times or add custom times afterward.

---

### Profile Feature (lib/features/profile/)

Manages user profile, settings, and gamification features.

#### profile_screen.dart
**Purpose**: Main profile screen displaying user info, stats, and app settings.

**Sections**:
- User profile card (name, DOB, allergies)
- Gamification stats (XP, level, streak)
- Settings (notifications, theme, etc.)
- Feedback button
- About/version info

**Actions**: Edit profile, provide feedback, view privacy policy.

**Data Source**: Reads from ProfileProvider.

#### xp_gain_popup.dart
**Purpose**: Animated popup celebrating XP gains and level progress.

**Trigger**: Shown after user logs medication dose if XP was awarded and popup hasn't been shown yet today.

**UI**: Displays XP gained, current level, progress bar to next level, streak days.

**Animation**: Fade in with scale animation, celebratory design.

**Dismissal**: User taps "Awesome!" button, which marks popup as shown in ProfileProvider.

#### dialogs/feedback_dialog.dart
**Purpose**: Form for submitting user feedback to developers.

**Form Fields**:
- Category selection (Bug, Feature Request, General Feedback)
- Message (multiline text, required)
- Star rating (1-5, optional)
- Email for follow-up (optional)

**Validation**: Uses FeedbackValidator to ensure message is not empty and reasonable length.

**Submission**: Calls FeedbackService to send to Firebase backend, shows success message.

#### utils/feedback_validator.dart
**Purpose**: Validation logic for feedback form.

**Validation Functions**:
- `validateMessage(message)`: Ensures message is not empty and within length limits
- `validateEmail(email)`: Validates email format if provided
- `validateCategory(category)`: Ensures a category is selected

**Error Messages**: Returns user-friendly error messages.

**Usage**: Called from FeedbackDialog before submission.

---

## Architecture Patterns

### 1. Feature-Based Organization

**Pattern**: Code is organized by user-facing features rather than technical layers.

**Benefits**:
- Easy to locate code related to a specific feature
- Features can be developed and tested independently
- Clear boundaries between features reduce coupling

**Implementation**: Each feature has its own directory under `lib/features/` containing all screens, dialogs, widgets, and utilities for that feature.

### 2. Provider Pattern (Riverpod)

**Pattern**: State management using Riverpod's NotifierProvider pattern.

**Key Concepts**:
- Providers extend `Notifier<State>` and manage a specific piece of state
- State is immutable - updates create new state objects
- Providers handle both state and business logic (CRUD operations)
- UI components consume state using `ref.watch()` and call methods using `ref.read()`

**Benefits**:
- Reactive UI updates when state changes
- Testable business logic separate from UI
- Type-safe dependencies
- No need for setState() in widgets

### 3. Hive Persistence

**Pattern**: Local NoSQL database with generated type adapters.

**Implementation**:
- Models use `@HiveType` and `@HiveField` annotations
- Type adapters generated via `build_runner`
- Providers manage Hive box lifecycle (open, cache, close)
- Boxes used as key-value stores with model-specific keys

**Benefits**:
- Fast local persistence
- Offline-first architecture
- Type-safe serialization
- No SQL boilerplate

### 4. Conditional Imports (Platform-Specific Code)

**Pattern**: Different implementations for different platforms using conditional imports.

**Example**: PDF export service has separate implementations for mobile (dart:io) and web (dart:html).

**Syntax**:
```dart
import 'pdf_export_service_mobile.dart'
    if (dart.library.html) 'pdf_export_service_web.dart';
```

**Benefits**:
- Share common interface
- Platform-specific optimizations
- Avoid importing unavailable libraries

### 5. Separation of Concerns

**Pattern**: Clear boundaries between UI, business logic, and state management.

**Layers**:
- **UI Layer**: Screens, dialogs, widgets (read-only access to state)
- **Business Logic**: Services and utilities (pure functions, no state)
- **State Management**: Providers (orchestrate business logic and manage state)
- **Data Layer**: Hive models and adapters (persistence)

**Benefits**:
- Easier testing (can test business logic without UI)
- Reusable business logic across features
- Clear dependencies

---

## Development Guidelines

### Adding a New Feature

1. **Create feature directory** under `lib/features/your_feature/`
2. **Add main screen** as `your_feature_screen.dart`
3. **Create subdirectories**:
   - `dialogs/` for modal dialogs
   - `widgets/` for feature-specific widgets
   - `utils/` for feature-specific helpers
4. **Add to navigation** in `lib/main.dart` bottom navigation if needed

### Adding Shared Components

1. **Models**: Add to `lib/core/models/`, use Hive annotations, run `build_runner`
2. **Services**: Add to `lib/core/services/`, keep stateless
3. **Providers**: Add to `lib/core/state/`, extend `Notifier<State>`
4. **Widgets**: Add to `lib/core/widgets/` if used by multiple features
5. **Utils**: Add to `lib/core/utils/` if used by multiple features

### Working with Hive Models

1. **Create model class** with `@HiveType(typeId: N)` (use unique typeId)
2. **Add fields** with `@HiveField(N)` annotations
3. **Include** `part 'model_name.g.dart';` directive
4. **Run** `flutter pub run build_runner build` to generate adapter
5. **Register adapter** in `lib/main.dart`: `Hive.registerAdapter(ModelNameAdapter())`

### Provider Initialization Pattern

```dart
@override
List<Model> build() {
  _initializeAndLoad();  // Start async loading
  return [];             // Return empty state initially
}

Future<void> _initializeAndLoad() async {
  await _loadData();
}

Future<void> _loadData() async {
  final box = await _getBox();
  final data = box.values.cast<Model>().toList();
  if (data.isNotEmpty || state.isEmpty) {
    state = data;  // Update state when data loads
  }
}
```

### When to Use Core vs. Feature-Specific Code

**Use Core (`lib/core/`)**:
- Code used by multiple features
- Business logic not tied to a specific feature
- Data models shared across features
- Reusable UI components

**Use Feature-Specific (`lib/features/your_feature/`)**:
- Code only used by one feature
- Feature-specific business logic
- Feature-specific widgets
- Feature-specific utilities

### Best Practices

1. **Immutable State**: Always create new state objects, never mutate existing state
2. **Read from Hive**: When updating state in providers, always fetch from Hive to ensure data accuracy
3. **Conditional Imports**: Use for platform-specific code (mobile vs. web)
4. **Error Handling**: Show user-friendly error messages via SnackBars
5. **Validation**: Validate form inputs before submission using dedicated validator utilities
6. **Documentation**: Add doc comments to public APIs and complex business logic

---

## File Statistics

- **Total Source Files**: 57 Dart files (.dart)
- **Generated Files**: 6 Hive adapters (.g.dart)
- **Core Modules**: 6 subdirectories
- **Features**: 4 feature modules
- **Total Directories**: 21

---

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Project README](../README.md)
- [CLAUDE.md](../CLAUDE.md) - Project overview and development guide

---

*Last Updated*: December 2025
*Document Version*: 1.0
