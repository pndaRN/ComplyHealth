import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/adherence_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/theme/theme_provider.dart';
import 'widgets/todays_medications_widget.dart';
import 'widgets/enhanced_calendar_widget.dart';
import 'widgets/at_a_glance_widget.dart';
import '../../core/state/profile_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    ref.invalidate(adherenceProvider);
    ref.invalidate(medicationProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(conditionsProvider);

    await Future.wait([
      ref.read(adherenceProvider.future),
      ref.read(medicationProvider.future),
      ref.read(profileProvider.future),
      ref.read(conditionsProvider.future),
    ]);

    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conditionsAsync = ref.watch(conditionsProvider);
    final medsAsync = ref.watch(medicationProvider);
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profile) {
          return conditionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (conditions) {
              return medsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (meds) {
                  return Stack(
                    children: [
                      // Background gradient
                      Container(
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(0.985, -0.174),
                            end: const Alignment(-0.985, 0.174),
                            colors: theme.brightness == Brightness.dark
                                ? [
                                    theme.colorScheme.primary,
                                    const Color(0xFF050A15),
                                  ]
                                : [
                                    theme.colorScheme.primary.withValues(alpha: 0.7),
                                    const Color(0xFFF5F8FF),
                                  ],
                          ),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor,
                            ],
                            stops: const [0.3, 0.95],
                          ),
                        ),
                      ),
                      // Main content with fixed AppBar and Calendar
                      SafeArea(
                        child: Column(
                          children: [
                            // Fixed AppBar area
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: profile.firstName.isNotEmpty
                                            ? Text(
                                                'Good to see you, ${profile.firstName}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            : const Text(
                                                'Welcome',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final themeState = ref.watch(themeProvider);
                                      final isDark =
                                          themeState.themeMode == ThemeMode.dark ||
                                          (themeState.themeMode == ThemeMode.system &&
                                              MediaQuery.of(context).platformBrightness ==
                                                  Brightness.dark);

                                      return PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          color: Colors.white,
                                        ),
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
                                                Icon(
                                                  isDark ? Icons.light_mode : Icons.dark_mode,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  isDark ? 'Light mode' : 'Dark mode',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Fixed Calendar Widget
                            EnhancedCalendarWidget(
                              key: ValueKey('adherence_$_refreshKey'),
                            ),
                            // Scrollable content
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _onRefresh,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    children: [
                                      TodaysMedicationsWidget(
                                        key: ValueKey('medications_$_refreshKey'),
                                      ),
                                      AtAGlanceWidget(
                                        key: ValueKey('glance_$_refreshKey'),
                                        conditions: conditions,
                                        medications: meds,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
