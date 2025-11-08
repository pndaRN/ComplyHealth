import 'package:flutter/material.dart';

class TimingPresetButtons extends StatelessWidget {
  final Function(List<TimeOfDay>) onTimesSelected;

  const TimingPresetButtons({
    super.key,
    required this.onTimesSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Presets',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetButton(
              label: 'Morning (8 AM)',
              onPressed: () => onTimesSelected([const TimeOfDay(hour: 8, minute: 0)]),
            ),
            _PresetButton(
              label: 'Evening (8 PM)',
              onPressed: () => onTimesSelected([const TimeOfDay(hour: 20, minute: 0)]),
            ),
            _PresetButton(
              label: 'Twice Daily',
              onPressed: () => onTimesSelected([
                const TimeOfDay(hour: 8, minute: 0),
                const TimeOfDay(hour: 20, minute: 0),
              ]),
            ),
            _PresetButton(
              label: 'Three Times Daily',
              onPressed: () => onTimesSelected([
                const TimeOfDay(hour: 8, minute: 0),
                const TimeOfDay(hour: 14, minute: 0),
                const TimeOfDay(hour: 20, minute: 0),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PresetButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
