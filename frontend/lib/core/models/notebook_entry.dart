import 'package:hive_ce/hive_ce.dart';

part 'notebook_entry.g.dart';

enum NoteSourceType {
  condition,
  medication,
}

@HiveType(typeId: 9)
class NotebookEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int sourceType; // 0 = condition, 1 = medication

  @HiveField(2)
  final String sourceName;

  @HiveField(3)
  final String sourceCode;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final DateTime timestamp;

  NotebookEntry({
    required this.id,
    required this.sourceType,
    required this.sourceName,
    required this.sourceCode,
    required this.content,
    required this.timestamp,
  });

  NoteSourceType get sourceTypeEnum =>
      sourceType == 0 ? NoteSourceType.condition : NoteSourceType.medication;

  NotebookEntry copyWith({
    String? id,
    int? sourceType,
    String? sourceName,
    String? sourceCode,
    String? content,
    DateTime? timestamp,
  }) {
    return NotebookEntry(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceName: sourceName ?? this.sourceName,
      sourceCode: sourceCode ?? this.sourceCode,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceType': sourceType,
        'sourceName': sourceName,
        'sourceCode': sourceCode,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NotebookEntry.fromJson(Map<String, dynamic> json) => NotebookEntry(
        id: json['id'] ?? '',
        sourceType: json['sourceType'] ?? 0,
        sourceName: json['sourceName'] ?? '',
        sourceCode: json['sourceCode'] ?? '',
        content: json['content'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );
}
