import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/theme/status_colors.dart';

class AdherenceScreen extends ConsumerStatefulWidget {
  const AdherenceScreen({super.key});

  @override
  ConsumerState<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends ConsumerState<AdherenceScreen> {
  AdherenceMetrics? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();

    ref.listenManual(adherenceProvider, (previous, next) {
      _loadMetrics();
    });
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    final metrics = await ref.read(adherenceProvider.notifier).getMetrics();
    setState(() {
      _metrics = metrics;
      _isLoading = false;
    });
  }

  Color _getAdherenceColor(double percentage, ThemeData theme) {
    if (percentage >= 90) return theme.statusColors.success;
    if (percentage >= 75) return theme.statusColors.info;
    if (percentage >= 60) return theme.statusColors.warning;
    return theme.statusColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adherence Metrics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _metrics == null
              ? _buildEmptyState(context)
              : _buildMetricsContent(context, _metrics!),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No adherence data',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your medications to see adherence metrics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsContent(BuildContext context, AdherenceMetrics metrics) {
    final theme = Theme.of(context);
    final adherenceColor = _getAdherenceColor(metrics.weeklyAdherence, theme);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly adherence percentage (main metric)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: adherenceColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: adherenceColor, width: 2),
          ),
          child: Column(
            children: [
              Icon(
                Icons.insights,
                size: 48,
                color: adherenceColor,
              ),
              const SizedBox(height: 12),
              Text(
                '${metrics.weeklyAdherence.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: adherenceColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '7-Day Adherence',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Grid of other metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.local_fire_department,
                value: '${metrics.currentStreak}',
                label: 'Day Streak',
                color: theme.statusColors.streak,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.check_circle,
                value: '${metrics.totalDosesTaken}',
                label: 'Taken',
                color: theme.statusColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.cancel,
                value: '${metrics.totalDosesSkipped}',
                label: 'Skipped',
                color: theme.statusColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.error,
                value: '${metrics.totalDosesMissed}',
                label: 'Missed',
                color: theme.statusColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Summary text
        Center(
          child: Text(
            'Based on ${metrics.totalDosesScheduled} scheduled doses in the last 7 days',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
