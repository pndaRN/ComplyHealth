import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/disease.dart';

/// Dialog for adding a custom condition not in the ICD-10 database
class AddCustomConditionDialog extends StatefulWidget {
  const AddCustomConditionDialog({super.key});

  @override
  State<AddCustomConditionDialog> createState() => _AddCustomConditionDialogState();
}

class _AddCustomConditionDialogState extends State<AddCustomConditionDialog> {
  // Validation constants
  static const int _customCodeLength = 8;
  static const int _minConditionNameLength = 3;

  late TextEditingController nameCtrl;
  late TextEditingController notesCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      // Generate unique code for custom condition
      const uuid = Uuid();
      final customCode = 'CUSTOM_${uuid.v4().substring(0, _customCodeLength).toUpperCase()}';

      // Create Disease object with custom fields
      final customCondition = Disease(
        code: customCode,
        name: nameCtrl.text.trim(),
        category: 'Custom',
        commonName: nameCtrl.text.trim(),
        description: 'Custom condition added by user',
        isCustom: true,
        personalNotes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
        createdAt: DateTime.now(),
      );

      Navigator.of(context).pop(customCondition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Condition'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add a condition that is not in our database. You can optionally submit a request to have it added to the official list.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Condition Name Field
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Condition Name *',
                  hintText: 'Enter the condition name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Condition name is required';
                  }
                  if (value.trim().length < _minConditionNameLength) {
                    return 'Name must be at least $_minConditionNameLength characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Personal Notes Field
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Personal Notes (Optional)',
                  hintText: 'Add any personal notes about your condition',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
