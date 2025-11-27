# SmartPatient

A comprehensive cross-platform medical condition and medication tracker designed to help users manage chronic conditions and maintain medication adherence.

## Overview

SmartPatient is a mobile-first health tracking application that enables users to:
- Track chronic medical conditions using standardized ICD-10 codes
- Manage medication schedules with customizable dosing times
- Monitor medication adherence with visual tracking and statistics
- Log PRN (as-needed) medication doses
- Access educational resources about health conditions
- Export medication reports to PDF for healthcare providers

The app provides a clean, intuitive interface for daily health management with features like dose reminders, adherence history, and condition-specific medication grouping.

## Features

### Condition Tracking
- Search and add chronic conditions using ICD-10 classification codes
- Browse curated list of common chronic conditions
- View detailed condition information and educational resources
- Organize medications by associated condition

### Medication Management
- Add scheduled medications with customizable dosing times
- Support for multiple daily doses with individual timing
- PRN (as-needed) medication tracking with dose counting
- Visual medication cards with color-coded status indicators
- Medication detail views with complete dosing history

### Adherence Monitoring
- Daily medication checklist on dashboard
- Visual adherence history with color-coded completion status
- Adherence percentage tracking over 30-day periods
- Dose logging with timestamp tracking
- Export medication reports to shareable PDF format

### User Profile
- Personal health information management
- Adherence statistics and trends
- Profile customization options

## Tech Stack

- **Frontend**: Flutter (cross-platform mobile development)
  - State Management: Riverpod
  - Local Storage: Hive (NoSQL database)
  - UI: Material Design 3

- **Backend**: Go with Gin framework
  - Currently in early development (basic API skeleton)

- **Data**:
  - ICD-10 chronic condition database (JSON asset)
  - Local-first data persistence

## Current Limitations

### Offline-Only Operation
The app currently operates entirely offline with no cloud sync functionality. All data is stored locally on the device using Hive database. This means:
- Data is not backed up to the cloud
- Cannot sync across multiple devices
- Data will be lost if the app is uninstalled without backup
- No web dashboard or remote access to health data

### Manual Medication Entry
Medications must be manually entered by the user. Unlike some commercial health apps, SmartPatient does not include:
- Integration with medication databases (e.g., FDA, RxNorm)
- Automatic medication lookup by name or NDC code
- Pill identification features
- Medication interaction checking
- Dosage suggestions or validation

Users are responsible for entering accurate medication names, dosages, and schedules.

### Limited Condition Coverage
The condition tracking feature uses a curated subset of ICD-10 codes focused on chronic conditions. This means:
- Not all ICD-10 codes are available (focused on chronic/long-term conditions)
- Acute conditions and temporary illnesses may not be included
- The condition database is manually curated and may not include rare conditions
- No integration with electronic health records (EHR) systems

The current condition database emphasizes common chronic conditions like diabetes, hypertension, asthma, etc.

## Documentation

Comprehensive documentation is available in the [`docs/`](docs/) directory:

### For Users
- **[Quick Start Guide](docs/QUICK_START.md)** - Get started in 5 minutes
- **[User Guide](docs/USER_GUIDE.md)** - Complete guide to all features
- **[Visual Guide](docs/VISUAL_GUIDE.md)** - UI reference and screen layouts
- **[Documentation Index](docs/README.md)** - Navigate all documentation

### For Developers
- **[Development Guide](CLAUDE.md)** - Architecture and development workflow
- **[Features Reference](docs/FEATURES.md)** - Technical specifications

### Quick Links
- 🚀 [Getting Started](docs/QUICK_START.md#step-1-add-your-first-condition-2-minutes)
- 💊 [Adding Medications](docs/USER_GUIDE.md#medication-management)
- 📊 [Understanding Adherence](docs/FEATURES.md#adherence-tracking)
- ❓ [FAQ](docs/USER_GUIDE.md#faq)

## Contributing

This is a personal health management project. Contributions, issues, and feature requests are welcome.

## License

[Add your license information here]

## Disclaimer

SmartPatient is a personal health tracking tool and is not intended to replace professional medical advice, diagnosis, or treatment. Always consult with qualified healthcare providers regarding medical conditions and medication management.
