import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/models/medication_log.dart';
import 'package:complyhealth/core/theme/status_colors.dart';
import '../dialogs/week_picker_dialog.dart';

class EnhancedCalendarWidget extends ConsumerStatefulWidget {
  const EnhancedCalendarWidget({super.key});

  @override
  ConsumerState<EnhancedCalendarWidget> createState() =>
      _EnhancedCalendarWidgetState();
}

class _EnhancedCalendarWidgetState extends ConsumerState<EnhancedCalendarWidget>
    with TickerProviderStateMixin<EnhancedCalendarWidget> {
  DateTime _currentWeekStart;
  DateTime _selectedDate;
  final Map<DateTime, List<MedicationLog>> _weekLogs = {};
  bool _isLoading = true;
  bool _isExpanded = false;
  bool _isAnimating = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  _EnhancedCalendarWidgetState()
    : _currentWeekStart = _getWeekStart(DateTime.now()),
      _selectedDate = DateTime.now();

  static DateTime _getWeekStart(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  }

  List<DateTime> _getCurrentWeekDays() {
    return List.generate(7, (i) {
      final date = _currentWeekStart.add(Duration(days: i));
      return DateTime(date.year, date.month, date.day);
    });
  }

  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today, ${DateFormat('MMM d, y').format(date)}';
    }
    return DateFormat('EEEE, MMM d, y').format(date);
  }

  String _getWeekRangeDisplay() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));

    if (_currentWeekStart.month == weekEnd.month) {
      return 'Week of ${DateFormat('MMM d').format(_currentWeekStart)}-${DateFormat('d, y').format(weekEnd)}';
    } else {
      return 'Week of ${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d, y').format(weekEnd)}';
    }
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _loadWeekData();

    // Listen for adherence state changes to refresh data
    ref.listenManual(adherenceProvider, (previous, next) {
      _loadWeekData();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);
    _weekLogs.clear();

    for (int i = 0; i < 7; i++) {
      final date = _currentWeekStart.add(Duration(days: i));
      final logs = await ref
          .read(adherenceProvider.notifier)
          .getLogsForDate(date);
      _weekLogs[DateTime(date.year, date.month, date.day)] = logs;
    }

    setState(() => _isLoading = false);
  }

  bool _isViewingCurrentWeek() {
    final actualCurrentWeekStart = _getWeekStart(DateTime.now());
    return _currentWeekStart.year == actualCurrentWeekStart.year &&
        _currentWeekStart.month == actualCurrentWeekStart.month &&
        _currentWeekStart.day == actualCurrentWeekStart.day;
  }

  Future<void> _navigateToPreviousWeek() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    // Slide out to the right
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(1.0, 0.0)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    await _slideController.forward();

    // Update data
    final newWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    setState(() {
      _currentWeekStart = newWeekStart;
      _selectedDate = newWeekStart;
    });
    await _loadWeekData();

    // Slide in from the left
    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _slideController.reset();
    await _slideController.forward();

    setState(() => _isAnimating = false);
  }

  Future<void> _navigateToNextWeek() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    // Slide out to the left
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    await _slideController.forward();

    // Update data
    final newWeekStart = _currentWeekStart.add(const Duration(days: 7));
    setState(() {
      _currentWeekStart = newWeekStart;
      _selectedDate = newWeekStart;
    });
    await _loadWeekData();

    // Slide in from the right
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _slideController.reset();
    await _slideController.forward();

    setState(() => _isAnimating = false);
  }

  Future<void> _navigateToCurrentWeek() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    final targetWeekStart = _getWeekStart(DateTime.now());
    final isGoingForward = targetWeekStart.isAfter(_currentWeekStart);

    // Slide out in the appropriate direction
    _slideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: Offset(isGoingForward ? -1.0 : 1.0, 0.0),
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    await _slideController.forward();

    // Update data
    setState(() {
      _currentWeekStart = targetWeekStart;
      _selectedDate = DateTime.now();
    });
    await _loadWeekData();

    // Slide in from the opposite direction
    _slideAnimation =
        Tween<Offset>(
          begin: Offset(isGoingForward ? 1.0 : -1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _slideController.reset();
    await _slideController.forward();

    setState(() => _isAnimating = false);
  }

  Future<void> _showWeekPicker() async {
    final selectedWeek = await showDialog<DateTime>(
      context: context,
      builder: (context) =>
          WeekPickerDialog(initialWeekStart: _currentWeekStart),
    );

    if (selectedWeek != null) {
      setState(() {
        _currentWeekStart = selectedWeek;
        _selectedDate = selectedWeek;
      });
      _loadWeekData();
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _showDayDetails(date);
  }

  Color _getDayColor(DateTime date, ThemeData theme) {
    final logs = _weekLogs[date] ?? [];
    if (logs.isEmpty) return theme.colorScheme.outlineVariant;

    final takenCount = logs
        .where((log) => log.status == DoseStatus.taken)
        .length;
    final totalCount = logs.length;
    final percentage = (takenCount / totalCount) * 100;

    if (percentage == 100) {
      return theme.statusColors.success;
    }
    if (percentage >= 75) {
      return theme.statusColors.success.withValues(alpha: 0.7);
    }
    if (percentage >= 50) {
      return theme.statusColors.warning;
    }
    if (percentage >= 25) {
      return theme.statusColors.warning.withValues(alpha: 0.8);
    }
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

    final weekDays = _getCurrentWeekDays();
    final now = DateTime.now();
    final theme = Theme.of(context);

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
                    color: theme.textTheme.titleLarge?.color,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '7-Day Adherence Calendar',
                        maxLines: 1,
                        style: theme.textTheme.titleLarge?.copyWith(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateForDisplay(_selectedDate),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _isAnimating
                                ? null
                                : _navigateToPreviousWeek,
                            icon: const Icon(Icons.arrow_back_ios),
                            tooltip: 'Previous week',
                            style: IconButton.styleFrom(
                              foregroundColor: _isAnimating
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _showWeekPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getWeekRangeDisplay(),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ),
                                if (!_isViewingCurrentWeek()) ...[
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: _navigateToCurrentWeek,
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                    ),
                                    tooltip:
                                        'Today', // Good for accessibility since text is gone
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isAnimating
                                ? null
                                : _navigateToNextWeek,
                            icon: const Icon(Icons.arrow_forward_ios),
                            tooltip: 'Next week',
                            style: IconButton.styleFrom(
                              foregroundColor: _isAnimating
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Calendar grid with slide animation
                ClipRect(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Day headers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: weekDays.map((date) {
                            return SizedBox(
                              width: 40,
                              child: Text(
                                DateFormat('E').format(date),
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
                        // Calendar days
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: weekDays.map((date) {
                            final isToday =
                                date.year == now.year &&
                                date.month == now.month &&
                                date.day == now.day;
                            final isSelected =
                                date.year == _selectedDate.year &&
                                date.month == _selectedDate.month &&
                                date.day == _selectedDate.day;
                            final color = _getDayColor(date, theme);
                            final adherence = _getDayAdherence(date);

                            return GestureDetector(
                              onTap: () => _selectDate(date),
                              child: Column(
                                children: [
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
                                          : isSelected
                                          ? Border.all(
                                              color: theme.colorScheme.primary,
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
                        ),
                        const SizedBox(height: 16),
                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(
                              theme.statusColors.success,
                              'Perfect',
                              theme,
                            ),
                            const SizedBox(width: 12),
                            _buildLegendItem(
                              theme.statusColors.success.withValues(alpha: 0.7),
                              'Good',
                              theme,
                            ),
                            const SizedBox(width: 12),
                            _buildLegendItem(
                              theme.statusColors.warning,
                              'Fair',
                              theme,
                            ),
                            const SizedBox(width: 12),
                            _buildLegendItem(
                              theme.statusColors.error,
                              'Poor',
                              theme,
                            ),
                          ],
                        ),
                      ],
                    ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
