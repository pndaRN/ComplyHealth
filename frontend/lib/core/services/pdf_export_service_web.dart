import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:pdf/widgets.dart' as pw;

/// Web-specific implementation for PDF file operations
/// Uses browser download APIs instead of file system
class PdfFilePlatform {
  /// Save PDF to browser download (web implementation)
  /// Returns a dummy file path since web doesn't use file paths
  static Future<String> savePdfToFile(pw.Document pdf, String fileName) async {
    try {
      final bytes = await pdf.save();

      // Create blob and download link
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      // Clean up
      html.Url.revokeObjectUrl(url);

      // Return dummy path (not used on web)
      return fileName;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Share PDF file (web implementation)
  /// On web, we just download the file since native share may not be available
  static Future<void> sharePdf(String filePath, Uint8List bytes, String fileName) async {
    // On web, sharing is handled by the download in savePdfToFile
    // We could optionally trigger another download here if needed
    // For now, just return successfully since the download already happened
    return;
  }
}
