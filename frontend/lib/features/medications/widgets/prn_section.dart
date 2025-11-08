import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PRNSection extends StatelessWidget {
  final bool isPRN;
  final Function(bool) onPRNChanged;
  final TextEditingController maxDosesController;

  const PRNSection({
    super.key,
    required this.isPRN,
    required this.onPRNChanged,
    required this.maxDosesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('Take as needed (PRN)'),
          subtitle: const Text('For medications taken only when necessary'),
          value: isPRN,
          onChanged: (bool? value) {
            if (value != null) {
              onPRNChanged(value);
            }
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (isPRN) ...[
          const SizedBox(height: 8),
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
          ),
        ],
      ],
    );
  }
}
