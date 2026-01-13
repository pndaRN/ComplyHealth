import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/disease.dart';
import '../../core/models/education_content.dart';
import '../../core/services/education_service.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import 'widgets/articles_section.dart';
import 'widgets/lifestyle_tips_section.dart';
import 'widgets/video_section.dart';

class ConditionDetailScreen extends ConsumerStatefulWidget {
  final Disease condition;

  const ConditionDetailScreen({super.key, required this.condition});

  @override
  ConsumerState<ConditionDetailScreen> createState() =>
      _ConditionDetailScreenState();
}

class _ConditionDetailScreenState extends ConsumerState<ConditionDetailScreen> {
  late TextEditingController _notesController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.condition.personalNotes ?? '',
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conditionsAsync = ref.watch(conditionsProvider);
    final displayName = widget.condition.commonName.isNotEmpty
        ? widget.condition.commonName
        : widget.condition.name;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(displayName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Medications'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: conditionsAsync.when(
          data: (conditions) {
            final isAdded = conditions.any(
              (c) => c.code == widget.condition.code,
            );
            return _buildBodyWithData(isAdded);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: conditionsAsync.when(
          data: (conditions) {
            final isAdded = conditions.any(
              (c) => c.code == widget.condition.code,
            );
            return FloatingActionButton.extended(
              onPressed: () => _toggleCondition(isAdded),
              icon: Icon(isAdded ? Icons.remove_circle : Icons.add_circle),
              label: Text(isAdded ? 'Remove' : 'Add to My Conditions'),
            );
          },
          loading: () => FloatingActionButton.extended(
            onPressed: null,
            icon: const CircularProgressIndicator(strokeWidth: 2),
            label: const Text('Loading...'),
          ),
          error: (err, stack) => FloatingActionButton.extended(
            onPressed: null,
            icon: const Icon(Icons.error),
            label: const Text('Error'),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyWithData(bool isAdded) {
    return TabBarView(children: [
      _buildOverviewTab(),
      _buildMedicationsTab(),
      _buildNotesTab(isAdded),
    ]);
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Condition name card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medical Name',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.condition.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (widget.condition.commonName.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Common Name',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.condition.commonName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.condition.category,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ICD-10: ${widget.condition.code}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            'Description',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.condition.description.isNotEmpty
                    ? widget.condition.description
                    : 'No description available.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab() {
    final theme = Theme.of(context);
    final medicationsAsync = ref.watch(medicationProvider);

    return medicationsAsync.when(
      data: (medications) {
        final linkedMedications = medications
            .where((m) => m.conditionNames.contains(widget.condition.name))
            .toList();

        if (linkedMedications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No medications for this condition',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add medications from the Medications tab',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: linkedMedications.length,
          itemBuilder: (context, index) {
            final med = linkedMedications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            med.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (med.isPRN)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PRN',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dosage: ${med.dosage}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      med.isPRN
                          ? 'Take as needed (max ${med.maxDailyDoses} times/day)'
                          : 'Scheduled: ${med.scheduledTimes.length}x daily',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!med.isPRN && med.scheduledTimes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: med.scheduledTimes.map((time) {
                          return Chip(
                            label: Text(time),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildLearnMoreTab() {
    final theme = Theme.of(context);

    return FutureBuilder<EducationContent?>(
      future: EducationService.getContentForCondition(widget.condition.code),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final content = snapshot.data;

        if (content == null) {
          // No content available for this condition
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Educational content coming soon',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Educational resources for ${widget.condition.commonName.isNotEmpty ? widget.condition.commonName : widget.condition.name} will be available here.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Display educational content
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Articles section
              ArticlesSection(articles: content.articles),
              const SizedBox(height: 24),
              // Lifestyle tips section
              LifestyleTipsSection(tips: content.lifestyleTips),
              const SizedBox(height: 24),
              // Videos section
              VideoSection(videos: content.videos),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesTab(bool isAdded) {
    final theme = Theme.of(context);

    if (!isAdded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Add to My Conditions first',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can add notes after adding this condition',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Notes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your own notes about this condition',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Write your notes here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
              ),
              onChanged: (value) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                  ref.read(conditionsProvider.notifier).updateConditionNotes(
                        widget.condition.code,
                        value,
                      );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCondition(bool isCurrentlyAdded) async {
    final notifier = ref.read(conditionsProvider.notifier);

    if (isCurrentlyAdded) {
      await notifier.removeCondition(widget.condition);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed ${widget.condition.commonName.isNotEmpty ? widget.condition.commonName : widget.condition.name}',
            ),
          ),
        );
      }
    } else {
      await notifier.addCondition(widget.condition);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${widget.condition.commonName.isNotEmpty ? widget.condition.commonName : widget.condition.name}',
            ),
          ),
        );
      }
    }
  }
}
