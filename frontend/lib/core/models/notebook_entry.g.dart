// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notebook_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotebookEntryAdapter extends TypeAdapter<NotebookEntry> {
  @override
  final int typeId = 9;

  @override
  NotebookEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotebookEntry(
      id: fields[0] as String,
      sourceType: fields[1] as int,
      sourceName: fields[2] as String,
      sourceCode: fields[3] as String,
      content: fields[4] as String,
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotebookEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourceType)
      ..writeByte(2)
      ..write(obj.sourceName)
      ..writeByte(3)
      ..write(obj.sourceCode)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotebookEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
