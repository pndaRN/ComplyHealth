import 'package:flutter/material.dart';
import '../dialogs/prn_setup_dialog.dart';

class TimingPresetButtons extends StatelessWidget {
  final Function(List<TimeOfDay>) onTimesSelected;
  final Function(int maxDoses)? onPRNSelected;

  const TimingPresetButtons({
    super.key,
    required this.onTimesSelected,
    this.onPRNSelected,
  });

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
            _PresetButton(
              label: 'Daily',
              onPressed: () => onTimesSelected([
                const TimeOfDay(hour: 8, minute: 0), // Example time for daily
              ]),
            ),
            _PresetButton(
              label: 'Twice a Day',
              onPressed: () => onTimesSelected([
                const TimeOfDay(hour: 8, minute: 0),
                const TimeOfDay(hour: 20, minute: 0),
              ]),
            ),
            _PresetButton(
              label: 'TID',
              onPressed: () => onTimesSelected([
                const TimeOfDay(hour: 8, minute: 0),
                const TimeOfDay(hour: 14, minute: 0),
                const TimeOfDay(hour: 20, minute: 0),
              ]),
            ),
            if (onPRNSelected != null)
              _PresetButton(
                label: 'PRN (As Needed)',
                onPressed: () async {
                  final maxDoses = await showDialog<int>(
                    context: context,
                    builder: (context) => const PRNSetupDialog(),
                  );
                  if (maxDoses != null) {
                    onPRNSelected!(maxDoses);
                  }
                },
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

  const _PresetButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
