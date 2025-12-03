import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartpatient/core/models/profile.dart';
import 'core/models/disease.dart';
import 'core/models/medication.dart';
import 'core/models/medication_log.dart';
import 'core/models/education_content.dart';
import 'core/models/feedback.dart';
import 'core/services/notification_service.dart';
import 'core/state/profile_provider.dart';
import 'core/state/conditions_provider.dart';
import 'core/state/medication_provider.dart';
import 'features/health/health_screen.dart';
import 'features/medications/medications_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/xp_gain_popup.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Initialize notification service
  await NotificationService().initialize();

  // Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create ProviderScope to initialize all providers early
  final container = ProviderContainer();

  // Initialize providers to ensure data is loaded before UI appears
  container.read(profileProvider);
  container.read(conditionsProvider);
  container.read(medicationProvider);

  // Give providers time to load from Hive
  await Future.delayed(const Duration(milliseconds: 200));

  runApp(UncontrolledProviderScope(
    container: container,
    child: const SmartPatientApp(),
  ));
}

class SmartPatientApp extends ConsumerStatefulWidget {
  const SmartPatientApp({super.key});

  @override
  ConsumerState<SmartPatientApp> createState() => _SmartPatientAppState();
}

class _SmartPatientAppState extends ConsumerState<SmartPatientApp> {
  int _index = 0;
  bool _hasCheckedPopup = false;

  final List<Widget> _screens = [
    DashboardScreen(),
    HealthScreen(),
    MedicationsScreen(),
    ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavigationBarItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(
      icon: Icon(Icons.health_and_safety),
      label: 'Health',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Medications'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    // Check and show XP popup after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowXpPopup();
    });
  }

  Future<void> _checkAndShowXpPopup() async {
    if (_hasCheckedPopup) return;
    _hasCheckedPopup = true;

    final profileNotifier = ref.read(profileProvider.notifier);
    final profile = ref.read(profileProvider);

    // Wait a bit for profile to load
    await Future.delayed(const Duration(milliseconds: 500));

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPatient',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        body: _screens[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: Colors.white, // Explicit background
          selectedItemColor: Colors.blue, // Selected icon color
          unselectedItemColor: Colors.grey,
          items: _bottomNavigationBarItems,
        ),
      ),
    );
  }
}
