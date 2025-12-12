import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/services/pdf_export_service.dart';
import 'package:complyhealth/core/theme/status_colors.dart';

/// Reusable button widget for exporting medication reports to PDF
/// Shows loading state during export and provides user feedback via SnackBar
class PdfExportButton extends ConsumerStatefulWidget {
  final IconData icon;
  final String tooltip;

  const PdfExportButton({
    super.key,
    this.icon = Icons.file_download,
    this.tooltip = 'Export medication report as PDF',
  });

  @override
  ConsumerState<PdfExportButton> createState() => _PdfExportButtonState();
}

class _PdfExportButtonState extends ConsumerState<PdfExportButton> {
  bool _isExporting = false;

  Future<void> _handleExport() async {
    // Prevent multiple simultaneous exports
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final service = PdfExportService();
      await service.exportMedicationReport(
        context: context,
        ref: ref,
      );

      // Check if widget is still mounted before showing SnackBar
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('PDF exported successfully'),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).statusColors.success,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Check if widget is still mounted before showing SnackBar
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Failed to export PDF: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).statusColors.error,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      // Ensure we reset the loading state
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isExporting
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
            )
          : Icon(widget.icon),
      onPressed: _isExporting ? null : _handleExport,
      tooltip: widget.tooltip,
    );
  }
}
