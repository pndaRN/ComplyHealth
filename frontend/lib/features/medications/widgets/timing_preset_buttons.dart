import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/settings_provider.dart';

class TimingPresetButtons extends ConsumerStatefulWidget {
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
  ConsumerState<TimingPresetButtons> createState() =>
      _TimingPresetButtonsState();
}

class _TimingPresetButtonsState extends ConsumerState<TimingPresetButtons> {
  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final morningTime = _parseTime(settings.morningTime);
    final noonTime = _parseTime(settings.noonTime);
    final eveningTime = _parseTime(settings.eveningTime);
    final nightTime = _parseTime(settings.nightTime);

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
              selected: _isTimeSelected(morningTime) && !widget.isPRN,
              onSelected: (_) => _toggleTime(morningTime),
            ),
            FilterChip(
              label: const Text('Noon'),
              selected: _isTimeSelected(noonTime) && !widget.isPRN,
              onSelected: (_) => _toggleTime(noonTime),
            ),
            FilterChip(
              label: const Text('Evening'),
              selected: _isTimeSelected(eveningTime) && !widget.isPRN,
              onSelected: (_) => _toggleTime(eveningTime),
            ),
            FilterChip(
              label: const Text('Night'),
              selected: _isTimeSelected(nightTime) && !widget.isPRN,
              onSelected: (_) => _toggleTime(nightTime),
            ),
          ],
        ),
      ],
    );
  }
}
