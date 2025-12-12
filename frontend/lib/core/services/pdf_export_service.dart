import 'package:flutter/material.dart';
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
    final profile = ref.read(profileProvider);

    // Get all medications
    final medications = ref.read(medicationProvider);

    // Get conditions for display name mapping
    final conditions = ref.read(conditionsProvider);

    // Get adherence data
    final adherenceNotifier = ref.read(adherenceProvider.notifier);
    final metrics = await adherenceNotifier.getMetrics();

    // Get recent medication logs (last 7 days)
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final allLogs = await adherenceNotifier.getLogsForDateRange(sevenDaysAgo, now);

    // Group logs by medication ID
    final logsByMedication = <String, List<MedicationLog>>{};
    for (final med in medications) {
      logsByMedication[med.id] =
          allLogs.where((log) => log.medicationId == med.id).toList();
    }

    // Map condition names to display names
    final conditionDisplayNames = <String, String>{};
    for (final condition in conditions) {
      conditionDisplayNames[condition.name] =
          condition.commonName.isNotEmpty ? condition.commonName : condition.name;
    }

    return _PdfData(
      profile: profile,
      medications: medications,
      adherenceMetrics: metrics,
      logsByMedication: logsByMedication,
      conditionDisplayNames: conditionDisplayNames,
      exportDate: now,
    );
  }

  /// Generate PDF document from aggregated data
  Future<pw.Document> _generatePdfDocument(_PdfData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header section
          _buildHeader(data.profile, data.exportDate),
          pw.SizedBox(height: 24),

          // Medications list
          if (data.medications.isEmpty)
            _buildEmptyState()
          else
            ...[
              _buildMedicationList(
                data.medications,
                data.conditionDisplayNames,
                data.logsByMedication,
              ),
              pw.SizedBox(height: 24),

              // Overall adherence summary
              _buildAdherenceSection(data.adherenceMetrics),
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
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.blue800),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ComplyHealth',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Medication Report',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Patient: ${profile.firstName} ${profile.lastName}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (profile.dob.isNotEmpty)
                    pw.Text(
                      'DOB: ${PdfFormattingUtils.formatDobForPdf(profile.dob)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
              pw.Text(
                'Generated: ${PdfFormattingUtils.formatDateForPdf(exportDate)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          if (profile.allergies.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.red300),
              ),
              child: pw.Row(
                children: [
                  pw.Icon(
                    pw.IconData(0xe5cd), // warning icon
                    size: 16,
                    color: PdfColors.red900,
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      'Allergies: ${profile.allergies}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.red900,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        pw.Header(
          level: 0,
          text: 'Medications (${medications.length})',
          textStyle: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 12),
        ...medications.map(
          (med) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: _buildMedicationTable(
              med,
              conditionDisplayNames,
              logsByMedication[med.id] ?? [],
            ),
          ),
        ),
      ],
    );
  }

  /// Build individual medication table
  pw.Widget _buildMedicationTable(
    Medication med,
    Map<String, String> conditionDisplayNames,
    List<MedicationLog> logs,
  ) {
    // Calculate recent adherence for this medication
    final takenCount =
        logs.where((log) => log.status == DoseStatus.taken).length;
    final adherenceText = PdfFormattingUtils.formatAdherenceWithCount(
      takenCount,
      logs.length,
    );

    // Map condition names to display names
    final displayConditions = med.conditionNames
        .map((name) => conditionDisplayNames[name] ?? name)
        .toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row with medication name
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                med.name,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        // Basic information rows
        _buildTableRow('Dosage', med.dosage),
        _buildTableRow(
          'Conditions',
          PdfFormattingUtils.formatConditionsForPdf(displayConditions),
        ),
        // Schedule information
        if (med.isPRN) ...[
          _buildTableRow('Type', 'As Needed (PRN)'),
          _buildTableRow(
            'Max Daily Doses',
            PdfFormattingUtils.formatMaxDoses(med.maxDailyDoses),
          ),
          _buildTableRow(
            'Current Count Today',
            PdfFormattingUtils.formatCurrentDoseCount(med.currentDoseCount),
          ),
        ] else ...[
          _buildTableRow('Type', 'Scheduled'),
          _buildTableRow(
            'Times',
            PdfFormattingUtils.formatScheduledTimesForPdf(med.scheduledTimes),
          ),
        ],
        // Adherence information
        _buildTableRow('7-Day Adherence', adherenceText),
      ],
    );
  }

  /// Build a single table row
  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  value,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build overall adherence summary section
  pw.Widget _buildAdherenceSection(AdherenceMetrics metrics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.green300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Overall Adherence Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                'Weekly Adherence',
                PdfFormattingUtils.formatAdherencePercentage(
                  metrics.weeklyAdherence,
                ),
              ),
              _buildMetricItem(
                'Current Streak',
                PdfFormattingUtils.formatStreak(metrics.currentStreak),
              ),
              _buildMetricItem(
                'Doses Taken',
                '${metrics.totalDosesTaken}',
              ),
              _buildMetricItem(
                'Doses Missed',
                '${metrics.totalDosesMissed}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a single metric display item
  pw.Widget _buildMetricItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
      ],
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
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400),
        ),
      ),
      child: pw.Text(
        'This report was generated by ComplyHealth on ${PdfFormattingUtils.formatDateForPdf(exportDate)}. '
        'For questions about your medications, please consult your healthcare provider.',
        style: const pw.TextStyle(
          fontSize: 8,
          color: PdfColors.grey600,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

}

/// Internal data class for aggregating all necessary data for PDF generation
class _PdfData {
  final Profile profile;
  final List<Medication> medications;
  final AdherenceMetrics adherenceMetrics;
  final Map<String, List<MedicationLog>> logsByMedication;
  final Map<String, String> conditionDisplayNames;
  final DateTime exportDate;

  _PdfData({
    required this.profile,
    required this.medications,
    required this.adherenceMetrics,
    required this.logsByMedication,
    required this.conditionDisplayNames,
    required this.exportDate,
  });
}
