import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/adherence_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/app_bar_widgets.dart';
import 'widgets/enhanced_calendar_widget.dart';
import 'widgets/at_a_glance_widget.dart';
import 'widgets/daily_progress_widget.dart'; // <--- Import your new widget
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
    // Watch all providers at the top level
    final conditionsAsync = ref.watch(conditionsProvider);
    final medsAsync = ref.watch(medicationProvider);
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onBackgroundContentColor = isDark
        ? Colors.white
        : theme.colorScheme.onSurface;

    // Render the Scaffold immediately, without waiting for data
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: profileAsync.when(
          data: (profile) => Text(
            profile.firstName.isNotEmpty
                ? 'Good to see you, ${profile.firstName}'
                : 'Welcome',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onBackgroundContentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          loading: () => Text(
            'Welcome',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onBackgroundContentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          error: (err, stack) => Text(
            'Welcome',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onBackgroundContentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [AppMoreMenu(iconColor: onBackgroundContentColor)],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.985, -0.174),
                end: const Alignment(-0.985, 0.174),
                colors: isDark
                    ? [theme.colorScheme.primary, const Color(0xFF050A15)]
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
                colors: [Colors.transparent, theme.scaffoldBackgroundColor],
                stops: const [0.3, 0.95],
              ),
            ),
          ),
          // Main content with fixed Calendar
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                EnhancedCalendarWidget(key: ValueKey('adherence_$_refreshKey')),
                // Scrollable content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const DailyProgressWidget(),
                          // Only block the "At A Glance" section if data is missing
                          // This allows daily progress and today's meds to function independently
                          if (conditionsAsync.hasValue && medsAsync.hasValue)
                            AtAGlanceWidget(
                              key: ValueKey('glance_$_refreshKey'),
                              conditions: conditionsAsync.value!,
                              medications: medsAsync.value!,
                            )
                          else if (conditionsAsync.isLoading ||
                              medsAsync.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(child: CircularProgressIndicator()),
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
      ),
    );
  }
}
