import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/disease.dart';
import 'core/models/medication.dart';
import 'features/conditions/conditions_screen.dart';
import 'features/medications/medications_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(DiseaseAdapter());
  Hive.registerAdapter(MedicationAdapter());
  runApp(const ProviderScope(child: MedSyncApp()));
}

class MedSyncApp extends StatefulWidget {
  const MedSyncApp({super.key});

  @override
  State<MedSyncApp> createState() => _MedSyncAppState();
}

class _MedSyncAppState extends State<MedSyncApp> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    ConditionsScreen(),
    MedicationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedSync',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        body: _screens[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
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
          ],
        ),
      ),
    );
  }
}
