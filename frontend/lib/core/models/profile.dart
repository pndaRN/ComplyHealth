import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 2)
class Profile {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String dob;

  @HiveField(2)
  final String allergies;

  @HiveField(3)
  final int xp;

  @HiveField(4)
  final int streak;

  @HiveField(5)
  final double levelProgress;

  @HiveField(6)
  final DateTime? lastXpAwardDate;

  const Profile({
    required this.name,
    required this.dob,
    required this.allergies,
    required this.xp,
    required this.streak,
    required this.levelProgress,
    this.lastXpAwardDate,
  });

  Profile copyWith({
    String? name,
    String? dob,
    String? allergies,
    int? xp,
    int? streak,
    double? levelProgress,
    DateTime? lastXpAwardDate,
  }) {
    return Profile(
      name: name ?? this.name,
      dob: dob ?? this.dob,
      allergies: allergies ?? this.allergies,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      levelProgress: levelProgress ?? this.levelProgress,
      lastXpAwardDate: lastXpAwardDate ?? this.lastXpAwardDate,
    );
  }
}
