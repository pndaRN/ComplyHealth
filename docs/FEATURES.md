# ComplyHealth Feature Reference

Complete technical reference for all ComplyHealth features and functionality.

---

## Table of Contents

1. [Core Features](#core-features)
2. [Condition Management](#condition-management)
3. [Medication Management](#medication-management)
4. [Adherence Tracking](#adherence-tracking)
5. [Data Export](#data-export)
6. [User Profile](#user-profile)
7. [Search & Filtering](#search--filtering)
8. [Notifications](#notifications)
9. [Data Persistence](#data-persistence)
10. [Future Features](#future-features)

---

## Core Features

### Multi-Tab Navigation

**Implementation**: Bottom navigation bar with tab persistence

**Tabs:**
- Dashboard (Index 0)
- Health (Index 1)
- Medications (Index 2)
- Profile (Index 3)

**Behavior:**
- Selected tab persists during session
- Each tab maintains its own scroll state
- Switching tabs does not reload data unnecessarily

**Technical Details:**
- Widget: `BottomNavigationBar`
- State management: Local component state (`_index`)
- Screens rendered in `IndexedStack` for state preservation

---

## Condition Management

### ICD-10 Condition Database

**Data Source**: Static JSON asset (`assets/icd10_chronic.json`)

**Database Structure:**
```json
{
  "code": "E11",
  "name": "Type 2 diabetes mellitus",
  "commonName": "Type 2 Diabetes",
  "category": "Endocrine & Metabolic",
  "description": "Detailed medical description..."
}
```

**Total Conditions**: ~248 chronic conditions across 12+ categories

**Categories:**
- Circulatory System Diseases
- Endocrine & Metabolic Disorders
- Respiratory System Diseases
- Digestive System Diseases
- Musculoskeletal Disorders
- Mental & Behavioral Disorders
- Nervous System Diseases
- Genitourinary System Diseases
- Skin Diseases
- Eye & Ear Disorders
- Infectious Diseases
- Neoplasms (chronic management)

### Condition CRUD Operations

**Add Condition:**
- Source: Browse database or create custom condition
- Validation: No duplicate ICD-10 codes
- Storage: Hive box (`conditions`)
- Key: ICD-10 code

**View Conditions:**
- Two modes: "My Conditions" (user-added) and "Browse All" (full database)
- Sorting: By category in Browse All mode
- Search: Across code, name, and commonName fields

**Remove Condition:**
- Direct deletion from storage
- No cascade delete to medications (medications remain but show as linked to non-existent condition)
- Confirmation not required (can be re-added)

**Custom Conditions:**
- User-generated conditions not in ICD-10 database
- Uses custom code format: `CUSTOM-{UUID}`
- Optional reporting feature to suggest additions to database
- Same storage mechanism as standard conditions

### Condition Detail View

**Displays:**
- ICD-10 code
- Official medical name
- Common name
- Category classification
- Detailed description
- List of associated medications (if any)
- Educational resources (if available)

**Actions:**
- Add to My Conditions
- Remove from My Conditions
- View associated medications
- Access educational content

---

## Medication Management

### Medication Types

#### Scheduled Medications

**Characteristics:**
- Fixed daily schedule (1-6 times per day)
- Each dose has specific time
- Contributes to adherence percentage
- Dose logging with timestamp

**Use Cases:**
- Chronic disease management (blood pressure, diabetes, etc.)
- Daily vitamins and supplements
- Any medication taken at consistent times

**Schedule Options:**
- Once daily (QD)
- Twice daily (BID)
- Three times daily (TID)
- Four times daily (QID)
- Five times daily
- Six times daily

**Technical Implementation:**
- `scheduledTimes`: List<String> in "HH:mm" format (24-hour)
- `isPRN`: false
- Times stored in local timezone

#### PRN (Pro Re Nata / As-Needed) Medications

**Characteristics:**
- No fixed schedule
- Maximum daily dose limit
- Dose counter (resets daily)
- Optional minimum hours between doses
- Does NOT contribute to adherence percentage

**Use Cases:**
- Pain relievers (as needed for pain)
- Rescue inhalers (for asthma attacks)
- Anti-nausea medication
- Sleep aids

**Dose Tracking:**
- Current dose count displayed
- Color-coded warning system:
  - Green: 0-74% of max doses
  - Orange: 75-99% of max doses
  - Red: 100%+ of max doses
- Daily reset at midnight (local time)

**Technical Implementation:**
- `isPRN`: true
- `maxDailyDoses`: Integer
- `currentDoseCount`: Integer (resets daily)
- `scheduledTimes`: Empty list

### Medication CRUD Operations

**Create Medication:**

Required fields:
- `name`: String (medication name)
- `dosage`: String (e.g., "500mg", "10ml")
- `conditionNames`: List<String> (at least one condition)
- `isPRN`: Boolean
- For scheduled: `scheduledTimes` (1-6 times)
- For PRN: `maxDailyDoses` (integer > 0)

Optional fields:
- `notes`: String (user notes)

Validation:
- Name cannot be empty
- Dosage cannot be empty
- Must have at least one associated condition
- Scheduled must have at least one time
- PRN must have max doses > 0

**Read Medications:**
- Retrieved from Hive box (`medications`)
- Sorted by selected option (name, condition, due time)
- Filtered by search query if active

**Update Medication:**
- All fields editable
- Can change type (scheduled ↔ PRN) but data clears
- Changing condition reassigns medication
- Validation same as create

**Delete Medication:**
- Removes from Hive box
- Deletes all associated dose logs
- No confirmation dialog (immediate deletion)
- Cannot be undone

### Medication Sorting

**Sort Options:**

1. **By Name (A-Z)**
   - Alphabetical order
   - Case-insensitive
   - Default sort option

2. **By Condition**
   - Groups medications under condition headers
   - Medications with multiple conditions appear under first condition
   - Within group: alphabetical by name
   - Section headers show condition common name

3. **By Due Time**
   - Chronological order of next scheduled dose
   - Groups by time slot
   - Future times first, then "tomorrow" times
   - PRN medications at the end
   - No schedule medications at the end

**Technical Implementation:**
- Sorting applied in provider before state update
- Re-sort on: medication add/edit/delete, sort option change
- Sort option persists during session (not across restarts)

### Multi-Condition Association

**Feature**: One medication can treat multiple conditions

**Examples:**
- Aspirin: Heart disease + Pain management
- Prednisone: Multiple inflammatory conditions
- Metformin: Diabetes + PCOS

**Implementation:**
- `conditionNames`: List<String>
- UI shows all conditions in medication card subtitle
- Can be edited to add/remove conditions
- Searchable by any associated condition name

---

## Adherence Tracking

### Adherence Calculation

**Formula:**
```
Adherence % = (Doses Taken / Total Scheduled Doses) × 100
```

**Scope:**
- Last 30 days (rolling window)
- Scheduled medications only
- PRN medications excluded from calculation

**Dose States:**
- **Taken**: User logged the dose (checkbox checked)
- **Missed**: Scheduled dose not logged by end of day
- **Upcoming**: Scheduled for future time today
- **Overdue**: Past scheduled time but not logged today

### Adherence Visualization

#### Calendar Grid (Dashboard)

**Display:**
- 30-day grid layout
- Color-coded squares
- Days labeled (M, T, W, T, F, S, S)

**Color Legend:**
- 🟢 Green: 100% adherence (all doses taken)
- 🟡 Yellow: 50-99% adherence (some doses missed)
- 🔴 Red: 0-49% adherence (most/all doses missed)
- ⚪ Gray: No scheduled medications for that day

**Calculation per Day:**
```
Daily Adherence = Doses Taken That Day / Total Scheduled That Day × 100
```

#### Adherence Metrics (Profile)

**Displays:**
- Overall adherence percentage (30-day)
- Total doses taken vs. total scheduled
- Doses missed count
- Current streak (consecutive 100% days)
- Daily adherence trend chart

**Streak Logic:**
- Increments on 100% adherence days
- Resets to 0 on any day with <100% adherence
- Today's streak only counts after all doses logged

### Dose Logging

**Timestamp Recording:**
- Each dose log includes timestamp
- Format: ISO 8601 with timezone
- Used for adherence analysis and history

**Logging Methods:**

1. **Checkbox (Scheduled)**: Tap checkbox next to scheduled time
2. **Log Dose Button (PRN)**: Tap button to increment dose counter
3. **Medication Detail**: Log from expanded medication view

**Business Rules:**
- Cannot log future doses (except upcoming doses today)
- Can log past doses (within current day)
- Logging multiple doses for same time slot creates multiple records
- No limit on logs per medication per day

**Data Model:**
```dart
class MedicationLog {
  String medicationId;    // UUID of medication
  DateTime timestamp;     // When dose was logged
  String? scheduledTime;  // Original scheduled time (if applicable)
  DoseStatus status;      // taken, missed, skipped
}
```

---

## Data Export

### PDF Report Generation

**Report Types:**

1. **Medication Report** (from Medications screen)
   - Focus: Complete medication list
   - Includes: All medications with schedules and adherence

2. **Health Report** (from Profile screen)
   - Focus: Complete health summary
   - Includes: Profile info + conditions + medications + adherence metrics

**Report Sections:**

**Header:**
- "ComplyHealth Medication Report" or "ComplyHealth Health Report"
- Generation date and time
- Disclaimer text

**Patient Information:**
- Full name (if provided)
- Date of birth (if provided)
- Known allergies (if provided)

**Current Conditions:**
- List of all tracked conditions
- ICD-10 code for each
- Alphabetically sorted

**Current Medications:**
- Numbered list
- For each medication:
  - Name and dosage
  - Associated condition(s)
  - Schedule (times or PRN max doses)
  - Adherence percentage (last 30 days)

**Adherence Summary:**
- Overall adherence percentage
- Total doses taken vs. scheduled
- Current streak
- Date range for statistics

**Footer:**
- Medical disclaimer
- Note about data being self-reported

**Technical Implementation:**
- Library: `pdf` package (Flutter)
- Format: A4 page size
- Font: Standard PDF fonts (Helvetica)
- Margins: 1 inch all sides
- File naming: `smartpatient_report_YYYYMMDD.pdf`

**Sharing Options:**
- Platform share sheet
- Email attachment
- Save to device files
- Print (via system print dialog)

---

## User Profile

### Profile Data Model

```dart
class Profile {
  String firstName;
  String lastName;
  String dob;              // Date of birth (free text)
  String allergies;        // Comma-separated or free text
  int xp;                  // Experience points (gamification)
  int streak;              // Current adherence streak
  double levelProgress;    // Progress to next level (0.0-1.0)
  int lastXpGained;        // Last XP gain amount (for popup)
  bool showPopup;          // Whether to show XP popup
}
```

### Profile Features

**Personal Information:**
- Editable in-app
- Optional fields (can be left blank)
- No validation on format (flexible for international users)
- Included in PDF exports

**Edit Mode:**
- Toggle between view and edit modes
- Cancel button discards changes
- Save button persists to Hive storage
- Confirmation snackbar on save

**Privacy:**
- Data stored locally only
- Not transmitted anywhere
- User controls what to include in PDF exports

---

## Search & Filtering

### Condition Search

**Search Fields:**
- ICD-10 code (e.g., "E11", "I10")
- Official name (e.g., "Type 2 diabetes mellitus")
- Common name (e.g., "Diabetes", "High blood pressure")

**Search Behavior:**
- Real-time filtering (onChange)
- Case-insensitive
- Substring matching
- Search applies to both "My Conditions" and "Browse All"
- Clear button appears when query present

**Performance:**
- Client-side search (no API calls)
- Filters ~248 conditions in <10ms
- No debouncing needed for this dataset size

### Medication Search

**Search Fields:**
- Medication name
- Dosage
- Associated condition name(s)

**Search Behavior:**
- Real-time filtering
- Case-insensitive
- Substring matching
- Searches all conditions for multi-condition medications
- Works across all sort modes

**Search + Sort Interaction:**
- Search results maintain current sort order
- Changing sort re-applies to filtered results
- Clearing search restores full list with current sort

---

## Notifications

### Local Push Notifications

**Implementation**: `flutter_local_notifications` package

**Notification Types:**

1. **Medication Reminders**
   - Triggered at scheduled medication times
   - Shows: "Time to take [Medication Name]"
   - Action: Tap to open app to Dashboard
   - Frequency: Per scheduled dose time

2. **Daily Summary**
   - Triggered: Evening (8 PM default)
   - Shows: Adherence summary for the day
   - Content: "You took X of Y doses today"

**Notification Scheduling:**
- Created when medication added/updated
- Updated when medication edited
- Cancelled when medication deleted
- Re-scheduled daily for next occurrence

**Permissions:**
- Requested on first app launch
- Can be managed in device settings
- Graceful degradation if denied (app still functions)

**Platform-Specific:**
- **Android**: Uses notification channels
- **iOS**: Requires authorization, shows in notification center
- **Web**: Not supported (browser notifications optional future feature)

**Technical Details:**
- Notification IDs: Hash of medication UUID + time slot
- Persistence: Scheduled notifications survive app closure
- Timezone: Local device timezone
- Background Processing: Uses background fetch for reliability

---

## Data Persistence

### Storage Architecture

**Technology**: Hive (NoSQL, local-first database)

**Hive Boxes:**

1. **conditions** (Box<Disease>)
   - Key: ICD-10 code (String)
   - Value: Disease object
   - TypeAdapter: DiseaseAdapter

2. **medications** (Box<Medication>)
   - Key: Medication UUID (String)
   - Value: Medication object
   - TypeAdapter: MedicationAdapterCustom

3. **medication_logs** (Box<MedicationLog>)
   - Key: Auto-generated integer
   - Value: MedicationLog object
   - TypeAdapter: MedicationLogAdapter

4. **profile** (Box<Profile>)
   - Key: "user_profile" (single entry)
   - Value: Profile object
   - TypeAdapter: ProfileAdapter

5. **feedback** (Box<Feedback>)
   - Key: Auto-generated integer
   - Value: Feedback object
   - TypeAdapter: FeedbackAdapter

6. **education_content** (Box<EducationContent>)
   - Key: Content ID (String)
   - Value: EducationContent object
   - TypeAdapter: EducationContentAdapter

### Data Models

**Type IDs** (for Hive adapters):
- Disease: 0
- Medication: 1
- Profile: 2
- Feedback: 3
- DoseStatus: 4
- MedicationLog: 5
- EducationContent: 6
- Article: 7
- Video: 8

**Adapter Generation:**
- Uses `build_runner` for code generation
- Generated files: `*.g.dart`
- Run: `flutter pub run build_runner build`

### State Management

**Technology**: Riverpod (v3.x)

**Provider Pattern:**
```dart
class MedicationNotifier extends Notifier<List<Medication>> {
  @override
  List<Medication> build() {
    // Load from Hive and return initial state
  }

  // Async CRUD methods that update state
}

final medicationProvider = NotifierProvider<MedicationNotifier, List<Medication>>(
  () => MedicationNotifier(),
);
```

**Providers:**
- `conditionsProvider`: List<Disease>
- `medicationProvider`: List<Medication>
- `profileProvider`: Profile
- `educationProvider`: List<EducationContent>

**State Updates:**
- Immutable state pattern
- State recreated on each update: `state = [...state, newItem]`
- Riverpod handles change notification to UI
- Hive operations within provider methods

### Data Migration

**Current Version**: 1.0 (no migrations yet)

**Future Migration Strategy:**
- Hive supports schema versioning
- Migration scripts will handle version upgrades
- Backward compatibility where possible
- Export/import fallback for major changes

---

## Future Features

### Gamification System (In Development)

**XP (Experience Points):**
- Earn XP for logging doses consistently
- Bonus XP for maintaining streaks
- Daily login bonuses

**XP Awards:**
- Log all scheduled doses: +10 XP per day
- Maintain 7-day streak: +50 XP bonus
- Monthly 100% adherence: +200 XP bonus

**Leveling System:**
- Start at Level 1
- XP requirements increase per level
- Formula: `XP_needed = level * 100`
- Level cap: 50

**Level Benefits:**
- Unlock new dashboard themes
- Access to advanced statistics
- Custom achievement badges

**UI Elements:**
- Level badge on profile
- XP progress bar
- Level-up popup animations
- XP gain notifications

**Technical Status:**
- Backend logic: Implemented
- Data models: Complete
- UI: Hidden (commented out in Profile screen)
- Planned release: v1.1

### Achievements & Badges (Planned)

**Achievement Types:**
- First Dose Logged
- Week Warrior (7-day streak)
- Month Master (30-day 100% adherence)
- Medication Maven (10+ medications tracked)
- Condition Champion (5+ conditions managed)

**Badge Display:**
- Profile screen "Achievements" section
- Badge gallery with locked/unlocked states
- Progress indicators for incomplete achievements

**Technical Status:**
- Design: Complete
- Implementation: Not started
- Planned release: v1.2

### Cloud Sync (Under Consideration)

**Proposed Features:**
- Optional account creation
- Cloud backup of all data
- Multi-device synchronization
- Web dashboard access

**Challenges:**
- Privacy concerns (medical data)
- HIPAA compliance requirements
- Server infrastructure costs
- Conflict resolution for offline edits

**Status:**
- Research phase
- User demand assessment needed
- No timeline for release

### Medication Interaction Checking (Future)

**Proposed Features:**
- Check for drug-drug interactions
- Allergy cross-referencing
- Dosage validation

**Requirements:**
- Integration with medication database (RxNorm, FDA)
- Regular database updates
- Medical disclaimer enhancements

**Status:**
- Concept phase
- Requires medical expertise review
- Potential partnerships with medication databases

### Medication Reminders Enhancement (Roadmap)

**Proposed Additions:**
- Custom reminder sounds
- Snooze functionality
- Smart reminders (adapt to user behavior)
- Reminder history

**Status:**
- Basic notifications implemented
- Enhancements planned for v1.3

---

## Technical Specifications

### Supported Platforms

- **Android**: 5.0 (Lollipop) and above
- **iOS**: 12.0 and above
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)
  - Limited features (no notifications, local storage only)

### Dependencies

**Core:**
- Flutter SDK: 3.x
- Dart: 3.x

**Key Packages:**
- `flutter_riverpod`: ^2.4.0 (state management)
- `hive_flutter`: ^1.1.0 (local database)
- `hive`: ^2.2.3
- `flutter_local_notifications`: ^15.1.0 (notifications)
- `pdf`: ^3.10.0 (PDF generation)
- `share_plus`: ^7.2.0 (sharing functionality)

**Dev Dependencies:**
- `build_runner`: ^2.4.0 (code generation)
- `hive_generator`: ^2.0.0 (adapter generation)

### Performance Metrics

**App Size:**
- Android APK: ~15-20 MB
- iOS IPA: ~25-30 MB
- Web: ~2-3 MB initial load

**Database Limits:**
- Conditions: No practical limit (tested with 500+)
- Medications: No practical limit (tested with 100+)
- Medication logs: Auto-cleanup after 90 days recommended
- Profile: Single entry

**Search Performance:**
- Condition search: <10ms for 248 entries
- Medication search: <5ms for 50 entries
- Real-time filtering: No noticeable lag

---

## API Reference (Internal)

### ICDService

**Static Methods:**

```dart
// Load all conditions from JSON asset
Future<List<Disease>> loadAll()

// Search conditions by query
Future<List<Disease>> search(String query)

// Get condition by code
Future<Disease?> getByCode(String code)
```

### ConditionHelper

**Static Methods:**

```dart
// Get display name (common name or fallback to medical name)
String getDisplayName(Disease condition)

// Get display name by condition name
String getDisplayNameByConditionName({
  required String conditionName,
  required List<Disease> conditions,
})

// Get display names for list of condition names
List<String> getDisplayNames({
  required List<String> conditionNames,
  required List<Disease> conditions,
})
```

### MedicationSorter

**Static Methods:**

```dart
// Sort medications by selected option
List<Medication> sort(
  List<Medication> medications,
  MedicationSortOption option,
)

// Get display name for sort option
String getDisplayName(MedicationSortOption option)
```

**Sort Options:**
```dart
enum MedicationSortOption {
  name,
  groupedByCondition,
  dueTime,
}
```

### NotificationService

**Methods:**

```dart
// Initialize notification service
Future<void> initialize()

// Schedule medication reminder
Future<void> scheduleMedicationReminder(Medication medication)

// Cancel medication reminders
Future<void> cancelMedicationReminders(String medicationId)

// Cancel all notifications
Future<void> cancelAllNotifications()
```

---

## Error Handling

### Data Validation Errors

**Medication Validation:**
- Empty name → "Medication name is required"
- Empty dosage → "Dosage is required"
- No conditions selected → "Select at least one condition"
- Scheduled with no times → "Add at least one scheduled time"
- PRN with no max doses → "Max daily doses is required"

**Condition Validation:**
- Duplicate ICD-10 code → "Condition already added"
- Custom condition without name → "Condition name is required"

### Storage Errors

**Hive Errors:**
- Box not opened → Auto-open on first access
- Corrupted data → Graceful degradation, rebuild from defaults
- Storage full → Show user error, suggest cleanup

**Handling:**
- Try-catch around all Hive operations
- User-friendly error messages in SnackBars
- Logging to console for debugging

### Platform Errors

**Notification Errors:**
- Permission denied → Disable notifications, show info message
- Scheduling failed → Log error, app continues without notifications

**PDF Export Errors:**
- Permission denied → Request permission, retry
- Storage full → User error message
- Share failed → Offer alternative export methods

---

## Security & Privacy

### Data Security

**Local Storage:**
- Hive database encrypted by device-level encryption
- No custom encryption (relies on OS security)
- Data stored in app's private directory

**No Network Transmission:**
- All data stays on device
- No analytics or tracking
- No cloud sync (yet)

### Privacy Considerations

**Personal Information:**
- All fields optional
- No email or account required
- No identifiable information collected

**Medical Data:**
- Stays on device
- User controls PDF export contents
- No third-party sharing

**Permissions Required:**
- Storage (for PDF export)
- Notifications (for medication reminders)
- No camera, microphone, location, or contacts

---

## Accessibility Features

### Screen Reader Support

- All interactive elements labeled
- Semantic labels for icons
- Proper heading hierarchy
- Form field descriptions

### Visual Accessibility

- High contrast mode compatible
- Color blindness friendly (not color-only indicators)
- Scalable text (respects device text size settings)
- Touch target sizes: minimum 48x48 dp

### Keyboard Navigation

- Tab order logical and consistent
- Enter/Return activates buttons
- Escape closes dialogs
- Arrow keys for list navigation (where applicable)

---

*Feature Reference Version 1.0 - November 2025*

*For user-focused documentation, see [User Guide](USER_GUIDE.md), [Quick Start Guide](QUICK_START.md), and [Visual Guide](VISUAL_GUIDE.md).*
