// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedbackAdapter extends TypeAdapter<Feedback> {
  @override
  final int typeId = 5;

  @override
  Feedback read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Feedback(
      id: fields[0] as String,
      type: fields[1] as String,
      subject: fields[2] as String,
      message: fields[3] as String,
      timestamp: fields[4] as DateTime,
      synced: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Feedback obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
