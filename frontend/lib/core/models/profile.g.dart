// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 2;

  @override
  Profile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Profile(
      name: fields[0] as String,
      dob: fields[1] as String,
      allergies: fields[2] as String,
      xp: fields[3] as int,
      streak: fields[4] as int,
      levelProgress: fields[5] as double,
      lastXpAwardDate: fields[6] as DateTime?,
      lastPopupShownDate: fields[7] as DateTime?,
      lastXpGained: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.dob)
      ..writeByte(2)
      ..write(obj.allergies)
      ..writeByte(3)
      ..write(obj.xp)
      ..writeByte(4)
      ..write(obj.streak)
      ..writeByte(5)
      ..write(obj.levelProgress)
      ..writeByte(6)
      ..write(obj.lastXpAwardDate)
      ..writeByte(7)
      ..write(obj.lastPopupShownDate)
      ..writeByte(8)
      ..write(obj.lastXpGained);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
