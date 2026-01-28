import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/theme/status_colors.dart';

class DailyProgressWidget extends ConsumerStatefulWidget {
  const DailyProgressWidget({super.key});

  @override
  ConsumerState<DailyProgressWidget> createState() =>
      _DailyProgressWidgetState();
}

class _DailyProgressWidgetState extends ConsumerState<DailyProgressWidget> {
  List<MedicationInstance> _instances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    setState(() => _isLoading = true);

    final instances = await ref
        .read(adherenceProvider.notifier)
        .getTodayInstances();

    if (mounted) {
      setState(() {
        _instances = instances;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to adherence provider changes to refresh data
    ref.listen(adherenceProvider, (previous, next) {
      _loadInstances();
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onBackgroundContentColor = isDark
        ? Colors.white
        : theme.colorScheme.onSurface;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: onBackgroundContentColor),
        ),
      );
    }

    // Calculate progress from loaded instances
    final scheduledInstances = _instances.where((i) => !i.isPRN).toList();
    final takenCount = scheduledInstances.where((i) => i.isTaken).length;
    final totalCount = scheduledInstances.length;

    // Protect against division by zero
    final targetProgress = totalCount > 0 ? takenCount / totalCount : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: targetProgress),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, child) {
          final percentage = (animatedProgress * 100).toInt();
          final progressColor = _getProgressColor(theme, animatedProgress);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.today,
                        size: 20,
                        color: onBackgroundContentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Today's Progress",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onBackgroundContentColor,
                        ),
                      ),
                    ],
                  ),
                  // Animated Percentage Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: progressColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$percentage%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Progress Bar ---
              Stack(
                children: [
                  // Background Track
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: onBackgroundContentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Animated Fill
                  FractionallySizedBox(
                    widthFactor: animatedProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            progressColor.withValues(alpha: 0.8),
                            progressColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: animatedProgress > 0
                            ? [
                                BoxShadow(
                                  color: progressColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      // Optional: Inner Shine Effect
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Footer Status Text ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$takenCount of $totalCount doses taken',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onBackgroundContentColor.withValues(alpha: 0.8),
                    ),
                  ),
                  if (animatedProgress >= 1.0)
                    Row(
                      children: [
                        Icon(
                          Icons.celebration,
                          size: 16,
                          color: theme.statusColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Complete!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.statusColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else if (totalCount > 0)
                    Text(
                      '${totalCount - takenCount} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onBackgroundContentColor.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getProgressColor(ThemeData theme, double progress) {
    if (progress >= 1.0) return theme.statusColors.success;
    if (progress >= 0.75)
      return theme.statusColors.success.withValues(alpha: 0.85);
    if (progress >= 0.5) return theme.statusColors.info;
    if (progress >= 0.25) return theme.statusColors.warning;
    return theme.brightness == Brightness.dark
        ? Colors.white
        : theme.colorScheme.primary;
  }
}
