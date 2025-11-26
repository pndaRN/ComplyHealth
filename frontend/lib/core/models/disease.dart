import 'package:hive/hive.dart';

part 'disease.g.dart';

@HiveType(typeId: 0)
class Disease {

    @HiveField(0)
    final String code;

    @HiveField(1)
    final String name;

    @HiveField(2)
    final String category;

    @HiveField(3, defaultValue: '')
    final String commonName;

    @HiveField(4, defaultValue: '')
    final String description;

    @HiveField(5, defaultValue: false)
    final bool isCustom;

    @HiveField(6)
    final String? personalNotes;

    @HiveField(7)
    final DateTime? createdAt;

    Disease({
        required this.code,
        required this.name,
        required this.category,
        this.commonName = '',
        this.description = '',
        this.isCustom = false,
        this.personalNotes,
        this.createdAt,
      });

    factory Disease.fromJson(Map<String, dynamic> json) => Disease (
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      commonName: json['commonName'] ?? '',
      description: json['description'] ?? '',
      isCustom: json['isCustom'] ?? false,
      personalNotes: json['personalNotes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );

    Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'category': category,
        'commonName': commonName,
        'description': description,
        'isCustom': isCustom,
        'personalNotes': personalNotes,
        'createdAt': createdAt?.toIso8601String(),
      };
  }
