import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/models/profile.dart';
import 'core/models/disease.dart';
import 'core/models/medication.dart';
import 'core/models/medication_log.dart';
import 'core/models/education_content.dart';
import 'core/models/feedback.dart';
import 'core/models/notebook_entry.dart';
import 'core/services/notification_service.dart';
import 'core/services/encryption_migration_service.dart';
import 'core/state/profile_provider.dart';
import 'core/state/adherence_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/state/settings_provider.dart';
import 'features/health/health_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/medications/medications_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/xp_gain_popup.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(DiseaseAdapter());
  Hive.registerAdapter(MedicationAdapterCustom());
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(FeedbackAdapter());
  Hive.registerAdapter(DoseStatusAdapter());
  Hive.registerAdapter(MedicationLogAdapter());
  Hive.registerAdapter(EducationContentAdapter());
  Hive.registerAdapter(ArticleAdapter());
  Hive.registerAdapter(VideoAdapter());
  Hive.registerAdapter(NotebookEntryAdapter());

  // Initialize notification service
  await NotificationService().initialize();

  // Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up Crashlytics error handlers (not supported on web)
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const ProviderScope(child: ComplyHealthApp()));
}

class ComplyHealthApp extends ConsumerStatefulWidget {
  const ComplyHealthApp({super.key});

  @override
  ConsumerState<ComplyHealthApp> createState() => _ComplyHealthAppState();
}

class _ComplyHealthAppState extends ConsumerState<ComplyHealthApp> {
  int _index = 0;
  bool _showOnboarding = true;
  bool _isAppReady = false;

  StreamSubscription<String>? _notificationSubscription;
  int _dashboardRefreshKey = 0;

  List<Widget> get _screens => [
    DashboardScreen(key: ValueKey('dashboard_$_dashboardRefreshKey')),
    const HealthScreen(),
    const MedicationsScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavigationBarItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.health_and_safety),
      label: 'Health',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.medication),
      label: 'Medications',
    ),
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();

    _initializeApp();
    // Listen for notification taps to navigate to dashboard
    _notificationSubscription = NotificationService.onNotificationTap.listen((
      payload,
    ) {
      setState(() {
        _index = 0; // Navigate to dashboard
        _dashboardRefreshKey++; // Force dashboard to rebuild and refresh
      });
    });

    // Clear incorrectly auto-marked missed logs and check for actual missed doses
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(adherenceProvider.notifier).clearMissedLogs();
      await ref.read(adherenceProvider.notifier).checkAndMarkMissedDoses();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAndShowXpPopup(Profile profile) async {
    final profileNotifier = ref.read(profileProvider.notifier);

    if (!mounted) return;

    final shouldShow = profileNotifier.shouldShowXpPopup();
    if (shouldShow && profile.lastXpGained > 0) {
      final currentLevel = profileNotifier.getCurrentLevel(profile.xp);
      final nextLevel = currentLevel + 1;
      final xpForNextLevel = profileNotifier.getXpForNextLevel(currentLevel);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => XpGainPopup(
          xpGained: profile.lastXpGained,
          currentLevel: currentLevel,
          nextLevel: nextLevel,
          levelProgress: profile.levelProgress,
          currentXp: profile.xp,
          xpForNextLevel: xpForNextLevel,
          streak: profile.streak,
        ),
      );

      // Mark popup as shown
      await profileNotifier.markPopupShown();
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Perform the heavy migration here while the UI is already visible
      await EncryptionMigrationService.migrateAllBoxes();
    } catch (e) {
      print('Migration error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAppReady = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);

    // Listen to profile provider changes to show XP popup
    ref.listen(profileProvider, (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<Profile>) {
        // Use a post-frame callback to ensure the widget tree is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkAndShowXpPopup(next.value);
          }
        });
      }
    });

    // Determine if we should show onboarding
    final showOnboarding = _showOnboarding && !settings.hasCompletedOnboarding;

    // Determine theme based on selected theme type
    ThemeData getTheme() {
      final platformBrightness = MediaQuery.of(context).platformBrightness;
      return AppTheme.getTheme(
        themeState.themeType,
        platformBrightness: platformBrightness,
      );
    }

    return MaterialApp(
      title: 'ComplyHealth',
      theme: getTheme(),
      darkTheme: getTheme(),
      themeMode: themeState.themeMode,
      home: showOnboarding
          ? OnboardingScreen(
              onComplete: () {
                setState(() => _showOnboarding = false);
              },
            )
          : Scaffold(
              body: IndexStack(
                index: _index,
                children: _screens,
              ),

              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                items: _bottomNavigationBarItems,
              ),
            ),
    );
  }
}
