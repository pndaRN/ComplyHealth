import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/medication.dart';
import '../../core/models/notebook_entry.dart';
import '../../core/state/medication_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/notebook_provider.dart';
import '../../core/utils/condition_helper.dart';
import '../../core/utils/time_formatting_utils.dart';
import '../../core/widgets/app_bar_widgets.dart';
import 'dialogs/medication_edit_dialog.dart';

class MedicationDetailScreen extends ConsumerStatefulWidget {
  final Medication medication;

  const MedicationDetailScreen({super.key, required this.medication});

  @override
  ConsumerState<MedicationDetailScreen> createState() =>
      _MedicationDetailScreenState();
}

class _MedicationDetailScreenState
    extends ConsumerState<MedicationDetailScreen> {
  late TextEditingController _notesController;
  Timer? _debounceTimer;
  final ValueNotifier<bool> _hasNotesText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.medication.personalNotes ?? '',
    );
    _hasNotesText.value = widget.medication.personalNotes?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _notesController.dispose();
    _hasNotesText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationProvider);
    final conditionsAsync = ref.watch(conditionsProvider);
    final notebookAsync = ref.watch(notebookProvider);

    final medications = medicationsAsync.value ?? [];
    final conditions = conditionsAsync.value ?? [];

    // Get the current medication state (might have been updated)
    final currentMed = medications.firstWhere(
      (m) => m.id == widget.medication.id,
      orElse: () => widget.medication,
    );

    final conditionDisplayNames = ConditionHelper.getDisplayNames(
      conditionNames: currentMed.conditionNames,
      conditions: conditions,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(currentMed.name),
          actions: [
            AppMoreMenu(
              additionalItems: [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20),
                      SizedBox(width: 12),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditDialog(currentMed);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(currentMed);
                    break;
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(currentMed, conditionDisplayNames),
            Scaffold(
              body: _buildNotesTab(currentMed, notebookAsync),
              floatingActionButton: ValueListenableBuilder<bool>(
                valueListenable: _hasNotesText,
                builder: (context, hasText, child) {
                  return hasText
                      ? FloatingActionButton.extended(
                          onPressed: () => _saveToNotebook(currentMed),
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    Medication medication,
    List<String> conditionDisplayNames,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(medicationProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medication info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medication,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medication.dosage,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (medication.isPRN)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PRN',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Conditions section
          Text(
            'Conditions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (conditionDisplayNames.isEmpty)
                    Text(
                      'No conditions linked',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ...conditionDisplayNames.map(
                      (name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.healing,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(name, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Schedule section (formerly Summary + Schedule)
          if (medication.isPRN) ...[
            // PRN dose tracking
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Take as needed (PRN)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Maximum ${medication.maxDailyDoses ?? "unlimited"} doses per day',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),

                    // Dose counter
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Doses taken today',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${medication.currentDoseCount}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (medication.maxDailyDoses != null)
                            Text(
                              'of ${medication.maxDailyDoses} max',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: medication.currentDoseCount > 0
                                    ? () => notifier.decrementDoseCount(
                                        medication,
                                      )
                                    : null,
                                icon: const Icon(Icons.remove),
                                label: const Text('Decrease'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: () =>
                                    notifier.incrementDoseCount(medication),
                                icon: const Icon(Icons.add),
                                label: const Text('Add dose'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: medication.currentDoseCount > 0
                                ? () => notifier.resetDoseCount(medication)
                                : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset count'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Scheduled times
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Scheduled Times',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (medication.scheduledTimes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 48,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No times scheduled',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Edit this medication to add scheduled times',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...medication.scheduledTimes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final time = entry.value;
                        return Column(
                          children: [
                            if (index > 0) const Divider(height: 1),
                            ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                              title: Text(
                                TimeFormattingUtils.formatTime(time),
                                style: theme.textTheme.titleMedium,
                              ),
                              trailing: Icon(
                                Icons.access_time,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(Medication medication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MedicationEditSheet(medication: medication),
    );
  }

  void _showDeleteConfirmation(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(medicationProvider.notifier)
                  .deleteMeds(medication);
              if (!context.mounted) return;
              Navigator.of(context).pop(); // Close dialog
              if (!context.mounted) return;
              Navigator.of(context).pop(); // Go back to list
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${medication.name} deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(
    Medication medication,
    AsyncValue<List<NotebookEntry>> notebookAsync,
  ) {
    final theme = Theme.of(context);

    final entries =
        notebookAsync.value
            ?.where((e) => e.sourceCode == medication.id && e.sourceType == 1)
            .toList() ??
        [];
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Quick Notes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scratchpad for temporary thoughts',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Write your notes here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
          ),
          onChanged: (value) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
              ref
                  .read(medicationProvider.notifier)
                  .updateMedicationNotes(medication.id, value);
            });
            _hasNotesText.value = value.isNotEmpty;
          },
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            'Note History',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.map((entry) => _buildHistoryNoteCard(entry)),
        ],
      ],
    );
  }

  Widget _buildHistoryNoteCard(NotebookEntry entry) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy - HH:mm').format(entry.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _confirmDeleteNote(entry),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.content, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteNote(NotebookEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notebookProvider.notifier).deleteEntry(entry.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Note deleted')));
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToNotebook(Medication medication) async {
    final content = _notesController.text;
    if (content.isEmpty) return;

    final entry = NotebookEntry(
      id: const Uuid().v4(),
      sourceType: 1, // medication
      sourceName: medication.name,
      sourceCode: medication.id,
      content: content,
      timestamp: DateTime.now(),
    );

    await ref.read(notebookProvider.notifier).addEntry(entry);

    // Clear the notes field
    _notesController.clear();
    await ref
        .read(medicationProvider.notifier)
        .updateMedicationNotes(medication.id, '');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved in notebook in profile')),
      );
      _hasNotesText.value = false;
    }
  }
}
