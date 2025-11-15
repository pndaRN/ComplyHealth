import 'package:hive/hive.dart';

part 'feedback.g.dart';

@HiveType(typeId: 5)
class Feedback {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final bool synced;

  const Feedback({
    required this.id,
    required this.type,
    required this.subject,
    required this.message,
    required this.timestamp,
    required this.synced,
  });

  Feedback copyWith({
    String? id,
    String? type,
    String? subject,
    String? message,
    DateTime? timestamp,
    bool? synced,
  }) {
    return Feedback(
      id: id ?? this.id,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'subject': subject,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
