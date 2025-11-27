# SmartPatient User Guide

**Version 1.0**
Last Updated: November 2025

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Dashboard](#dashboard)
4. [Health Tracking](#health-tracking)
5. [Medication Management](#medication-management)
6. [Profile & Settings](#profile--settings)
7. [Tips & Best Practices](#tips--best-practices)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

---

## Introduction

SmartPatient is a comprehensive health tracking application designed to help you manage chronic medical conditions and maintain medication adherence. The app provides an intuitive interface for tracking conditions using standardized ICD-10 codes, managing medication schedules, monitoring adherence, and accessing health information.

### Key Features

- **Condition Tracking**: Search and add chronic conditions using ICD-10 classification codes
- **Medication Management**: Schedule medications with customizable dosing times
- **Adherence Monitoring**: Track medication adherence with visual history and statistics
- **PRN Tracking**: Log as-needed (PRN) medications with dose counting
- **PDF Export**: Generate shareable medication reports for healthcare providers
- **Educational Resources**: Access condition-specific health information
- **Personal Profile**: Store health information and track adherence metrics

### Important Notes

- **Offline-First**: All data is stored locally on your device using secure storage
- **Privacy**: Your health data stays on your device - no cloud sync or external sharing
- **Disclaimer**: SmartPatient is a personal tracking tool and does not replace professional medical advice

---

## Getting Started

### First Launch

When you first open SmartPatient, you'll see the Dashboard with empty state messages prompting you to:

1. Add your first health condition
2. Set up your medications
3. Complete your profile

### Recommended Setup Flow

1. **Navigate to Health Tab** → Add your chronic conditions
2. **Go to Medications Tab** → Add medications for each condition
3. **Visit Profile Tab** → Complete your personal information
4. **Return to Dashboard** → View your daily medication checklist

### Navigation

SmartPatient uses a bottom navigation bar with four main sections:

- **Dashboard** (Home icon): Daily overview and medication checklist
- **Health** (Health & Safety icon): Manage your conditions
- **Medications** (Medication icon): Manage your medication list
- **Profile** (Person icon): Personal info and adherence statistics

---

## Dashboard

The Dashboard is your daily command center for medication tracking and health overview.

### Components

#### Welcome Message
- Displays rotating motivational messages
- Changes throughout the day to keep you engaged

#### Today's Medications
- Shows all scheduled medications for the current day
- Displays medication cards with:
  - Medication name and dosage
  - Associated condition(s)
  - Scheduled times for the day
  - Checkboxes to log each dose
- Color-coded status indicators:
  - **Green**: Dose taken on time
  - **Gray**: Not yet taken
  - **Yellow**: Approaching due time
  - **Red**: Overdue

#### Adherence History
- Visual calendar showing your medication adherence over the past 30 days
- Color-coded days:
  - **Green**: All medications taken (100% adherence)
  - **Yellow**: Partial adherence (some doses missed)
  - **Red**: No doses taken that day
  - **Gray**: No medications scheduled
- Displays overall adherence percentage

#### Conditions Overview
- Lists your tracked conditions
- Shows medications associated with each condition
- Quick summary of dosing frequency

### How to Use

#### Logging a Dose
1. Find the medication on Today's Medications widget
2. Locate the scheduled time slot
3. Tap the checkbox when you take the dose
4. The app records the timestamp and updates adherence metrics

#### Logging PRN Medications
1. Find the PRN medication card
2. Tap the "Log Dose" button
3. Dose counter increments (e.g., "1/6 doses taken today")
4. Color changes as you approach max daily doses:
   - Green: Under 75% of max
   - Orange: 75-99% of max
   - Red: At or over max doses

---

## Health Tracking

The Health screen allows you to manage your medical conditions using the standardized ICD-10 classification system.

### View Modes

#### My Conditions
- Shows only conditions you've added
- Search bar to filter your conditions
- Displays medication count for each condition
- Tap a condition to view details
- Swipe to remove a condition

#### Browse All
- Explore the complete database of chronic conditions
- Organized by medical category (expandable sections):
  - Circulatory System Diseases
  - Endocrine & Metabolic Disorders
  - Respiratory System Diseases
  - Digestive System Diseases
  - Musculoskeletal Disorders
  - Mental Health Conditions
  - And more...
- Toggle button to add/remove conditions
- Search across all conditions by:
  - ICD-10 code (e.g., "E11")
  - Medical name (e.g., "Type 2 diabetes mellitus")
  - Common name (e.g., "Diabetes")

### Adding a Condition

**From Browse All:**
1. Switch to "Browse All" view
2. Expand a category or use search
3. Find your condition
4. Tap the toggle button (+ icon)
5. Condition is added with a confirmation message

**Adding Custom Conditions:**
1. Search for a condition in "Browse All"
2. If not found, tap "Can't find your condition?"
3. Enter condition details:
   - Name (required)
   - Common name (optional)
   - Category (select from dropdown)
   - Description (optional)
4. Tap "Add Custom Condition"
5. Optionally report the condition to be added to the database

### Viewing Condition Details

Tap any condition to view:
- Full ICD-10 code
- Medical and common names
- Category classification
- Detailed description
- Related educational resources
- Associated medications

### Removing a Condition

1. Go to "My Conditions" view
2. Find the condition to remove
3. Tap the condition card
4. Tap "Remove Condition" button
5. **Note**: Medications linked to this condition will NOT be automatically deleted

---

## Medication Management

The Medications screen provides comprehensive tools for managing your medication regimen.

### Medication Types

#### Scheduled Medications
- Taken at specific times each day
- Examples: Blood pressure pills, daily vitamins
- Can have multiple doses per day (e.g., twice daily, three times daily)
- Each dose time can be customized

#### PRN (As-Needed) Medications
- Taken when needed, not on a schedule
- Examples: Pain relievers, rescue inhalers
- Includes max daily dose limit
- Tracks doses taken vs. maximum allowed

### Adding a Medication

1. Tap the **+** (floating action button)
2. **First time?** If no conditions exist, you'll be prompted to add a condition first
3. Fill in medication details:

   **Basic Information:**
   - **Medication Name** (required): e.g., "Metformin"
   - **Dosage** (required): e.g., "500mg"
   - **Associated Condition(s)** (required): Select one or more conditions

   **Medication Type:**
   - Choose **Scheduled** or **PRN**

   **For Scheduled Medications:**
   - Select how many times per day (1-6)
   - Set specific times for each dose
   - Use time picker for precision

   **For PRN Medications:**
   - Enter max daily doses (e.g., "6")
   - Optionally add minimum hours between doses

4. Tap "Add Medication"

### Editing a Medication

1. Find the medication in your list
2. Tap the medication card to expand details
3. Tap the **Edit** button (pencil icon)
4. Modify any field
5. Tap "Save Changes"

### Deleting a Medication

1. Expand the medication card
2. Tap the **Delete** button (trash icon)
3. Confirm deletion
4. **Note**: This action cannot be undone

### Sorting Medications

Tap the sort icon (top right) to choose:

- **By Name (A-Z)**: Alphabetical order
- **By Condition**: Grouped by associated condition
- **By Due Time**: Organized by next scheduled time
  - Shows upcoming doses first
  - Includes tomorrow's morning doses at the end
  - PRN medications appear last

### Searching Medications

1. Use the search bar at the top
2. Search by:
   - Medication name
   - Dosage amount
   - Condition name

### Medication Details View

Expand any medication card to see:
- Full medication information
- Associated condition(s)
- Complete schedule or PRN limits
- Dosing history (last 30 days)
- Adherence statistics for this medication
- Edit and delete options

### Exporting Medication Report

Generate a PDF report to share with healthcare providers:

1. Tap the **PDF export** icon (top right)
2. Review the generated report content:
   - Personal information (if entered in Profile)
   - Complete medication list with dosages and schedules
   - Adherence statistics
   - Condition list
3. Share via:
   - Email
   - Messaging apps
   - Save to files
   - Print

---

## Profile & Settings

The Profile screen stores your personal health information and displays adherence metrics.

### Personal Information

#### Editable Fields
- **First Name**
- **Last Name**
- **Date of Birth**
- **Allergies**: List any medication or substance allergies

#### Editing Your Profile

1. Tap the **Edit** button (pencil icon)
2. Update any fields
3. Tap **Save** to confirm or **Cancel** to discard changes

### Adherence Metrics

View your medication tracking performance:

- **Overall Adherence Percentage**: Based on last 30 days
- **Current Streak**: Consecutive days with 100% adherence
- **Doses Taken**: Total doses logged in the period
- **Doses Missed**: Scheduled doses not logged
- **Adherence Trend**: Visual graph showing daily adherence

### PDF Export from Profile

Generate a comprehensive health report:

1. Tap the **PDF export** icon (next to Edit button)
2. Report includes:
   - Personal information
   - Active conditions
   - Current medications
   - Adherence statistics
   - Medical history summary

### Feedback & Support

Submit feedback directly from the app:

1. Scroll to "Feedback & Support" section
2. Tap **Submit Feedback**
3. Choose feedback type:
   - Bug Report
   - Feature Request
   - General Feedback
4. Describe your feedback
5. Submit to help improve SmartPatient

### Future Features (Coming Soon)

The following features are in development:
- **Gamification System**: Earn XP and level up for consistent adherence
- **Achievements & Badges**: Unlock rewards for health milestones
- **Daily Streaks**: Visual streak tracking and rewards

---

## Tips & Best Practices

### Getting the Most from SmartPatient

#### Daily Routine
1. **Morning**: Check Dashboard for today's medication schedule
2. **As You Go**: Log doses immediately after taking them
3. **Evening**: Review adherence history and log any missed doses

#### Organization Tips
- **Use Clear Names**: Enter medication names exactly as on the bottle
- **Include Strength**: Always add dosage (e.g., "10mg" not just "Lisinopril")
- **Link to Conditions**: Associate each medication with the correct condition
- **Set Realistic Times**: Schedule doses at times you can consistently take them

#### Adherence Success
- **Set Reminders**: Use phone alarms alongside SmartPatient
- **Build Habits**: Take medications with daily activities (meals, bedtime)
- **Keep It Current**: Remove discontinued medications promptly
- **Review Weekly**: Check adherence trends every Sunday

#### Data Management
- **Regular Exports**: Generate PDF reports monthly for your records
- **Before Appointments**: Export and share reports with healthcare providers
- **Update Profile**: Keep allergy information current
- **Backup Important**: Since data is local-only, back up your device regularly

### Common Workflows

#### Adding a New Prescription
1. Add the condition (if new) in Health tab
2. Go to Medications tab and tap +
3. Enter medication name, dosage, and link to condition
4. Set schedule based on prescription instructions
5. Log first dose on Dashboard

#### Before a Doctor's Visit
1. Go to Profile → tap PDF export
2. Review the generated health summary
3. Share report via email or print
4. Bring to appointment for reference

#### Adjusting Medication Times
1. Medications tab → find medication
2. Tap Edit button
3. Update scheduled times
4. Save changes
5. New schedule applies starting tomorrow

---

## Troubleshooting

### Common Issues

#### "No conditions yet" message when adding medication
**Solution**: You must add at least one condition before adding medications
1. Go to Health tab
2. Switch to "Browse All"
3. Add a condition
4. Return to Medications tab to add medication

#### Medication not appearing on Dashboard
**Possible causes:**
- Medication has no scheduled times (check if it's PRN-only)
- Schedule is set for future date
- App needs to be refreshed (close and reopen)

**Solution**: Edit medication and verify schedule is set correctly

#### Search not finding my condition
**Solutions:**
1. Try different search terms (medical name vs. common name)
2. Search by ICD-10 code if known
3. Browse categories manually
4. Add as custom condition if truly not in database

#### Adherence percentage seems incorrect
**Check:**
- Are all current medications added to the app?
- Did you log doses from earlier in the 30-day window?
- Are there discontinued medications still active? (Delete them)
- Percentage is based on scheduled doses only (PRN doesn't affect it)

#### PDF export not working
**Try:**
1. Ensure you've granted file/storage permissions
2. Check device has sufficient storage space
3. Try exporting to a different location
4. Restart the app and try again

#### Lost my data
**Important**: SmartPatient stores data locally only
- Data is lost if app is uninstalled without backup
- Enable device backup/sync to preserve data
- Consider regular PDF exports as backup documentation

---

## FAQ

### General

**Q: Is my health data shared with anyone?**
A: No. SmartPatient stores all data locally on your device. Nothing is sent to external servers or shared without your explicit action (like exporting a PDF).

**Q: Can I use SmartPatient on multiple devices?**
A: Currently, no. The app is offline-only with no cloud sync. Data stays on the device where you enter it.

**Q: Is SmartPatient a replacement for medical advice?**
A: No. SmartPatient is a tracking tool only. Always consult healthcare professionals for medical decisions.

### Conditions

**Q: What are ICD-10 codes?**
A: ICD-10 (International Classification of Diseases, 10th Revision) is a standardized medical coding system used worldwide to classify health conditions.

**Q: Why can't I find my condition?**
A: The app focuses on chronic (long-term) conditions. Acute or temporary conditions may not be included. You can add any condition as a custom entry.

**Q: Can I add the same condition twice?**
A: No, each ICD-10 code can only be added once to avoid duplicates.

**Q: What happens to medications if I delete a condition?**
A: Medications remain in your list. You can reassign them to other conditions or delete them separately.

### Medications

**Q: What's the difference between scheduled and PRN?**
A: Scheduled medications are taken at specific times daily (like "8 AM and 8 PM"). PRN medications are taken as needed when symptoms occur (like "take 1 tablet for headache, max 6 per day").

**Q: Can a medication be linked to multiple conditions?**
A: Yes! When adding or editing, you can select multiple conditions. This is useful for medications that treat more than one condition.

**Q: How do I log a dose I took earlier?**
A: Currently, doses are logged with the current timestamp. If you missed logging in real-time, log it as soon as you remember - it will still count toward adherence.

**Q: What if I miss a dose?**
A: Simply leave that dose unchecked. The adherence tracker will reflect the miss. Do not double up on doses - consult your healthcare provider about missed doses.

### Adherence

**Q: How is adherence percentage calculated?**
A: (Doses Taken / Total Scheduled Doses) × 100, calculated over the last 30 days. Only scheduled medications count; PRN doses don't affect percentage.

**Q: Why did my adherence go down when I added a new medication?**
A: Adding a medication increases total scheduled doses. If you haven't logged all doses for the past days since adding it, the percentage may decrease temporarily.

**Q: Can I see adherence for individual medications?**
A: Yes! Expand any medication card to see its specific adherence statistics and dosing history.

### Data & Privacy

**Q: What happens if I uninstall the app?**
A: All data will be deleted. There's no cloud backup, so make sure to export important information before uninstalling.

**Q: Can I export my data besides PDF?**
A: Currently, only PDF export is available. This format is widely accepted by healthcare providers and preserves formatting.

**Q: How long is data stored?**
A: Indefinitely, until you delete medications/conditions or uninstall the app. Adherence history shows the last 30 days.

### Technical

**Q: Which platforms does SmartPatient support?**
A: SmartPatient is built with Flutter and supports:
- Android devices (phones and tablets)
- iOS devices (iPhone and iPad)
- Web browsers (limited features)

**Q: Does the app require internet?**
A: No. SmartPatient works completely offline. Internet is only needed for optional features like submitting feedback.

**Q: Will my data sync if I switch phones?**
A: No, there's no automatic sync. You'll need to manually transfer data or rebuild your medication list on the new device.

---

## Additional Resources

### For Healthcare Providers

SmartPatient generates PDF reports that include:
- Complete medication list with dosages and schedules
- Adherence statistics and trends
- Patient condition list
- Allergy information

These reports can help facilitate medication reviews and patient consultations.

### Medical Disclaimer

SmartPatient is provided for informational and tracking purposes only. It is not intended to:
- Replace professional medical advice, diagnosis, or treatment
- Provide medication interaction checking
- Validate dosages or schedules
- Serve as a clinical decision support tool

Always seek the advice of qualified health providers with questions regarding medical conditions and medications. Never disregard professional medical advice or delay seeking it because of information tracked in SmartPatient.

### Support & Feedback

**Found a bug?** **Have a suggestion?** **Need help?**

Use the in-app Feedback feature:
1. Profile tab → Feedback & Support
2. Submit Feedback
3. Choose appropriate category
4. Describe your issue or suggestion

Your feedback helps make SmartPatient better for everyone!

---

**SmartPatient** - Take control of your health, one dose at a time.

*User Guide Version 1.0 - November 2025*
