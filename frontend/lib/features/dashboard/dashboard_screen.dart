import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/models/medication.dart';
import 'widgets/rotating_welcome_message.dart';
import 'widgets/todays_medications_widget.dart';
import 'widgets/adherence_history_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getTimingSummary(Medication medication) {
    if (medication.isPRN) {
      return 'PRN';
    }
    final count = medication.scheduledTimes.length;
    if (count == 0) return 'No schedule';
    if (count == 1) return 'Once daily';
    return '${count}x daily';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = ref.watch(conditionsProvider);
    final meds = ref.watch(medicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartPatient'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final themeState = ref.watch(themeProvider);
              final isDark =
                  themeState.themeMode == ThemeMode.dark ||
                  (themeState.themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness ==
                          Brightness.dark);

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'theme') {
                    ref.read(themeProvider.notifier).toggleTheme();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                        const SizedBox(width: 12),
                        Text(isDark ? 'Light mode' : 'Dark mode'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotatingWelcomeMessage(),
            const Divider(height: 1),
            const TodaysMedicationsWidget(),
            const AdherenceHistoryWidget(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'At A Glance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (conditions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No conditions tracked yet.\nAdd a condition to get started!',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(20),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: conditions.length,
                  itemBuilder: (context, index) {
                    final condition = conditions[index];
                    final related = meds
                        .where(
                          (medication) => medication.conditionNames.contains(
                            condition.name,
                          ),
                        )
                        .toList();
                    return Card(
                      child: ListTile(
                        title: Text(condition.commonName),
                        subtitle: related.isEmpty
                            ? const Text('No medications yet')
                            : Text(
                                related
                                    .map(
                                      (medication) =>
                                          '${medication.name} - ${medication.dosage} - ${_getTimingSummary(medication)}',
                                    )
                                    .join('\n'),
                              ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
