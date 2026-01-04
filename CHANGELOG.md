# Changelog

All notable changes to the ComplyHealth project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-01-04

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

## [1.1.0] - 2026-01-01

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
