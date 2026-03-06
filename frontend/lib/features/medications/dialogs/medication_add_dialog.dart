import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/medication.dart';
import '../../../core/state/medication_provider.dart';
import '../../../core/state/conditions_provider.dart';
import '../widgets/medication_form_content.dart';
import '../utils/medication_validator.dart';

/// Bottom sheet for adding a new medication
class MedicationAddSheet extends ConsumerStatefulWidget {
  const MedicationAddSheet({super.key});

  @override
  ConsumerState<MedicationAddSheet> createState() => _MedicationAddSheetState();
}

class _MedicationAddSheetState extends ConsumerState<MedicationAddSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController doseCtrl;
  late TextEditingController maxDosesCtrl;
  List<String> selectedConditions = [];
  Set<String> _autoSelectedConditions = {};
  bool isPRN = false;
  bool isTimeSensitive = true;
  List<TimeOfDay> scheduledTimes = [];
  List<TimeOfDay>? _savedScheduledTimes;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    doseCtrl = TextEditingController();
    maxDosesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    doseCtrl.dispose();
    maxDosesCtrl.dispose();
    super.dispose();
  }

  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _onSave() {
    final notifier = ref.read(medicationProvider.notifier);

    if (!MedicationValidator.validateForm(
      context: context,
      name: nameCtrl.text,
      dosage: doseCtrl.text,
      conditions: selectedConditions,
      isPRN: isPRN,
      scheduledTimes: scheduledTimes,
      maxDailyDoses: maxDosesCtrl.text.isEmpty
          ? null
          : int.tryParse(maxDosesCtrl.text),
    )) {
      return;
    }

    final newMedication = Medication(
      id: const Uuid().v4(),
      name: nameCtrl.text.trim(),
      dosage: doseCtrl.text.trim(),
      conditionNames: selectedConditions,
      isPRN: isPRN,
      scheduledTimes: scheduledTimes.map(_timeToString).toList(),
      maxDailyDoses: maxDosesCtrl.text.isEmpty
          ? null
          : int.tryParse(maxDosesCtrl.text),
      isTimeSensitive: isTimeSensitive,
    );
    notifier.addMeds(newMedication);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final conditionsAsync = ref.watch(conditionsProvider);

    // Auto-selection logic
    conditionsAsync.whenData((conditions) {
      if (selectedConditions.isEmpty && conditions.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              selectedConditions = [conditions.first.name];
              _autoSelectedConditions = {conditions.first.name};
            });
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Medication'),
        actions: [
          TextButton(
            onPressed: conditionsAsync.isLoading ? null : _onSave,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: conditionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading conditions: $err')),
        data: (conditions) => MedicationFormContent(
          nameController: nameCtrl,
          dosageController: doseCtrl,
          conditions: conditions,
          selectedConditions: selectedConditions,
          onConditionsChanged: (value) {
            setState(() {
              selectedConditions = value;
              // Clear auto-selection if user manually changes conditions
              if (!_autoSelectedConditions.every(value.contains)) {
                _autoSelectedConditions.clear();
              }
            });
          },
          isPRN: isPRN,
          onPRNChanged: (value) {
            setState(() {
              if (value) {
                // Switching to PRN - save and clear times
                _savedScheduledTimes = List.from(scheduledTimes);
                scheduledTimes = [];
                isPRN = true;
              } else {
                // Switching from PRN - restore times
                if (_savedScheduledTimes != null) {
                  scheduledTimes = _savedScheduledTimes!;
                  _savedScheduledTimes = null;
                }
                isPRN = false;
                maxDosesCtrl.clear();
              }
            });
          },
          scheduledTimes: scheduledTimes,
          onTimesChanged: (value) {
            setState(() {
              scheduledTimes = value;
            });
          },
          maxDosesController: maxDosesCtrl,
          autoSelectedConditions: _autoSelectedConditions,
          isTimeSensitive: isTimeSensitive,
          onTimeSensitiveChanged: (value) {
            setState(() {
              isTimeSensitive = value;
            });
          },
        ),
      ),
    );
  }
}
