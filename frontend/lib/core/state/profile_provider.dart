import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/profile.dart';

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<Profile> {
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

  void addXP(int amount) {
    int newXP = state.xp + amount;
    double newProgress = (newXP % 100) / 100;
    int newStreak = state.streak;
    if (newProgress == 0.0) newStreak += 1;

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
