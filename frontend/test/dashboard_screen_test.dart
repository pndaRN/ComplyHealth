import 'package:complyhealth/core/models/profile.dart';
import 'package:complyhealth/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:complyhealth/core/state/profile_provider.dart';
import 'package:complyhealth/core/state/conditions_provider.dart';
import 'package:complyhealth/core/state/medication_provider.dart';
import 'package:complyhealth/core/models/disease.dart';
import 'package:complyhealth/core/models/medication.dart';

// Mock profile provider
final mockProfileProvider =
    FutureProvider<Profile>((ref) async => Profile(firstName: 'John'));

void main() {
  testWidgets('DashboardScreen shows welcome message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWithProvider(mockProfileProvider),
          conditionsProvider.overrideWithProvider(
            FutureProvider<List<Disease>>((ref) async => []),
          ),
          medicationProvider.overrideWithProvider(
            FutureProvider<List<Medication>>((ref) async => []),
          ),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Let the future providers resolve
    await tester.pump();

    // Verify the welcome message is shown
    expect(find.text('Good to see you, John'), findsOneWidget);
  });
}
