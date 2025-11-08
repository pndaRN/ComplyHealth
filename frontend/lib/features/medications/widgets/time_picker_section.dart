import 'package:flutter/material.dart';

class TimePickerSection extends StatelessWidget {
  final List<TimeOfDay> selectedTimes;
  final Function(TimeOfDay) onAddTime;
  final Function(TimeOfDay) onRemoveTime;

  const TimePickerSection({
    super.key,
    required this.selectedTimes,
    required this.onAddTime,
    required this.onRemoveTime,
  });

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    // Sort times chronologically for display
    final sortedTimes = List<TimeOfDay>.from(selectedTimes)
      ..sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Scheduled Times',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton.icon(
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  onAddTime(picked);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Time'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sortedTimes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No times scheduled. Add times using presets or custom time picker.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedTimes.map((time) {
              return Chip(
                label: Text(_formatTime(time)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => onRemoveTime(time),
              );
            }).toList(),
          ),
      ],
    );
  }
}
