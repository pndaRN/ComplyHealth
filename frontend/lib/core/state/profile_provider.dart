import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/profile.dart';
import 'adherence_provider.dart';
import '../../core/services/encryption_migration_service.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<Profile> {
  static const int maxLevel = 100;
  static const int baseXpPerDay = 100;

  Future<Box<Profile>> _getBox() async {
    if (Hive.isBoxOpen('profile')) {
      try {
        try {
          final box = Hive.box<Profile>('profile');
          return box;
        } catch (_) {
          final box = Hive.box('profile');
          await box.close();
        }
      } catch (_) {
        try {
          final box = await Hive.openBox('profile');
          await box.close();
        } catch (_) {}
      }
    }
    final key = await EncryptionMigrationService.getEncryptionKey();
    return await Hive.openBox<Profile>(
      'profile',
      encryptionCipher: HiveAesCipher(key),
    );
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

    final baseXp = ((dailyAdherence / 100) * baseXpPerDay).round();
    final adherenceStreak = await adherenceNotifier.getCurrentStreak();
    final streakMultiplier = 1.0 + (0.01 * adherenceStreak);
    final finalXp = (baseXp * streakMultiplier).round();

    await addXP(finalXp, newStreak: adherenceStreak);

    final currentProfile = state.value;
    if (currentProfile == null) return;

    final updated = currentProfile.copyWith(
      lastXpAwardDate: date,
      lastXpGained: finalXp,
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
