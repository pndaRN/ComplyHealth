import 'package:hive_ce/hive_ce.dart';

part 'profile.g.dart';

@HiveType(typeId: 2)
class Profile {
  @HiveField(0)
  final String firstName;

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

  @HiveField(7)
  final DateTime? lastPopupShownDate;

  @HiveField(8)
  final int lastXpGained;

  @HiveField(9)
  final String lastName;

  const Profile({
    required this.firstName,
    required this.dob,
    required this.allergies,
    required this.xp,
    required this.streak,
    required this.levelProgress,
    this.lastXpAwardDate,
    this.lastPopupShownDate,
    this.lastXpGained = 0,
    required this.lastName,
  });

  Profile copyWith({
    String? firstName,
    String? dob,
    String? allergies,
    int? xp,
    int? streak,
    double? levelProgress,
    DateTime? lastXpAwardDate,
    DateTime? lastPopupShownDate,
    int? lastXpGained,
    String? lastName,
  }) {
    return Profile(
      firstName: firstName ?? this.firstName,
      dob: dob ?? this.dob,
      allergies: allergies ?? this.allergies,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      levelProgress: levelProgress ?? this.levelProgress,
      lastXpAwardDate: lastXpAwardDate ?? this.lastXpAwardDate,
      lastPopupShownDate: lastPopupShownDate ?? this.lastPopupShownDate,
      lastXpGained: lastXpGained ?? this.lastXpGained,
      lastName: lastName ?? this.lastName,
    );
  }
}
