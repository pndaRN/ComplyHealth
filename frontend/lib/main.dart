import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartpatient/core/models/profile.dart';
import 'package:smartpatient/features/education/eductation_screen.dart';
import 'core/models/disease.dart';
import 'core/models/medication.dart';
import 'core/models/medication_log.dart';
import 'core/services/notification_service.dart';
import 'features/conditions/conditions_screen.dart';
import 'features/medications/medications_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(DiseaseAdapter());
  Hive.registerAdapter(MedicationAdapterCustom());
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(DoseStatusAdapter());
  Hive.registerAdapter(MedicationLogAdapter());

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const ProviderScope(child: SmartPatientApp()));
}

class SmartPatientApp extends StatefulWidget {
  const SmartPatientApp({super.key});

  @override
  State<SmartPatientApp> createState() => _SmartPatientAppState();
}

class _SmartPatientAppState extends State<SmartPatientApp> {
  int _index = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    ConditionsScreen(),
    MedicationsScreen(),
    EducationScreen(),
    ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavigationBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.healing),
      label: 'Conditions',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.medication),
      label: 'Medications',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.school),
      label: 'Education',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

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
