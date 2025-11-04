import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/profile.dart';

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<Profile> {
  static const int maxLevel = 100;

  @override
  Profile build() {
    _loadProfile();
    return Profile(
      name: '',
      dob: '',
      allergies: '',
      xp: 0,
      streak: 0,
      levelProgress: 0.0,
    );
  }

  Future<void> _loadProfile() async {
    final box = await Hive.openBox('profile');
    final saved = box.get('user');
    if (saved != null && saved is Profile) {
      state = saved;
    }
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

  void addXP(int amount) {
    int newXP = state.xp + amount;
    int currentLevel = getCurrentLevel(state.xp);
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

    // Increment streak if leveled up
    int newStreak = state.streak;
    if (newLevel > currentLevel) {
      newStreak += (newLevel - currentLevel);
    }

    final updated = state.copyWith(
      xp: newXP,
      streak: newStreak,
      levelProgress: newProgress,
    );
    save(updated);
  }

  void resetProgress() {
    final updated = state.copyWith(streak: 0, xp: 0, levelProgress: 0.0);
    save(updated);
  }
}
