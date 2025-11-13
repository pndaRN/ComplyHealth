// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'education_content.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EducationContentAdapter extends TypeAdapter<EducationContent> {
  @override
  final int typeId = 6;

  @override
  EducationContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EducationContent(
      conditionCode: fields[0] as String,
      articles: (fields[1] as List).cast<Article>(),
      lifestyleTips: (fields[2] as List).cast<String>(),
      videos: (fields[3] as List).cast<Video>(),
    );
  }

  @override
  void write(BinaryWriter writer, EducationContent obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.conditionCode)
      ..writeByte(1)
      ..write(obj.articles)
      ..writeByte(2)
      ..write(obj.lifestyleTips)
      ..writeByte(3)
      ..write(obj.videos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArticleAdapter extends TypeAdapter<Article> {
  @override
  final int typeId = 7;

  @override
  Article read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Article(
      title: fields[0] as String,
      url: fields[1] as String,
      source: fields[2] as String,
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Article obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VideoAdapter extends TypeAdapter<Video> {
  @override
  final int typeId = 8;

  @override
  Video read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Video(
      title: fields[0] as String,
      url: fields[1] as String,
      thumbnail: fields[2] as String?,
      duration: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Video obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.thumbnail)
      ..writeByte(3)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
