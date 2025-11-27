# SmartPatient Visual Guide

This document provides descriptions of the app's key screens and UI elements to help users understand the visual interface. Screenshots should be taken from the actual application to accompany this guide.

---

## App Navigation Overview

### Bottom Navigation Bar

The app uses a bottom navigation bar with four tabs:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│              [Current Screen Content]              │
│                                                     │
└─────────────────────────────────────────────────────┘
┌─────────┬──────────┬──────────────┬─────────────────┐
│Dashboard│  Health  │ Medications  │    Profile      │
│   🏠    │    🏥    │      💊      │       👤        │
└─────────┴──────────┴──────────────┴─────────────────┘
```

- **Dashboard**: Daily medication overview and adherence tracking
- **Health**: Condition management and browsing
- **Medications**: Medication list and management
- **Profile**: Personal information and statistics

---

## Screen-by-Screen Visual Guide

### 1. Dashboard Screen

**Top Section: Welcome Message**
- Displays rotating motivational message
- Examples: "Welcome back!", "Stay consistent!", "Great job tracking!"
- Clean, centered text on colored background

**Today's Medications Widget**
- Card-based layout
- Each medication shows:
  - Medication name (bold, large text)
  - Dosage amount (below name)
  - Associated condition (smaller text, gray)
  - Scheduled times with checkboxes
  - Status indicators (green/yellow/red dots)

**Visual Example:**
```
┌────────────────────────────────────────┐
│ 📋 Today's Medications                 │
├────────────────────────────────────────┤
│ ┌────────────────────────────────────┐ │
│ │ Metformin - 500mg               ✓  │ │
│ │ Type 2 Diabetes Mellitus           │ │
│ │ ⏰ 8:00 AM  ☐   8:00 PM  ☐         │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ Lisinopril - 10mg               ✓  │ │
│ │ Hypertension                       │ │
│ │ ⏰ 9:00 AM  ☑                      │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**Adherence History Widget**
- Calendar-style grid
- Color-coded squares for each day
- Legend showing color meanings
- Overall percentage displayed

**Visual Layout:**
```
┌────────────────────────────────────────┐
│ 📊 Adherence History - Last 30 Days   │
│                                        │
│  M  T  W  T  F  S  S                  │
│ [🟢][🟢][🟢][🟡][🟢][🟢][🟢]            │
│ [🟢][🔴][🟢][🟢][🟢][🟢][🟡]            │
│ [🟢][🟢][🟢][🟢][🟢][⚪][⚪]            │
│                                        │
│ Overall Adherence: 87%                 │
│                                        │
│ 🟢 Complete  🟡 Partial  🔴 Missed     │
└────────────────────────────────────────┘
```

**Conditions Overview**
- List of tracked conditions
- Each showing associated medications
- Simple card layout

---

### 2. Health Screen

**Top Navigation**
- App bar with "Health" title
- Filter chips below: "My Conditions" and "Browse All"
- Search bar with magnifying glass icon

**My Conditions View**
```
┌────────────────────────────────────────┐
│ Health                       ⋮         │
├────────────────────────────────────────┤
│ [My Conditions (3)]  [ Browse All ]    │
│                                        │
│ 🔍 Search conditions...                │
├────────────────────────────────────────┤
│ ┌────────────────────────────────────┐ │
│ │ Type 2 Diabetes Mellitus       →  │ │
│ │ E11                                │ │
│ │ 2 medications                      │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ Essential Hypertension         →  │ │
│ │ I10                                │ │
│ │ 1 medication                       │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**Browse All View**
- Expandable category sections
- Toggle buttons to add/remove conditions
- Organized by medical category

```
┌────────────────────────────────────────┐
│ [ My Conditions ]  [Browse All (248)]  │
│                                        │
│ 🔍 Search conditions...                │
├────────────────────────────────────────┤
│ ▼ Endocrine & Metabolic (24)          │
│   ┌──────────────────────────────────┐ │
│   │ Type 2 Diabetes Mellitus    [✓] │ │
│   │ E11 - Diabetes                   │ │
│   └──────────────────────────────────┘ │
│   ┌──────────────────────────────────┐ │
│   │ Hypothyroidism              [+] │ │
│   │ E03 - Underactive thyroid        │ │
│   └──────────────────────────────────┘ │
│                                        │
│ ▶ Circulatory System (32)             │
│ ▶ Respiratory System (18)             │
└────────────────────────────────────────┘
```

**Condition Detail Screen**
- Full condition name and ICD-10 code
- Category badge
- Detailed description
- Educational resources
- List of associated medications
- Add/Remove button

---

### 3. Medications Screen

**Top Bar**
- Title "Medications"
- Search bar
- Sort icon (upper right)
- PDF export icon

**Medication List**
- Expandable cards for each medication
- Color-coded status indicators for PRN medications

```
┌────────────────────────────────────────┐
│ Medications          📄 ⋮              │
├────────────────────────────────────────┤
│ 🔍 Search medications...               │
├────────────────────────────────────────┤
│ ▼ Metformin - 500mg                   │
│   Type 2 Diabetes Mellitus             │
│   Twice daily: 8:00 AM, 8:00 PM        │
│                                        │
│   📅 Scheduled Times:                  │
│   • 8:00 AM                            │
│   • 8:00 PM                            │
│                                        │
│   📊 Adherence: 92% (last 30 days)    │
│                                        │
│   [Edit] [Delete]                      │
│                                        │
│ ▶ Lisinopril - 10mg                   │
│   Hypertension                         │
│   Once daily                           │
│                                        │
│ ▶ Ibuprofen - 200mg              🟢   │
│   Arthritis (PRN)                      │
│   1/6 doses taken today                │
└────────────────────────────────────────┘
                                    [+]
```

**Add Medication Dialog**
```
┌────────────────────────────────────────┐
│ Add Medication                    ✕   │
├────────────────────────────────────────┤
│ Medication Name *                      │
│ ┌────────────────────────────────────┐ │
│ │ Metformin                          │ │
│ └────────────────────────────────────┘ │
│                                        │
│ Dosage *                               │
│ ┌────────────────────────────────────┐ │
│ │ 500mg                              │ │
│ └────────────────────────────────────┘ │
│                                        │
│ Associated Condition(s) *              │
│ ┌────────────────────────────────────┐ │
│ │ ▼ Select condition(s)              │ │
│ │ ☑ Type 2 Diabetes Mellitus         │ │
│ │ ☐ Hypertension                     │ │
│ └────────────────────────────────────┘ │
│                                        │
│ Medication Type *                      │
│ ⚪ Scheduled   ⚫ PRN (As-needed)      │
│                                        │
│ Times per day: 2                       │
│ ┌──────────────┬──────────────────┐   │
│ │ 8:00 AM      │ 8:00 PM          │   │
│ └──────────────┴──────────────────┘   │
│                                        │
│        [Cancel]  [Add Medication]      │
└────────────────────────────────────────┘
```

**Sort Options Menu**
```
┌──────────────────────────┐
│ Sort by:                 │
├──────────────────────────┤
│ ✓ Name (A-Z)            │
│   Condition              │
│   Due Time               │
└──────────────────────────┘
```

---

### 4. Profile Screen

**Personal Information Card**
```
┌────────────────────────────────────────┐
│ 👤 Personal Information     📄 ✏️      │
├────────────────────────────────────────┤
│ 🎫 Full Name                           │
│ ┌────────────────────────────────────┐ │
│ │ John Doe                           │ │
│ └────────────────────────────────────┘ │
│                                        │
│ 🎂 Date of Birth                       │
│ ┌────────────────────────────────────┐ │
│ │ 01/15/1980                         │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ⚠️ Allergies                           │
│ ┌────────────────────────────────────┐ │
│ │ Penicillin, Sulfa drugs            │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**Adherence Metrics Card**
```
┌────────────────────────────────────────┐
│ 📊 Your Adherence Metrics              │
├────────────────────────────────────────┤
│ Last 30 Days                           │
│                                        │
│ Overall Adherence                      │
│ ┌────────────────────────────────────┐ │
│ │ ████████████████░░░░░░░░  87%      │ │
│ └────────────────────────────────────┘ │
│                                        │
│ 🎯 Doses Taken:    156 / 180          │
│ ⏭️  Doses Missed:   24                 │
│ 🔥 Current Streak:  5 days            │
│                                        │
│ Daily Adherence Trend                  │
│ [Line chart showing adherence %]       │
│                                        │
└────────────────────────────────────────┘
```

**Feedback & Support Card**
```
┌────────────────────────────────────────┐
│ 💬 Feedback & Support                  │
├────────────────────────────────────────┤
│ We value your feedback! Help us        │
│ improve SmartPatient by sharing your   │
│ thoughts, reporting bugs, or           │
│ requesting features.                   │
│                                        │
│        [📝 Submit Feedback]            │
└────────────────────────────────────────┘
```

---

## Color Scheme & Visual Elements

### Primary Colors
- **Blue (#2196F3)**: Primary action color, app bar, buttons
- **Green (#4CAF50)**: Success states, completed doses, full adherence
- **Yellow (#FFC107)**: Warning states, partial adherence
- **Red (#F44336)**: Error states, missed doses, overdue
- **Gray (#9E9E9E)**: Inactive states, disabled elements

### Status Indicators

**Dose Status:**
- ✅ Green checkmark: Dose taken
- ⭕ Gray circle: Dose not taken yet
- 🔴 Red dot: Dose overdue
- 🟡 Yellow dot: Approaching due time

**Adherence Colors:**
- 🟢 Green: 100% adherence
- 🟡 Yellow: 50-99% adherence
- 🔴 Red: 0-49% adherence
- ⚪ Gray: No data / no medications

**PRN Dose Count Colors:**
- 🟢 Green: 0-74% of max doses
- 🟠 Orange: 75-99% of max doses
- 🔴 Red: 100%+ of max doses (at or over limit)

---

## UI Patterns

### Cards
- Rounded corners (12px radius)
- Subtle shadow for depth
- White background
- Padding for content breathing room

### Buttons
- **Primary (Filled)**: Blue background, white text
- **Secondary (Outlined)**: Blue border, blue text
- **Text**: No background, blue text
- **Floating Action Button**: Circular, blue, bottom right

### Icons
- Material Design icon set
- Consistent sizing (20-24px standard)
- Colored to match context

### Typography
- **Headlines**: Bold, larger size
- **Body**: Regular weight, readable size
- **Labels**: Smaller, gray color for secondary info

---

## Responsive Design

### Phone Layout (Portrait)
- Single column layout
- Full-width cards
- Bottom navigation always visible
- Scrollable content areas

### Tablet Layout (Landscape)
- Two-column layouts where appropriate
- Wider cards with more horizontal space
- Side navigation option (future feature)

---

## Accessibility Features

### Visual Accessibility
- High contrast text
- Color not sole indicator (uses icons + text)
- Large touch targets (minimum 48x48px)
- Clear visual hierarchy

### Text Accessibility
- Scalable text sizes
- Clear font (Roboto)
- Adequate line spacing
- Left-aligned text for readability

---

## Animation & Transitions

### Subtle Animations
- Smooth transitions between screens (300ms)
- Card expansion/collapse with animation
- Button press feedback (ripple effect)
- Progress bar smooth filling

### Interactive Feedback
- Checkbox check animation
- Snackbar slide-up for confirmations
- Dialog fade-in/out
- List item swipe gestures

---

## Empty States

### Friendly Empty State Messages

**Dashboard (No Medications):**
```
┌────────────────────────────────────────┐
│                                        │
│            💊                          │
│                                        │
│    No medications tracked yet          │
│                                        │
│ Add a condition to get started!        │
│                                        │
└────────────────────────────────────────┘
```

**Health (No Conditions):**
```
┌────────────────────────────────────────┐
│                                        │
│            🏥                          │
│                                        │
│      No conditions yet                 │
│                                        │
│ Tap "Browse All" to add your first     │
│           condition                    │
│                                        │
└────────────────────────────────────────┘
```

**Search (No Results):**
```
┌────────────────────────────────────────┐
│                                        │
│            🔍                          │
│                                        │
│    No medications found                │
│                                        │
│  Try a different search term           │
│                                        │
└────────────────────────────────────────┘
```

---

## PDF Export Preview

### Medication Report Layout
```
┌────────────────────────────────────────┐
│ SMARTPATIENT MEDICATION REPORT         │
│ Generated: November 27, 2025           │
├────────────────────────────────────────┤
│ PATIENT INFORMATION                    │
│ Name: John Doe                         │
│ DOB: 01/15/1980                        │
│ Allergies: Penicillin, Sulfa drugs     │
├────────────────────────────────────────┤
│ CURRENT CONDITIONS                     │
│ • Type 2 Diabetes Mellitus (E11)       │
│ • Essential Hypertension (I10)         │
├────────────────────────────────────────┤
│ CURRENT MEDICATIONS                    │
│                                        │
│ 1. Metformin 500mg                     │
│    Condition: Type 2 Diabetes          │
│    Schedule: 8:00 AM, 8:00 PM          │
│    Adherence: 92% (last 30 days)       │
│                                        │
│ 2. Lisinopril 10mg                     │
│    Condition: Hypertension             │
│    Schedule: 9:00 AM                   │
│    Adherence: 95% (last 30 days)       │
├────────────────────────────────────────┤
│ ADHERENCE SUMMARY                      │
│ Overall Adherence: 87%                 │
│ Doses Taken: 156 / 180                 │
│ Current Streak: 5 days                 │
└────────────────────────────────────────┘
```

---

## Notes for Screenshot Creation

When creating screenshots for documentation, capture:

1. **Dashboard - Full View**: Showing welcome message, today's medications, and adherence history
2. **Health - My Conditions**: Showing 2-3 conditions with medication counts
3. **Health - Browse All**: Showing expanded category with conditions
4. **Health - Condition Detail**: Full detail view of a condition
5. **Medications - List View**: Showing mix of scheduled and PRN medications
6. **Medications - Add Dialog**: Complete form with all fields visible
7. **Medications - Expanded Card**: Showing full medication details
8. **Profile - View Mode**: Showing personal info and metrics
9. **Profile - Edit Mode**: Showing editable fields
10. **Empty States**: One example for each main screen
11. **PDF Export**: Generated PDF on device
12. **Search Examples**: Active search with results

### Screenshot Best Practices
- Use consistent test data across screenshots
- Capture at standard phone resolution (1080x2400 or similar)
- Include status bar and navigation bar for context
- Use light mode for clarity
- Avoid sensitive personal information
- Annotate screenshots with arrows/highlights where helpful

---

*This visual guide complements the [User Guide](USER_GUIDE.md) and [Quick Start Guide](QUICK_START.md). For complete documentation, refer to all three guides together.*
