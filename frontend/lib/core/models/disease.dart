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

    Disease({
        required this.code,
        required this.name,
        required this.category,
      });

    factory Disease.fromJson(Map<String, dynamic> json) => Disease (
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
    );
    
    Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'category': category,
      };
  }
