import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import '../models/notebook_entry.dart';
import '../services/encryption_migration_service.dart';
import '../../core/state/auth_provider.dart';

enum NotebookSortOption { chronological, bySource }

final notebookProvider =
    AsyncNotifierProvider<NotebookNotifier, List<NotebookEntry>>(
      NotebookNotifier.new,
    );

class NotebookNotifier extends AsyncNotifier<List<NotebookEntry>> {
  NotebookSortOption _sortOption = NotebookSortOption.chronological;

  NotebookSortOption get sortOption => _sortOption;

  Future<Box<NotebookEntry>> _getBox() async {
    final key = await EncryptionMigrationService.getEncryptionKey();
    if (Hive.isBoxOpen('notebook')) {
      try {
        try {
          final box = Hive.box<NotebookEntry>('notebook');
          return box;
        } catch (_) {
          final box = Hive.box('notebook');
          await box.close();
        }
      } catch (_) {
        try {
          final box = await Hive.openBox('notebook');
          await box.close();
        } catch (_) {}
      }
    }
    return await Hive.openBox<NotebookEntry>(
      'notebook',
      encryptionCipher: HiveAesCipher(key),
    );
  }

  List<NotebookEntry> _applySorting(List<NotebookEntry> entries) {
    final sorted = List<NotebookEntry>.from(entries);
    if (_sortOption == NotebookSortOption.chronological) {
      sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      sorted.sort((a, b) {
        final typeCompare = a.sourceType.compareTo(b.sourceType);
        if (typeCompare != 0) return typeCompare;
        final nameCompare = a.sourceName.compareTo(b.sourceName);
        if (nameCompare != 0) return nameCompare;
        return b.timestamp.compareTo(a.timestamp);
      });
    }
    return sorted;
  }

  @override
  Future<List<NotebookEntry>> build() async {
    final box = await _getBox();
    return _applySorting(box.values.toList());
  }

  Future<void> addEntry(NotebookEntry entry) async {
    state = const AsyncValue.loading();
    try {
      final box = await _getBox();
      await box.put(entry.id, entry);
      state = AsyncValue.data(_applySorting(box.values.toList()));
      _syncEntry(entry);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    try {
      final box = await _getBox();
      await box.delete(id);
      state = AsyncValue.data(_applySorting(box.values.toList()));
      _syncDeleteEntry(id);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void _syncEntry(NotebookEntry entry) {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    ref.read(syncServiceProvider).syncNotebookEntry(uid, entry);
  }

  void _syncDeleteEntry(String id) {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    ref.read(syncServiceProvider).deleteNotebookEntryRemote(uid, id);
  }

  Future<void> setSortOption(NotebookSortOption option) async {
    _sortOption = option;
    final box = await _getBox();
    state = AsyncValue.data(_applySorting(box.values.toList()));
  }

  Map<String, List<NotebookEntry>> getEntriesGroupedBySource(
    List<NotebookEntry> entries,
  ) {
    final grouped = <String, List<NotebookEntry>>{};
    for (final entry in entries) {
      final key = '${entry.sourceType}:${entry.sourceName}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }
}
