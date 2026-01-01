import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/theme/theme_provider.dart';
import 'widgets/todays_medications_widget.dart';
import 'widgets/adherence_history_widget.dart';
import 'widgets/at_a_glance_widget.dart';
import '../../core/state/profile_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = ref.watch(conditionsProvider);
    final meds = ref.watch(medicationProvider);
    final profile = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: profile.firstName.isNotEmpty
            ? Text('Good to see you, ${profile.firstName}')
            : const Text('Welcome'),
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
      body: Stack(
        children: [
          // Gradient background
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.985, -0.174),
                end: const Alignment(-0.985, 0.174),
                colors: [theme.colorScheme.tertiary, theme.colorScheme.primary],
              ),
            ),
          ),
          // Vertical fade to background
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, theme.scaffoldBackgroundColor],
                stops: const [0.0, 0.8],
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),
                const TodaysMedicationsWidget(),
                const AdherenceHistoryWidget(),
                AtAGlanceWidget(
                  conditions: conditions,
                  medications: meds,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
