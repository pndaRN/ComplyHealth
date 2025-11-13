import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/education_content.dart';

class EducationService {
  static const String _assetPath = 'assets/education_content.json';
  static Map<String, EducationContent>? _cache;

  /// Load all educational content from the JSON asset
  static Future<Map<String, EducationContent>> loadAll() async {
    if (_cache != null) {
      return _cache!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);

      _cache = {
        for (final item in jsonList)
          (item['conditionCode'] as String):
              EducationContent.fromJson(item as Map<String, dynamic>)
      };

      return _cache!;
    } catch (e) {
      // If file doesn't exist or has errors, return empty map
      _cache = {};
      return _cache!;
    }
  }

  /// Get educational content for a specific condition code
  static Future<EducationContent?> getContentForCondition(
      String conditionCode) async {
    final allContent = await loadAll();
    return allContent[conditionCode];
  }

  /// Check if educational content exists for a condition
  static Future<bool> hasContent(String conditionCode) async {
    final allContent = await loadAll();
    return allContent.containsKey(conditionCode);
  }

  /// Clear the cache (useful for testing or refreshing content)
  static void clearCache() {
    _cache = null;
  }
}
