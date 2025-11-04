import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/disease.dart';

class ICDService {
  static Future<List<Disease>> loadAll() async {
    final data = await rootBundle.loadString('assets/icd10_chronic.json');
    final List jsonList = jsonDecode(data);
    return jsonList.map((e) => Disease.fromJson(e)).toList();
  }

  static List<Disease> search(List<Disease> all, String term) {
    if (term.isEmpty) return [];
    final lower = term.toLowerCase();
    return all
        .where(
          (d) =>
              d.name.toLowerCase().contains(lower) ||
              d.commonName.toLowerCase().contains(lower) ||
              d.code.toLowerCase().contains(lower),
        )
        .toList();
  }
}
