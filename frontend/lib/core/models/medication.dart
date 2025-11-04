import 'package:hive/hive.dart';

part 'medication.g.dart';

@HiveType(typeId: 1, adapterName: 'MedicationAdapterGenerated')
class Medication {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String dosage;
  @HiveField(3)
  final String frequency;
  @HiveField(4, defaultValue: <String>[])
  final List<String> conditionNames;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.conditionNames = const [],
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    dosage: json['doseage'] ?? '',
    frequency: json['frequency'] ?? '',
    conditionNames: json['conditionNames'] != null
        ? List<String>.from(json['conditionNames'])
        : [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'conditionNames': conditionNames,
  };
}

/// Custom adapter that handles migration from single condition to multiple conditions
class MedicationAdapterCustom extends TypeAdapter<Medication> {
  @override
  final int typeId = 1;

  @override
  Medication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Handle migration from String (old) to List<String> (new)
    List<String> conditionNames;
    if (fields[4] == null) {
      conditionNames = [];
    } else if (fields[4] is String) {
      // Old format: single condition as String
      conditionNames = [fields[4] as String];
    } else if (fields[4] is List) {
      // New format: multiple conditions as List
      conditionNames = (fields[4] as List).cast<String>();
    } else {
      conditionNames = [];
    }

    return Medication(
      id: fields[0] as String,
      name: fields[1] as String,
      dosage: fields[2] as String,
      frequency: fields[3] as String,
      conditionNames: conditionNames,
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dosage)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.conditionNames);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationAdapterCustom &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
