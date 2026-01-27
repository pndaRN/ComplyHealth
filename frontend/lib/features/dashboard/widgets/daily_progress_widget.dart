import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/theme/status_colors.dart';

class DailyProgressWidget extends ConsumerWidget {
  const DailyProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Reactively watch the data. When the provider updates, this widget rebuilds,
    // and the TweenAnimationBuilder automatically handles the animation to the new value.
    // Note: Adjust the type (e.g., List<MedicationInstance>) to match your provider.
    final adherenceState = ref.watch(adherenceProvider);

    // 2. Calculate progress synchronously from the state
    // (Assuming adherenceState is the list of instances, or use .when if it's AsyncValue)
    final instances = adherenceState is List ? adherenceState : []; 
    
    final scheduledInstances = instances.where((i) => !i.isPRN).toList();
    final takenCount = scheduledInstances.where((i) => i.isTaken).length;
    final totalCount = scheduledInstances.length;
    
    // Protect against division by zero
    final targetProgress = totalCount > 0 ? takenCount / totalCount : 0.0;
    
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                      Icon(Icons.today, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Today's Progress",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // Animated Percentage Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$percentage%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
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
                      color: theme.colorScheme.surfaceContainerHighest,
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
                            progressColor.withOpacity(0.8),
                            progressColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: animatedProgress > 0
                            ? [
                                BoxShadow(
                                  color: progressColor.withOpacity(0.4),
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
                                Colors.white.withOpacity(0.3),
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
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (animatedProgress >= 1.0)
                    Row(
                      children: [
                        Icon(Icons.celebration, size: 16, color: theme.statusColors.success),
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
                        color: theme.colorScheme.onSurfaceVariant,
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
    if (progress >= 0.75) return theme.statusColors.success.withOpacity(0.85);
    if (progress >= 0.5) return theme.statusColors.info;
    if (progress >= 0.25) return theme.statusColors.warning;
    return theme.colorScheme.primary; // Changed default from outline to primary
  }
}