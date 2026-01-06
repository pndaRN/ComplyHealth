import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/models/medication_log.dart';

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
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    _weekLogs.clear();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final logs = await ref.read(adherenceProvider.notifier).getLogsForDate(date);
      _weekLogs[normalizedDate] = logs;
    }

    setState(() => _isLoading = false);
  }

  Color _getDayColor(DateTime date) {
    final logs = _weekLogs[date] ?? [];
    if (logs.isEmpty) return Colors.grey.shade300;

    final takenCount = logs.where((log) => log.status == DoseStatus.taken).length;
    final totalCount = logs.length;
    final percentage = (takenCount / totalCount) * 100;

    if (percentage == 100) return Colors.green;
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 25) return Colors.deepOrange;
    return Colors.red;
  }

  double _getDayAdherence(DateTime date) {
    final logs = _weekLogs[date] ?? [];
    if (logs.isEmpty) return 0.0;

    final takenCount = logs.where((log) => log.status == DoseStatus.taken).length;
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adherence: ${_getDayAdherence(date).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
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
                        leading: Icon(
                          log.status == DoseStatus.taken
                              ? Icons.check_circle
                              : log.status == DoseStatus.skipped
                                  ? Icons.cancel
                                  : Icons.error,
                          color: log.status == DoseStatus.taken
                              ? Colors.green
                              : log.status == DoseStatus.skipped
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        title: Text(log.medicationName),
                        subtitle: Text(
                          '${log.dosage} - ${DateFormat('h:mm a').format(log.scheduledTime)}',
                        ),
                        trailing: Text(
                          log.status == DoseStatus.taken
                              ? 'Taken'
                              : log.status == DoseStatus.skipped
                                  ? 'Skipped'
                                  : 'Missed',
                          style: TextStyle(
                            color: log.status == DoseStatus.taken
                                ? Colors.green
                                : log.status == DoseStatus.skipped
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
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
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Calendar grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: weekDays.map((date) {
                      final isToday = date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;
                      final color = _getDayColor(date);
                      final adherence = _getDayAdherence(date);

                      return GestureDetector(
                        onTap: () => _showDayDetails(date),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight:
                                    isToday ? FontWeight.bold : FontWeight.normal,
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
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('d').format(date),
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.green, 'Perfect'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.lightGreen, 'Good'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.orange, 'Fair'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.red, 'Poor'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
