import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/profile.dart';
import 'adherence_provider.dart';

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<Profile> {
  static const int maxLevel = 100;
  static const int baseXpPerDay = 100;

  @override
  Profile build() {
    _loadProfile();
    return Profile(
      firstName: '',
      dob: '',
      allergies: '',
      xp: 0,
      streak: 0,
      levelProgress: 0.0,
      lastXpAwardDate: null,
      lastPopupShownDate: null,
      lastXpGained: 0,
      lastName: '',
    );
  }

  Future<void> _loadProfile() async {
    final key = await EncryptionMigrationService.getEncryptionKey();

    final box = await Hive.openBox(
      'profile',
      encryptionCipher: HiveAesCipher(key),
      );
    final saved = box.get('user');
    if (saved != null && saved is Profile) {
      state = saved;
    } else {
      // Create a default profile if none exists
      final defaultProfile = Profile(
        firstName: 'John',
        lastName: 'Smith',
        dob: '04/19/1985',
        allergies: 'None',
        xp: 0,
        streak: 0,
        levelProgress: 0.0,
        lastXpAwardDate: null,
        lastPopupShownDate: null,
        lastXpGained: 0,
      );
      await box.put('user', defaultProfile);
      state = defaultProfile;
    }
    // Check and award XP for yesterday when profile loads
    await checkAndAwardDailyXp();
  }

  Future<void> save(Profile p) async {
    final box = await Hive.openBox('profile');
    await box.put('user', p);
    state = p;
  }

  /// Calculate current level from total XP
  /// Formula: level = floor((-1 + sqrt(1 + 8*XP/100)) / 2)
  /// Capped at maxLevel
  int getCurrentLevel(int xp) {
    if (xp == 0) return 0;
    final level = ((-1 + sqrt(1 + 8 * xp / 100)) / 2).floor();
    return level > maxLevel ? maxLevel : level;
  }

  /// Calculate total XP required to reach a specific level
  /// Formula: XP = 100 * level * (level + 1) / 2
  int getXpForLevel(int level) {
    return 100 * level * (level + 1) ~/ 2;
  }

  /// Calculate XP needed for next level
  int getXpForNextLevel(int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    return (currentLevel + 1) * 100;
  }

  /// Check if two DateTime objects are on the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check and award XP for any missed days
  ///
  /// This method:
  /// - Checks if XP has already been awarded today
  /// - Awards XP for yesterday if not already done
  /// - Should be called when app opens or at midnight
  Future<void> checkAndAwardDailyXp() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If we've already awarded XP today, skip
    if (state.lastXpAwardDate != null &&
        _isSameDay(state.lastXpAwardDate!, today)) {
      return;
    }

    // Award XP for yesterday (if we haven't already)
    final yesterday = today.subtract(const Duration(days: 1));

    if (state.lastXpAwardDate == null ||
        !_isSameDay(state.lastXpAwardDate!, yesterday)) {
      await awardDailyXp(yesterday);
    }
  }

  /// Award XP for a specific day based on medication adherence
  ///
  /// XP Calculation:
  /// 1. Base XP = 100 * (adherence percentage / 100)
  ///    - 100% adherence = 100 XP
  ///    - 80% adherence = 80 XP
  ///    - 50% adherence = 50 XP
  ///
  /// 2. Streak Multiplier = 1 + (0.01 * streak_days)
  ///    - Day 1 streak: 1.01x (101 XP for perfect adherence)
  ///    - Day 2 streak: 1.02x (102 XP for perfect adherence)
  ///    - Day 30 streak: 1.30x (130 XP for perfect adherence)
  ///
  /// 3. Final XP = Base XP * Streak Multiplier
  ///
  /// Examples:
  /// - Day 1, 100% adherence: 100 * 1.01 = 101 XP
  /// - Day 5, 80% adherence: 80 * 1.05 = 84 XP
  /// - Day 30, 100% adherence: 100 * 1.30 = 130 XP
  Future<void> awardDailyXp(DateTime date) async {
    final adherenceNotifier = ref.read(adherenceProvider.notifier);

    // Get adherence for the specific day
    final dailyAdherence = await adherenceNotifier.getDailyAdherence(date);
    final logs = await adherenceNotifier.getLogsForDate(date);

    // Don't award XP if there were no medications scheduled
    if (logs.isEmpty) {
      return;
    }

    // Calculate base XP based on adherence percentage
    // If 100% adherence, get full 100 XP
    // If 80% adherence, get 80 XP, etc.
    final baseXp = ((dailyAdherence / 100) * baseXpPerDay).round();

    // Get current adherence streak
    final adherenceStreak = await adherenceNotifier.getCurrentStreak();

    // Apply streak multiplier: 1 + (0.01 * streak_days)
    // Day 1: 1.01x, Day 2: 1.02x, Day 30: 1.30x
    final streakMultiplier = 1.0 + (0.01 * adherenceStreak);
    final finalXp = (baseXp * streakMultiplier).round();

    // Add XP and update streak
    addXP(finalXp, newStreak: adherenceStreak);

    // Update last award date and store XP gained for popup
    final updated = state.copyWith(
      lastXpAwardDate: date,
      lastXpGained: finalXp,
    );
    save(updated);
  }

  /// Add XP and update level progress
  void addXP(int amount, {int? newStreak}) {
    int newXP = state.xp + amount;
    int newLevel = getCurrentLevel(newXP);

    // Calculate progress to next level
    double newProgress = 0.0;
    if (newLevel < maxLevel) {
      int xpForCurrentLevel = getXpForLevel(newLevel);
      int xpForNextLevel = getXpForNextLevel(newLevel);
      int xpIntoCurrentLevel = newXP - xpForCurrentLevel;
      newProgress = xpIntoCurrentLevel / xpForNextLevel;
    } else {
      newProgress = 1.0; // Max level reached
    }

    final updated = state.copyWith(
      xp: newXP,
      streak: newStreak ?? state.streak,
      levelProgress: newProgress,
    );
    save(updated);
  }

  void resetProgress() {
    final updated = state.copyWith(
      streak: 0,
      xp: 0,
      levelProgress: 0.0,
      lastXpAwardDate: null,
    );
    save(updated);
  }

  /// Check if we should show the XP gain popup
  ///
  /// Returns true if:
  /// - We haven't shown the popup today
  /// - XP was gained yesterday (lastXpGained > 0)
  bool shouldShowXpPopup() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If we've already shown the popup today, don't show it again
    if (state.lastPopupShownDate != null &&
        _isSameDay(state.lastPopupShownDate!, today)) {
      return false;
    }

    // Show popup if XP was gained
    return state.lastXpGained > 0;
  }

  /// Mark the popup as shown for today
  Future<void> markPopupShown() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final updated = state.copyWith(lastPopupShownDate: today);
    await save(updated);
  }
}
