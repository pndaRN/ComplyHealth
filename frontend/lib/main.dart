import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/disease.dart';
import 'features/conditions/conditions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(DiseaseAdapter());
  runApp(const ProviderScope(child: MedSyncApp()));
}

class MedSyncApp extends StatelessWidget {
  const MedSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedSync',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ConditionsScreen(),
    );
  }
}
