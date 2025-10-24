import 'package:hive/hive.dart';

part 'medication.g.dart';

@HiveType(typeId: 1)
class Medication {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String dosage;
  @HiveField(3)
  final String frequency;
  @HiveField(4)
  final String conditionCode;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.conditionCode,
  });
}
