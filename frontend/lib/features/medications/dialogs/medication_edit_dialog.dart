import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/medication.dart';
import '../../../core/state/medication_provider.dart';
import '../../../core/state/conditions_provider.dart';
import '../widgets/medication_form_content.dart';
import '../utils/medication_validator.dart';

/// Bottom sheet for editing an existing medication
class MedicationEditSheet extends ConsumerStatefulWidget {
  final Medication medication;

  const MedicationEditSheet({super.key, required this.medication});

  @override
  ConsumerState<MedicationEditSheet> createState() =>
      _MedicationEditSheetState();
}

class _MedicationEditSheetState extends ConsumerState<MedicationEditSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController doseCtrl;
  late TextEditingController maxDosesCtrl;
  late List<String> selectedConditions;
  Set<String> _autoSelectedConditions = {};
  late bool isPRN;
  late bool isTimeSensitive;
  late List<TimeOfDay> scheduledTimes;
  List<TimeOfDay>? _savedScheduledTimes;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.medication.name);
    doseCtrl = TextEditingController(text: widget.medication.dosage);
    maxDosesCtrl = TextEditingController(
      text: widget.medication.maxDailyDoses?.toString() ?? '',
    );
    selectedConditions = List<String>.from(widget.medication.conditionNames);
    isPRN = widget.medication.isPRN;
    isTimeSensitive = widget.medication.isTimeSensitive;
    scheduledTimes = widget.medication.scheduledTimes
        .map(_stringToTime)
        .whereType<TimeOfDay>()
        .toList();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    doseCtrl.dispose();
    maxDosesCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _stringToTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      // Invalid time string
    }
    return null;
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

    final updatedMedication = widget.medication.copyWith(
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
    notifier.updateMeds(updatedMedication);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final conditionsAsync = ref.watch(conditionsProvider);

    // Auto-selection logic for edit dialog
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
        title: const Text('Edit Medication'),
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
