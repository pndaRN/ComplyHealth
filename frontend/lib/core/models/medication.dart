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
  @HiveField(4, defaultValue: <String>[])
  final List<String> conditionNames;
  @HiveField(5, defaultValue: false)
  final bool isPRN;
  @HiveField(6, defaultValue: <String>[])
  final List<String> scheduledTimes; // Stored as "HH:mm" format
  @HiveField(7)
  final int? maxDailyDoses;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    this.conditionNames = const [],
    this.isPRN = false,
    this.scheduledTimes = const [],
    this.maxDailyDoses,
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    dosage: json['doseage'] ?? '',
    conditionNames: json['conditionNames'] != null
        ? List<String>.from(json['conditionNames'])
        : [],
    isPRN: json['isPRN'] ?? false,
    scheduledTimes: json['scheduledTimes'] != null
        ? List<String>.from(json['scheduledTimes'])
        : [],
    maxDailyDoses: json['maxDailyDoses'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'conditionNames': conditionNames,
    'isPRN': isPRN,
    'scheduledTimes': scheduledTimes,
    'maxDailyDoses': maxDailyDoses,
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

    // Handle new timing fields with defaults for old data
    final isPRN = fields[5] as bool? ?? false;

    List<String> scheduledTimes;
    if (fields[6] == null) {
      scheduledTimes = [];
    } else if (fields[6] is List) {
      scheduledTimes = (fields[6] as List).cast<String>();
    } else {
      scheduledTimes = [];
    }

    final maxDailyDoses = fields[7] as int?;

    return Medication(
      id: fields[0] as String,
      name: fields[1] as String,
      dosage: fields[2] as String,
      conditionNames: conditionNames,
      isPRN: isPRN,
      scheduledTimes: scheduledTimes,
      maxDailyDoses: maxDailyDoses,
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(7) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dosage)
      ..writeByte(4)
      ..write(obj.conditionNames)
      ..writeByte(5)
      ..write(obj.isPRN)
      ..writeByte(6)
      ..write(obj.scheduledTimes)
      ..writeByte(7)
      ..write(obj.maxDailyDoses);
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
