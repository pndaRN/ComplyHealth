import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PRNSetupDialog extends StatefulWidget {
  const PRNSetupDialog({super.key});

  @override
  State<PRNSetupDialog> createState() => _PRNSetupDialogState();
}

class _PRNSetupDialogState extends State<PRNSetupDialog> {
  final TextEditingController maxDosesController = TextEditingController();

  @override
  void dispose() {
    maxDosesController.dispose();
    super.dispose();
  }

  String _getIntervalSuggestion(int doses) {
    if (doses <= 0) return '';
    final hoursPerDay = 24;
    final interval = hoursPerDay / doses;

    if (doses == 1) return 'Once daily';
    if (doses == 2) return 'Every 12 hours';
    if (doses == 3) return 'Every 8 hours';
    if (doses == 4) return 'Every 6 hours';
    if (doses == 6) return 'Every 4 hours';

    return 'Approximately every ${interval.toStringAsFixed(1)} hours';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PRN Medication Setup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configure "as needed" medication',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: maxDosesController,
            decoration: const InputDecoration(
              labelText: 'Maximum doses per day',
              hintText: 'e.g., 4',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.medical_services),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              setState(() {}); // Rebuild to update interval suggestion
            },
          ),
          const SizedBox(height: 12),
          if (maxDosesController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getIntervalSuggestion(int.tryParse(maxDosesController.text) ?? 0),
                      style: const TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final maxDoses = int.tryParse(maxDosesController.text);
            if (maxDoses != null && maxDoses > 0) {
              Navigator.pop(context, maxDoses);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid number of doses'),
                ),
              );
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
