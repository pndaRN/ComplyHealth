import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/notebook_entry.dart';
import '../../../core/state/notebook_provider.dart';
import '../../../core/state/conditions_provider.dart';
import '../../../core/state/medication_provider.dart';
import '../../../core/utils/adaptive_dialog.dart';

/// Dialog for creating a new notebook entry
class NoteCreationDialog extends ConsumerStatefulWidget {
  const NoteCreationDialog({super.key});

  @override
  ConsumerState<NoteCreationDialog> createState() => _NoteCreationDialogState();
}

class _NoteCreationDialogState extends ConsumerState<NoteCreationDialog> {
  static const Uuid _uuid = Uuid();

  late final TextEditingController _contentController;
  NoteSourceType _selectedSourceType = NoteSourceType.condition;
  String? _selectedSourceId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.note_add,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create New Note',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Source Type Selection
              Text(
                'Note Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      label: const Text('Condition'),
                      selected: _selectedSourceType == NoteSourceType.condition,
                      onSelected: _isSubmitting
                          ? null
                          : (value) {
                              if (value == true) {
                                setState(() {
                                  _selectedSourceType =
                                      NoteSourceType.condition;
                                  _selectedSourceId = null;
                                });
                              }
                            },
                      avatar: Icon(
                        Icons.health_and_safety,
                        size: 18,
                        color: _selectedSourceType == NoteSourceType.condition
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilterChip(
                      label: const Text('Medication'),
                      selected:
                          _selectedSourceType == NoteSourceType.medication,
                      onSelected: _isSubmitting
                          ? null
                          : (value) {
                              if (value == true) {
                                setState(() {
                                  _selectedSourceType =
                                      NoteSourceType.medication;
                                  _selectedSourceId = null;
                                });
                              }
                            },
                      avatar: Icon(
                        Icons.medication,
                        size: 18,
                        color: _selectedSourceType == NoteSourceType.medication
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Source Selection Dropdown
              FutureBuilder<List<dynamic>>(
                future: _getSourcesForType(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return DropdownButtonFormField<String>(
                      initialValue: null,
                      items: const [],
                      onChanged: null,
                      decoration: const InputDecoration(
                        labelText: 'Loading...',
                        border: OutlineInputBorder(),
                      ),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return DropdownButtonFormField<String>(
                      initialValue: null,
                      items: const [],
                      onChanged: null,
                      decoration: InputDecoration(
                        labelText: 'No ${_selectedSourceType.name}s available',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          _selectedSourceType == NoteSourceType.condition
                              ? Icons.health_and_safety
                              : Icons.medication,
                        ),
                        helperText: 'Add ${_selectedSourceType.name}s first',
                      ),
                    );
                  }

                  final sources = snapshot.data!;
                  final selectedSource = _selectedSourceId != null
                      ? sources.cast<Object?>().firstWhere(
                          (source) => source != null && _getSourceIdentifier(source) == _selectedSourceId,
                          orElse: () => null,
                        )
                      : null;

                  return DropdownButtonFormField<dynamic>(
                    initialValue: selectedSource,
                    decoration: InputDecoration(
                      labelText: 'Select ${_selectedSourceType.name}',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        _selectedSourceType == NoteSourceType.condition
                            ? Icons.health_and_safety
                            : Icons.medication,
                      ),
                    ),
                    items: sources.map((source) {
                      return DropdownMenuItem<dynamic>(
                        value: source,
                        child: Text(source.name),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() => _selectedSourceId = value != null ? _getSourceIdentifier(value) : null);
                          },
                  );
                },
              ),
              const SizedBox(height: 20),

              // Note Content
              TextFormField(
                controller: _contentController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Note Content',
                  hintText: 'Enter your note here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter note content';
                  }
                  if (value.trim().length < 3) {
                    return 'Note must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_isSubmitting || _selectedSourceId == null)
                          ? null
                          : _createNote,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> _getSourcesForType() async {
    if (_selectedSourceType == NoteSourceType.condition) {
      final conditions = await ref.read(conditionsProvider.future);
      return conditions;
    } else {
      final medications = ref.read(medicationProvider);
      return medications.value ?? [];
    }
  }

  /// Gets the identifier for a source (code for conditions, id for medications)
  String _getSourceIdentifier(dynamic source) {
    if (_selectedSourceType == NoteSourceType.condition) {
      return source.code;
    } else {
      return source.id;
    }
  }

  Future<void> _createNote() async {
    if (_selectedSourceId == null || _contentController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get the selected source
      final sources = await _getSourcesForType();
      final selectedSource = sources.firstWhere(
        (source) => _getSourceIdentifier(source) == _selectedSourceId,
      );

      // Create the notebook entry
      String sourceCode;
      if (_selectedSourceType == NoteSourceType.condition) {
        sourceCode = selectedSource.code;
      } else {
        // For medications, use the ID as the code since they don't have a code field
        sourceCode = selectedSource.id;
      }

      final entry = NotebookEntry(
        id: _uuid.v4(),
        sourceType: _selectedSourceType == NoteSourceType.condition ? 0 : 1,
        sourceName: selectedSource.name,
        sourceCode: sourceCode,
        content: _contentController.text.trim(),
        timestamp: DateTime.now(),
      );

      // Save the entry
      await ref.read(notebookProvider.notifier).addEntry(entry);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating note: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Shows the note creation dialog with adaptive behavior
Future<void> showNoteCreationDialog(BuildContext context) {
  return AdaptiveDialog.show(
    context: context,
    builder: (context) => const NoteCreationDialog(),
  );
}
