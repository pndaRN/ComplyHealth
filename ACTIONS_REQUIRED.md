# Actions Required After Renaming to ComplyHealth

This document outlines the manual steps required to complete the rename from SmartPatient to ComplyHealth.

## Summary of Code Changes Made

The following code changes have been automatically applied:
- Bundle identifier changed to `com.complyhealth.app` across all platforms
- App display name changed to "ComplyHealth" in iOS, Android, and web
- Package name changed in pubspec.yaml from `smartpatient` to `complyhealth`
- All UI strings referencing "SmartPatient" updated to "ComplyHealth"
- All documentation updated
- Codemagic CI/CD configuration updated

---

## 1. Apple Developer Portal Setup

### Register New App ID
1. Go to [Apple Developer Portal - Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click the **+** button to register a new identifier
3. Select **App IDs** → Continue
4. Select **App** → Continue
5. Enter:
   - **Description**: ComplyHealth
   - **Bundle ID**: `com.complyhealth.app` (Explicit)
6. Enable any capabilities your app needs (e.g., Push Notifications)
7. Click **Continue** → **Register**

### Create Certificates (if needed)
If you don't have existing iOS Distribution certificates:
1. Go to [Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click **+** to create new certificates
3. Create an **Apple Distribution** certificate for App Store builds

---

## 2. App Store Connect Setup

### Create New App
1. Go to [App Store Connect](https://appstoreconnect.apple.com/apps)
2. Click the **+** button → **New App**
3. Select:
   - **Platform**: iOS
   - **Name**: ComplyHealth
   - **Primary Language**: English (or your preference)
   - **Bundle ID**: Select `com.complyhealth.app`
   - **SKU**: complyhealth (or your preference)
   - **User Access**: Full Access (or your preference)
4. Click **Create**

### App Information (Required for TestFlight)
In App Store Connect, fill in:
- App name and subtitle
- Privacy Policy URL (required for health apps)
- App category (Medical or Health & Fitness)
- Content rights information

---

## 3. Firebase Project Setup

Since you're skipping Firebase file updates, you'll need to:

### Option A: Create New Firebase Project (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** → Name it "ComplyHealth"
3. Follow setup wizard

### Option B: Update Existing Project
1. Go to your existing Firebase project
2. Update app registrations with new bundle IDs

### Register iOS App
1. In Firebase Console → Project Settings → Your apps
2. Click **Add app** → iOS
3. Enter bundle ID: `com.complyhealth.app`
4. Download `GoogleService-Info.plist`
5. Place in `frontend/ios/Runner/`

### Register Android App
1. Click **Add app** → Android
2. Enter package name: `com.complyhealth.app`
3. Download `google-services.json`
4. Place in `frontend/android/app/`

### Regenerate Firebase Options
```bash
cd frontend

# Install FlutterFire CLI if not already installed
dart pub global activate flutterfire_cli

# Configure Firebase (regenerates firebase_options.dart)
flutterfire configure --project=YOUR_PROJECT_ID
```

---

## 4. Codemagic Configuration

### Update App Store Connect Integration
1. Go to [Codemagic](https://codemagic.io/apps)
2. Navigate to **Team Settings** → **Integrations** → **App Store Connect**
3. Verify your API key integration name matches what's in `codemagic.yaml`:
   ```yaml
   integrations:
     app_store_connect: codemagic  # Update this to match your integration name
   ```

### Update Environment Variables (if needed)
In Codemagic app settings, update these environment variables:
- `FIREBASE_IOS_APP_ID` - New Firebase iOS app ID
- `FIREBASE_SERVICE_ACCOUNT` - Firebase service account JSON (if using Firebase distribution)
- `APP_STORE_APPLE_ID` - New App Store Connect app ID (numeric)

---

## 5. Android Configuration (If Targeting Android)

### Update Android Package Name
The app label has been updated, but if you need to change the Android package name (applicationId), you'll need to:

1. Update `frontend/android/app/build.gradle`:
   ```gradle
   defaultConfig {
       applicationId "com.complyhealth.app"
       ...
   }
   ```

2. Move Kotlin/Java source files to new package path:
   ```
   android/app/src/main/kotlin/com/complyhealth/app/
   ```

3. Update `google-services.json` with new package name

---

## 6. Flutter Rebuild Commands

After completing the above steps, run:

```bash
cd frontend

# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Regenerate Hive type adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Verify the build works
flutter build ios --release --no-codesign
flutter build apk --release
```

---

## 7. Test Checklist

Before submitting to App Store:

- [ ] App launches with new name "ComplyHealth"
- [ ] Firebase Crashlytics reports to new project
- [ ] Push notifications work (if applicable)
- [ ] All screens show "ComplyHealth" instead of "SmartPatient"
- [ ] PDF exports show "ComplyHealth"
- [ ] Backup files are named `complyhealth_backup.json`
- [ ] About screen shows "ComplyHealth"
- [ ] Privacy policy references "ComplyHealth"

---

## 8. Repository Rename (Optional)

If you want to rename the GitHub repository:

1. Go to repository settings
2. Under "Repository name", change from `smartPatient` to `complyhealth`
3. Update any CI/CD references to the new repo URL
4. Update clone URLs in documentation

---

## Quick Reference

| Item | Old Value | New Value |
|------|-----------|-----------|
| Bundle ID (iOS) | com.example.smartpatient | com.complyhealth.app |
| Bundle ID (Android) | com.example.smartpatient | com.complyhealth.app |
| App Name | SmartPatient | ComplyHealth |
| Package Name (Dart) | smartpatient | complyhealth |
| Backup File | smartpatient_backup.json | complyhealth_backup.json |

---

## Support

If you encounter issues:
1. Check Codemagic build logs for signing errors
2. Verify bundle ID matches exactly in all configurations
3. Ensure Firebase apps are registered with correct bundle IDs
4. Check that provisioning profiles are created for the new bundle ID
