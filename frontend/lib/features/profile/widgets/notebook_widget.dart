import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/notebook_entry.dart';
import '../../../core/state/notebook_provider.dart';

class NotebookWidget extends ConsumerWidget {
  const NotebookWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebookAsync = ref.watch(notebookProvider);
    final sortOption = ref.read(notebookProvider.notifier).sortOption;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notebook',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DropdownButton<NotebookSortOption>(
                  value: sortOption,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort),
                  items: const [
                    DropdownMenuItem(
                      value: NotebookSortOption.chronological,
                      child: Text('By Date'),
                    ),
                    DropdownMenuItem(
                      value: NotebookSortOption.bySource,
                      child: Text('By Condition'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(notebookProvider.notifier).setSortOption(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            notebookAsync.when(
              data: (entries) => _buildContent(context, ref, entries, sortOption),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<NotebookEntry> entries,
    NotebookSortOption sortOption,
  ) {
    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }

    if (sortOption == NotebookSortOption.chronological) {
      return _buildChronologicalList(context, ref, entries);
    } else {
      return _buildGroupedList(context, ref, entries);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.note_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No notes yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save notes from your conditions or medications',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChronologicalList(
    BuildContext context,
    WidgetRef ref,
    List<NotebookEntry> entries,
  ) {
    return Column(
      children: entries.map((entry) => _buildNoteCard(context, ref, entry)).toList(),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<NotebookEntry> entries,
  ) {
    final grouped = ref.read(notebookProvider.notifier).getEntriesGroupedBySource(entries);
    final theme = Theme.of(context);

    return Column(
      children: grouped.entries.map((entry) {
        final sourceName = entry.value.first.sourceName;
        final sourceType = entry.value.first.sourceTypeEnum;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: ExpansionTile(
            leading: Icon(
              sourceType == NoteSourceType.condition
                  ? Icons.health_and_safety
                  : Icons.medication,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              sourceName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${entry.value.length} note${entry.value.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            children: entry.value.map((note) {
              return _buildNoteListItem(context, ref, note);
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteCard(BuildContext context, WidgetRef ref, NotebookEntry entry) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd-MM-yyyy').format(entry.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showNoteDetail(context, ref, entry),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    entry.sourceTypeEnum == NoteSourceType.condition
                        ? Icons.health_and_safety
                        : Icons.medication,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entry.sourceName} - $dateStr',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () => _confirmDelete(context, ref, entry),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteListItem(BuildContext context, WidgetRef ref, NotebookEntry entry) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd-MM-yyyy').format(entry.timestamp);

    return ListTile(
      title: Text(
        dateStr,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        entry.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          size: 20,
          color: theme.colorScheme.error,
        ),
        onPressed: () => _confirmDelete(context, ref, entry),
      ),
      onTap: () => _showNoteDetail(context, ref, entry),
    );
  }

  void _showNoteDetail(BuildContext context, WidgetRef ref, NotebookEntry entry) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd-MM-yyyy HH:mm').format(entry.timestamp);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              entry.sourceTypeEnum == NoteSourceType.condition
                  ? Icons.health_and_safety
                  : Icons.medication,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.sourceName,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                entry.content,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete(context, ref, entry);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, NotebookEntry entry) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(notebookProvider.notifier).deleteEntry(entry.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note deleted')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
