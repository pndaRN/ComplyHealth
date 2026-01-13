// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationLogAdapter extends TypeAdapter<MedicationLog> {
  @override
  final int typeId = 4;

  @override
  MedicationLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationLog(
      id: fields[0] as String?,
      medicationId: fields[1] as String,
      medicationName: fields[2] as String,
      scheduledTime: fields[3] as DateTime,
      actualTakenTime: fields[4] as DateTime?,
      status: fields[5] as DoseStatus,
      notes: fields[6] as String?,
      dosage: fields[7] as String,
      skipReason: fields[8] as String?,
      isDismissed: fields[9] == null ? false : fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicationId)
      ..writeByte(2)
      ..write(obj.medicationName)
      ..writeByte(3)
      ..write(obj.scheduledTime)
      ..writeByte(4)
      ..write(obj.actualTakenTime)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.dosage)
      ..writeByte(8)
      ..write(obj.skipReason)
      ..writeByte(9)
      ..write(obj.isDismissed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DoseStatusAdapter extends TypeAdapter<DoseStatus> {
  @override
  final int typeId = 3;

  @override
  DoseStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DoseStatus.taken;
      case 1:
        return DoseStatus.skipped;
      case 2:
        return DoseStatus.missed;
      default:
        return DoseStatus.taken;
    }
  }

  @override
  void write(BinaryWriter writer, DoseStatus obj) {
    switch (obj) {
      case DoseStatus.taken:
        writer.writeByte(0);
        break;
      case DoseStatus.skipped:
        writer.writeByte(1);
        break;
      case DoseStatus.missed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
