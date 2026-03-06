// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationAdapterGenerated extends TypeAdapter<Medication> {
  @override
  final typeId = 1;

  @override
  Medication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medication(
      id: fields[0] as String,
      name: fields[1] as String,
      dosage: fields[2] as String,
      conditionNames: fields[4] == null
          ? []
          : (fields[4] as List).cast<String>(),
      isPRN: fields[5] == null ? false : fields[5] as bool,
      scheduledTimes: fields[6] == null
          ? []
          : (fields[6] as List).cast<String>(),
      maxDailyDoses: (fields[7] as num?)?.toInt(),
      currentDoseCount: fields[8] == null ? 0 : (fields[8] as num).toInt(),
      lastDoseCountReset: fields[9] as DateTime?,
      personalNotes: fields[10] as String?,
      isTimeSensitive: fields[11] == null ? true : fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.maxDailyDoses)
      ..writeByte(8)
      ..write(obj.currentDoseCount)
      ..writeByte(9)
      ..write(obj.lastDoseCountReset)
      ..writeByte(10)
      ..write(obj.personalNotes)
      ..writeByte(11)
      ..write(obj.isTimeSensitive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationAdapterGenerated &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
