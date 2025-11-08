import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  final pythonScriptPath = path.join('scripts', 'update_conditions_from_sheets.py');
  
  try {
    await Process.run(
      'python',
      [pythonScriptPath],
      runInShell: true,
    );
    print('Successfully updated conditions from Google Sheets.');
  } catch (e) {
    print('Failed to update conditions from Google Sheets: $e');
  }
}
