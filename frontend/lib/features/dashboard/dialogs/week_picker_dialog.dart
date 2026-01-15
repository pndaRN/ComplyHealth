import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekPickerDialog extends StatefulWidget {
  final DateTime initialWeekStart;

  const WeekPickerDialog({super.key, required this.initialWeekStart});

  @override
  State<WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<WeekPickerDialog> {
  late DateTime _displayMonth;
  late DateTime _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(
      widget.initialWeekStart.year,
      widget.initialWeekStart.month,
      1,
    );
    _selectedWeekStart = widget.initialWeekStart;
  }

  static DateTime _getWeekStart(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  }

  String _getWeekRangeDisplay(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (weekStart.month == weekEnd.month) {
      return 'Week of ${DateFormat('MMM d').format(weekStart)}-${DateFormat('d, y').format(weekEnd)}';
    } else {
      return 'Week of ${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, y').format(weekEnd)}';
    }
  }

  List<List<DateTime?>> _buildMonthGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final startPadding = firstDay.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final List<DateTime?> allDays = [];

    // Add padding days from previous month
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final daysInPrevMonth = DateTime(month.year, month.month, 0).day;
    for (int i = 0; i < startPadding; i++) {
      allDays.add(
        DateTime(
          prevMonth.year,
          prevMonth.month,
          daysInPrevMonth - startPadding + i + 1,
        ),
      );
    }

    // Add all days of current month
    for (int i = 1; i <= daysInMonth; i++) {
      allDays.add(DateTime(month.year, month.month, i));
    }

    // Add padding days from next month to complete grid
    final remainingDays = 42 - allDays.length; // 6 rows * 7 days
    for (int i = 1; i <= remainingDays; i++) {
      final nextMonth = DateTime(month.year, month.month + 1, 1);
      allDays.add(DateTime(nextMonth.year, nextMonth.month, i));
    }

    // Convert to 2D list (weeks)
    final List<List<DateTime?>> weeks = [];
    for (int i = 0; i < allDays.length; i += 7) {
      weeks.add(
        allDays.sublist(i, (i + 7) > allDays.length ? allDays.length : i + 7),
      );
    }

    return weeks;
  }

  bool _isInSelectedWeek(DateTime date) {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    return date.isAfter(_selectedWeekStart.subtract(const Duration(days: 1))) &&
        date.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  void _selectWeek(DateTime weekStart) {
    setState(() {
      _selectedWeekStart = weekStart;
    });
  }

  void _navigatePreviousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    });
  }

  void _navigateNextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedWeekStart);
  }

  Widget _buildDayCell(DateTime? day) {
    final theme = Theme.of(context);
    final isPaddingDay = day == null || day.month != _displayMonth.month;
    final isInSelectedWeek = !isPaddingDay && _isInSelectedWeek(day);

    return GestureDetector(
      onTap: () {
        if (!isPaddingDay) {
          final weekStart = _getWeekStart(day);
          _selectWeek(weekStart);
        }
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isInSelectedWeek
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          border: isInSelectedWeek
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            isPaddingDay ? '' : DateFormat('d').format(day),
            style: TextStyle(
              color: isPaddingDay
                  ? Colors.transparent
                  : isInSelectedWeek
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
              fontWeight: isInSelectedWeek
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthGrid = _buildMonthGrid(_displayMonth);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _navigatePreviousMonth,
                  icon: const Icon(Icons.arrow_back_ios),
                  tooltip: 'Previous month',
                ),
                Text(
                  DateFormat('MMMM y').format(_displayMonth),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _navigateNextMonth,
                  icon: const Icon(Icons.arrow_forward_ios),
                  tooltip: 'Next month',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Day headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((
                day,
              ) {
                return SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Calendar grid
            Column(
              children: monthGrid.map((week) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: week.map((day) => _buildDayCell(day)).toList(),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Selected week display
            Center(
              child: Text(
                _getWeekRangeDisplay(_selectedWeekStart),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dialog actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _confirmSelection,
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
