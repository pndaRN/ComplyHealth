import 'package:flutter/material.dart';

class TimingPresetButtons extends StatefulWidget {
  final List<TimeOfDay> scheduledTimes;
  final bool isPRN;
  final ValueChanged<TimeOfDay> onTimeAdded;
  final ValueChanged<TimeOfDay> onTimeRemoved;
  final ValueChanged<bool> onPRNChanged;

  const TimingPresetButtons({
    super.key,
    required this.scheduledTimes,
    required this.isPRN,
    required this.onTimeAdded,
    required this.onTimeRemoved,
    required this.onPRNChanged,
  });

  @override
  State<TimingPresetButtons> createState() => _TimingPresetButtonsState();
}

class _TimingPresetButtonsState extends State<TimingPresetButtons> {
  /// Standard medication timing presets based on medical best practices:
  /// - Morning (7 AM): Typical wake time for most patients
  /// - Noon (12 PM): Mid-day, often taken with lunch
  /// - Evening (5 PM): Before dinner, end of work day
  /// - Night (9 PM): Before bedtime, allows 1-2 hours before sleep
  static const TimeOfDay morningTime = TimeOfDay(hour: 7, minute: 0);
  static const TimeOfDay noonTime = TimeOfDay(hour: 12, minute: 0);
  static const TimeOfDay eveningTime = TimeOfDay(hour: 17, minute: 0);
  static const TimeOfDay nightTime = TimeOfDay(hour: 21, minute: 0);

  bool get _isMorningSelected => _isTimeSelected(morningTime);
  bool get _isNoonSelected => _isTimeSelected(noonTime);
  bool get _isEveningSelected => _isTimeSelected(eveningTime);
  bool get _isNightSelected => _isTimeSelected(nightTime);

  bool _isTimeSelected(TimeOfDay time) {
    return widget.scheduledTimes.any(
      (t) => t.hour == time.hour && t.minute == time.minute,
    );
  }

  void _toggleTime(TimeOfDay time) {
    if (_isTimeSelected(time)) {
      widget.onTimeRemoved(time);
    } else {
      widget.onTimeAdded(time);
      // If PRN is selected, deselect it when a time button is clicked
      if (widget.isPRN) {
        widget.onPRNChanged(false);
      }
    }
  }

  void _togglePRN() {
    widget.onPRNChanged(!widget.isPRN);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Presets', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Morning'),
              selected: _isMorningSelected && !widget.isPRN,
              onSelected: (_) => _toggleTime(morningTime),
            ),
            FilterChip(
              label: const Text('Noon'),
              selected: _isNoonSelected && !widget.isPRN,
              onSelected: (_) => _toggleTime(noonTime),
            ),
            FilterChip(
              label: const Text('Evening'),
              selected: _isEveningSelected && !widget.isPRN,
              onSelected: (_) => _toggleTime(eveningTime),
            ),
            FilterChip(
              label: const Text('Night'),
              selected: _isNightSelected && !widget.isPRN,
              onSelected: (_) => _toggleTime(nightTime),
            ),
            FilterChip(
              label: const Text('PRN'),
              selected: widget.isPRN,
              onSelected: (_) => _togglePRN(),
            ),
          ],
        ),
      ],
    );
  }
}
