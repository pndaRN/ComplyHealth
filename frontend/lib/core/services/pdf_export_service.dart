import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:complyhealth/core/models/medication.dart';
import 'package:complyhealth/core/models/medication_log.dart';
import 'package:complyhealth/core/models/profile.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/state/conditions_provider.dart';
import 'package:complyhealth/core/state/medication_provider.dart';
import 'package:complyhealth/core/state/profile_provider.dart';
import 'package:complyhealth/core/utils/pdf_formatting_utils.dart';

// Conditional imports for platform-specific implementations
import 'pdf_export_service_mobile.dart'
    if (dart.library.html) 'pdf_export_service_web.dart';

/// Service for exporting medication data to PDF format
/// Follows singleton pattern like NotificationService and FeedbackService
class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();

  factory PdfExportService() => _instance;

  PdfExportService._internal();

  /// Export medication report as PDF and share via native dialog
  /// Aggregates data from all providers and generates comprehensive report
  Future<void> exportMedicationReport({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      // Aggregate data from all providers
      final data = await _aggregateData(ref);

      // Generate PDF document
      final pdfDoc = await _generatePdfDocument(data);

      // Generate file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'medication_report_$timestamp.pdf';

      // Save PDF and get file path (platform-specific)
      final filePath = await PdfFilePlatform.savePdfToFile(pdfDoc, fileName);

      // Get bytes for sharing
      final bytes = await pdfDoc.save();

      // Share PDF (platform-specific)
      await PdfFilePlatform.sharePdf(filePath, bytes, fileName);
    } catch (e) {
      // Rethrow for widget to handle with SnackBar
      rethrow;
    }
  }

  /// Aggregate all necessary data from providers
  Future<_PdfData> _aggregateData(WidgetRef ref) async {
    // Get profile data
    final profile = await ref.read(profileProvider.future);

    // Get all medications
    final medications = await ref.read(medicationProvider.future);

    // Get conditions for display name mapping
    final conditions = await ref.read(conditionsProvider.future);

    // Get adherence data
    final adherenceNotifier = ref.read(adherenceProvider.notifier);

    // Get recent medication logs (last 7 days)
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final allLogs = await adherenceNotifier.getLogsForDateRange(
      sevenDaysAgo,
      now,
    );

    // Group logs by medication ID
    final logsByMedication = <String, List<MedicationLog>>{};
    for (final med in medications) {
      logsByMedication[med.id] = allLogs
          .where((log) => log.medicationId == med.id)
          .toList();
    }

    // Map condition names to display names
    final conditionDisplayNames = <String, String>{};
    for (final condition in conditions) {
      conditionDisplayNames[condition.name] = condition.commonName.isNotEmpty
          ? condition.commonName
          : condition.name;
    }

    return _PdfData(
      profile: profile,
      medications: medications,
      logsByMedication: logsByMedication,
      conditionDisplayNames: conditionDisplayNames,
      exportDate: now,
    );
  }

  /// Generate PDF document from aggregated data
  Future<pw.Document> _generatePdfDocument(_PdfData data) async {
    final pdf = pw.Document();

    // Load fonts for Unicode and Icon support
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final iconFontData = await rootBundle.load(
      'assets/fonts/MaterialIcons-Regular.ttf',
    );

    final baseFont = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);
    final iconFont = pw.Font.ttf(iconFontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          icons: iconFont,
        ),
        build: (context) => [
          // Header section
          _buildHeader(data.profile, data.exportDate),
          pw.SizedBox(height: 24),

          // Medications list
          if (data.medications.isEmpty)
            _buildEmptyState()
          else ...[
            _buildMedicationList(
              data.medications,
              data.conditionDisplayNames,
              data.logsByMedication,
            ),
          ],

          // Footer
          pw.SizedBox(height: 24),
          _buildFooter(data.exportDate),
        ],
      ),
    );

    return pdf;
  }

  /// Build PDF header with patient information
  pw.Widget _buildHeader(Profile profile, DateTime exportDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildBrandBanner(),
        pw.SizedBox(height: 16),
        _buildPatientInfoGrid(profile, exportDate),
        if (profile.allergies.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _buildAllergyAlert(profile.allergies),
        ],
      ],
    );
  }

  /// Full-width brand banner
  pw.Widget _buildBrandBanner() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF0000CC), // Brand Blue
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ComplyHealth',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Comprehensive Medication & Health Report',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.blue100,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Patient information in a structured grid
  pw.Widget _buildPatientInfoGrid(Profile profile, DateTime exportDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('PATIENT', '${profile.firstName} ${profile.lastName}'),
          _buildInfoItem(
            'DATE OF BIRTH',
            profile.dob.isNotEmpty
                ? PdfFormattingUtils.formatDobForPdf(profile.dob)
                : 'Not Set',
          ),
          _buildInfoItem(
            'REPORT DATE',
            PdfFormattingUtils.formatDateForPdf(exportDate),
          ),
        ],
      ),
    );
  }

  /// Individual info item for the grid
  pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// Prominent allergy alert box
  pw.Widget _buildAllergyAlert(String allergies) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.red300, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 16,
            height: 16,
            decoration: const pw.BoxDecoration(
              color: PdfColors.red700,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                '!',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'ALLERGIES: ',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.red900,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.TextSpan(
                    text: allergies,
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.red900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build medication list section
  pw.Widget _buildMedicationList(
    List<Medication> medications,
    Map<String, String> conditionDisplayNames,
    Map<String, List<MedicationLog>> logsByMedication,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(
            'CURRENT MEDICATIONS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5), // Name
            1: const pw.FlexColumnWidth(1.5), // Dosage
            2: const pw.FlexColumnWidth(2), // Schedule
            3: const pw.FlexColumnWidth(2), // Conditions
            4: const pw.FlexColumnWidth(1.5), // Adherence
          },
          children: [
            // Table Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell('Medication', isHeader: true),
                _buildTableCell('Dosage', isHeader: true),
                _buildTableCell('Schedule', isHeader: true),
                _buildTableCell('Conditions', isHeader: true),
                _buildTableCell('7-Day Adherence', isHeader: true),
              ],
            ),
            // Data Rows
            ...medications.map((med) {
              final logs = logsByMedication[med.id] ?? [];
              final takenCount = logs
                  .where((log) => log.status == DoseStatus.taken)
                  .length;
              final totalCount = logs.length;
              final adherencePercent = totalCount > 0
                  ? (takenCount / totalCount) * 100
                  : 0.0;

              final displayConditions = med.conditionNames
                  .map((name) => conditionDisplayNames[name] ?? name)
                  .join(', ');

              String schedule = '';
              if (med.isPRN) {
                schedule = 'As Needed (Max ${med.maxDailyDoses} doses)';
              } else {
                schedule = PdfFormattingUtils.formatScheduledTimesForPdf(
                  med.scheduledTimes,
                );
              }

              return pw.TableRow(
                children: [
                  _buildTableCell(med.name, isBold: true),
                  _buildTableCell(med.dosage),
                  _buildTableCell(schedule),
                  _buildTableCell(
                    displayConditions.isEmpty ? 'None' : displayConditions,
                  ),
                  _buildAdherenceCell(takenCount, totalCount, adherencePercent),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Helper for consistent table cells
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 10,
          fontWeight: (isHeader || isBold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
      ),
    );
  }

  /// Specialized cell for adherence with color coding
  pw.Widget _buildAdherenceCell(int taken, int total, double percent) {
    PdfColor textColor = PdfColors.grey700;
    if (total > 0) {
      if (percent >= 90) {
        textColor = PdfColors.green700;
      } else if (percent >= 75) {
        textColor = PdfColors.orange700;
      } else {
        textColor = PdfColors.red700;
      }
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${percent.toStringAsFixed(1)}%',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
          pw.Text(
            '$taken/$total doses',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Build empty state when no medications
  pw.Widget _buildEmptyState() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(32),
      child: pw.Center(
        child: pw.Column(
          children: [
            pw.Icon(
              pw.IconData(0xe3a4), // medication icon
              size: 48,
              color: PdfColors.grey400,
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'No medications currently tracked',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build PDF footer
  pw.Widget _buildFooter(DateTime exportDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Text(
        'This report was generated by ComplyHealth on ${PdfFormattingUtils.formatDateForPdf(exportDate)}. '
        'For questions about your medications, please consult your healthcare provider.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}

/// Internal data class for aggregating all necessary data for PDF generation
class _PdfData {
  final Profile profile;
  final List<Medication> medications;
  final Map<String, List<MedicationLog>> logsByMedication;
  final Map<String, String> conditionDisplayNames;
  final DateTime exportDate;

  _PdfData({
    required this.profile,
    required this.medications,
    required this.logsByMedication,
    required this.conditionDisplayNames,
    required this.exportDate,
  });
}
