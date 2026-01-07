import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/models/medication_log.dart';
import 'package:complyhealth/core/theme/status_colors.dart';

class AdherenceHistoryWidget extends ConsumerStatefulWidget {
  const AdherenceHistoryWidget({super.key});

  @override
  ConsumerState<AdherenceHistoryWidget> createState() =>
      _AdherenceHistoryWidgetState();
}

class _AdherenceHistoryWidgetState
    extends ConsumerState<AdherenceHistoryWidget> {
  final Map<DateTime, List<MedicationLog>> _weekLogs = {};
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadWeekData();

    // Listen for adherence state changes to refresh history
    ref.listenManual(adherenceProvider, (previous, next) {
      _loadWeekData();
    });
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    _weekLogs.clear();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final logs = await ref
          .read(adherenceProvider.notifier)
          .getLogsForDate(date);
      _weekLogs[normalizedDate] = logs;
    }

    setState(() => _isLoading = false);
  }

  Color _getDayColor(DateTime date, ThemeData theme) {
    final logs = _weekLogs[date] ?? [];
    if (logs.isEmpty) return theme.colorScheme.outlineVariant;

    final takenCount = logs
        .where((log) => log.status == DoseStatus.taken)
        .length;
    final totalCount = logs.length;
    final percentage = (takenCount / totalCount) * 100;

    if (percentage == 100) return theme.statusColors.success;
    if (percentage >= 75) return theme.statusColors.success.withValues(alpha: 0.7);
    if (percentage >= 50) return theme.statusColors.warning;
    if (percentage >= 25) return theme.statusColors.warning.withValues(alpha: 0.8);
    return theme.statusColors.error;
  }

  double _getDayAdherence(DateTime date) {
    final logs = _weekLogs[date] ?? [];
    if (logs.isEmpty) return 0.0;

    final takenCount = logs
        .where((log) => log.status == DoseStatus.taken)
        .length;
    return (takenCount / logs.length) * 100;
  }

  void _showDayDetails(DateTime date) {
    final logs = _weekLogs[date] ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(date),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Adherence: ${_getDayAdherence(date).toStringAsFixed(1)}%',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
              ),
              const Divider(height: 24),
              if (logs.isEmpty)
                const Text('No medications scheduled for this day')
              else
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        leading: Builder(
                          builder: (context) {
                            final theme = Theme.of(context);
                            return Icon(
                              log.status == DoseStatus.taken
                                  ? Icons.check_circle
                                  : log.status == DoseStatus.skipped
                                  ? Icons.cancel
                                  : Icons.error,
                              color: log.status == DoseStatus.taken
                                  ? theme.statusColors.success
                                  : log.status == DoseStatus.skipped
                                  ? theme.statusColors.warning
                                  : theme.statusColors.error,
                            );
                          },
                        ),
                        title: Text(log.medicationName),
                        subtitle: Text(
                          '${log.dosage} - ${DateFormat('h:mm a').format(log.scheduledTime)}',
                        ),
                        trailing: Builder(
                          builder: (context) {
                            final theme = Theme.of(context);
                            return Text(
                              log.status == DoseStatus.taken
                                  ? 'Taken'
                                  : log.status == DoseStatus.skipped
                                  ? 'Skipped'
                                  : 'Missed',
                              style: TextStyle(
                                color: log.status == DoseStatus.taken
                                    ? theme.statusColors.success
                                    : log.status == DoseStatus.skipped
                                    ? theme.statusColors.warning
                                    : theme.statusColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final now = DateTime.now();
    final weekDays = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateTime(date.year, date.month, date.day);
    });

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '7-Day Adherence History',
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Calendar grid
                      Builder(
                        builder: (context) {
                          final theme = Theme.of(context);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: weekDays.map((date) {
                              final isToday =
                                  date.year == now.year &&
                                  date.month == now.month &&
                                  date.day == now.day;
                              final color = _getDayColor(date, theme);
                              final adherence = _getDayAdherence(date);

                              return GestureDetector(
                                onTap: () => _showDayDetails(date),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('E').format(date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: isToday
                                            ? Border.all(
                                                color: theme.statusColors.info,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          DateFormat('d').format(date),
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${adherence.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Builder(
                        builder: (context) {
                          final theme = Theme.of(context);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(theme.statusColors.success, 'Perfect', theme),
                              const SizedBox(width: 12),
                              _buildLegendItem(theme.statusColors.success.withValues(alpha: 0.7), 'Good', theme),
                              const SizedBox(width: 12),
                              _buildLegendItem(theme.statusColors.warning, 'Fair', theme),
                              const SizedBox(width: 12),
                              _buildLegendItem(theme.statusColors.error, 'Poor', theme),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
