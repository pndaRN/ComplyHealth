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
  final String conditionName;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.conditionName,
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    dosage: json['doseage'] ?? '',
    frequency: json['frequency'] ?? '',
    conditionName: json['conditionName'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'conditionName': conditionName,
  };
}
