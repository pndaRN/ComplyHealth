import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import '../models/profile.dart';
import 'adherence_provider.dart';
import '../../core/services/encryption_migration_service.dart';
import '../../core/state/auth_provider.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<Profile> {
  static const String _boxName = 'profile';
  static const int maxLevel = 100;
  static const int baseXpPerDay = 100;

  Future<Box<Profile>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      try {
        try {
          final box = Hive.box<Profile>(_boxName);
          return box;
        } catch (_) {
          final box = Hive.box(_boxName);
          await box.close();
        }
      } catch (_) {
        try {
          final box = await Hive.openBox(_boxName);
          await box.close();
        } catch (_) {}
      }
    }
    final key = await EncryptionMigrationService.getEncryptionKey();
    try {
      return await Hive.openBox<Profile>(
        _boxName,
        encryptionCipher: HiveAesCipher(key),
      );
    } catch (e) {
      debugPrint('Failed to open $_boxName: $e - clearing and retrying');
      // Clear corrupted box
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {}
      // Open fresh empty box
      return await Hive.openBox<Profile>(
        _boxName,
        encryptionCipher: HiveAesCipher(key),
      );
    }
  }

  @override
  Future<Profile> build() async {
    final box = await _getBox();
    Profile? profile = box.get('user');

    if (profile == null) {
      profile = Profile(
        firstName: '',
        dob: '',
        allergies: '',
        xp: 0,
        streak: 0,
        levelProgress: 0.0,
        lastName: '',
      );
      await box.put('user', profile);
    }

    // Run XP check in background after initial load with error handling
    checkAndAwardDailyXp().catchError((e) {
      // Silently handle errors - XP award is not critical for app function
    });

    return profile;
  }

  Future<void> save(Profile p) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      await box.put('user', p);
      return p;
    });
    _syncProfile(p);
  }

  void _syncProfile(Profile profile) {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    ref.read(syncServiceProvider).syncProfile(uid, profile);
  }

  int getCurrentLevel(int xp) {
    if (xp == 0) return 0;
    final level = ((-1 + sqrt(1 + 8 * xp / 100)) / 2).floor();
    return level > maxLevel ? maxLevel : level;
  }

  int getXpForLevel(int level) {
    return 100 * level * (level + 1) ~/ 2;
  }

  int getXpForNextLevel(int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    return (currentLevel + 1) * 100;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> checkAndAwardDailyXp() async {
    final profile = state.value;
    if (profile == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (profile.lastXpAwardDate != null &&
        _isSameDay(profile.lastXpAwardDate!, today)) {
      return;
    }

    final yesterday = today.subtract(const Duration(days: 1));

    if (profile.lastXpAwardDate == null ||
        !_isSameDay(profile.lastXpAwardDate!, yesterday)) {
      await awardDailyXp(yesterday);
    }
  }

  Future<void> awardDailyXp(DateTime date) async {
    final profile = state.value;
    if (profile == null) return;

    final adherenceNotifier = ref.read(adherenceProvider.notifier);
    final dailyAdherence = await adherenceNotifier.getDailyAdherence(date);
    final logs = await adherenceNotifier.getLogsForDate(date);

    if (logs.isEmpty) return;

    int bonusXp = 0;
    final adherenceStreak = await adherenceNotifier.getCurrentStreak();

    // Award "Perfect Day" bonus only if 100% adherence was achieved
    if (dailyAdherence >= 100.0) {
      // Base bonus is 50 XP, plus 2 XP for every day of the current streak
      bonusXp = 50 + (adherenceStreak * 2);
      await addXP(bonusXp, newStreak: adherenceStreak);
    }

    final currentProfile = state.value;
    if (currentProfile == null) return;

    // Always update last award date and streak to prevent re-processing
    final updated = currentProfile.copyWith(
      lastXpAwardDate: date,
      lastXpGained: bonusXp,
      streak: adherenceStreak,
    );
    await save(updated);
  }

  Future<void> addXP(int amount, {int? newStreak}) async {
    final profile = state.value;
    if (profile == null) return;

    int newXP = profile.xp + amount;
    int newLevel = getCurrentLevel(newXP);
    double newProgress = 0.0;

    if (newLevel < maxLevel) {
      int xpForCurrentLevel = getXpForLevel(newLevel);
      int xpForNextLevel = getXpForNextLevel(newLevel);
      int xpIntoCurrentLevel = newXP - xpForCurrentLevel;
      newProgress = xpIntoCurrentLevel / xpForNextLevel;
    } else {
      newProgress = 1.0;
    }

    final updated = profile.copyWith(
      xp: newXP,
      streak: newStreak ?? profile.streak,
      levelProgress: newProgress,
    );
    await save(updated);
  }

  Future<void> resetProgress() async {
    final profile = state.value;
    if (profile == null) return;

    final updated = profile.copyWith(
      streak: 0,
      xp: 0,
      levelProgress: 0.0,
      lastXpAwardDate: null,
    );
    await save(updated);
  }

  bool shouldShowXpPopup() {
    final profile = state.value;
    if (profile == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (profile.lastPopupShownDate != null &&
        _isSameDay(profile.lastPopupShownDate!, today)) {
      return false;
    }
    return profile.lastXpGained > 0;
  }

  Future<void> markPopupShown() async {
    final profile = state.value;
    if (profile == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final updated = profile.copyWith(lastPopupShownDate: today);
    await save(updated);
  }
}
