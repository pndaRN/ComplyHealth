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

    Disease({
        required this.code,
        required this.name,
        required this.category,
        this.commonName = '',
        this.description = '',
      });

    factory Disease.fromJson(Map<String, dynamic> json) => Disease (
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      commonName: json['commonName'] ?? '',
      description: json['description'] ?? '',
    );

    Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'category': category,
        'commonName': commonName,
        'description': description,
      };
  }
