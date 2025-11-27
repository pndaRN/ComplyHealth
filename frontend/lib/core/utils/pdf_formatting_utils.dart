import 'package:intl/intl.dart';

/// Utility class for PDF-specific formatting operations
class PdfFormattingUtils {
  /// Format DateTime for PDF header and footer
  /// Example: DateTime(2025, 1, 26) returns "January 26, 2025"
  static String formatDateForPdf(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format DateTime for short date display
  /// Example: DateTime(2025, 1, 26) returns "Jan 26, 2025"
  static String formatShortDateForPdf(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format medication time from 24-hour format to 12-hour format for PDF
  /// Uses existing TimeFormattingUtils pattern
  /// Example: "14:30" returns "2:30 PM"
  static String formatTimeForPdf(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        return '$displayHour:$displayMinute $period';
      }
    } catch (e) {
      // Return original if parsing fails
    }
    return timeStr;
  }

  /// Format list of scheduled times for PDF display
  /// Example: ["09:00", "14:30", "21:00"] returns "9:00 AM, 2:30 PM, 9:00 PM"
  static String formatScheduledTimesForPdf(List<String> times) {
    if (times.isEmpty) return 'No times scheduled';
    return times.map((time) => formatTimeForPdf(time)).join(', ');
  }

  /// Format adherence percentage for PDF display
  /// Example: 87.5 returns "87.5%"
  static String formatAdherencePercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Format adherence percentage with dose count
  /// Example: (15, 20) returns "75.0% (15/20 doses)"
  static String formatAdherenceWithCount(int taken, int total) {
    if (total == 0) return '0.0% (0/0 doses)';
    final percentage = (taken / total) * 100;
    return '${percentage.toStringAsFixed(1)}% ($taken/$total doses)';
  }

  /// Wrap long text to fit within a maximum width
  /// Returns list of strings, each representing a line
  /// Note: This is a simple implementation for basic text wrapping
  static List<String> wrapText(String text, {int maxCharsPerLine = 50}) {
    if (text.length <= maxCharsPerLine) return [text];

    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + word.length + 1) <= maxCharsPerLine) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  /// Format condition names for PDF display
  /// Example: ["Hypertension", "Diabetes Type 2"] returns "Hypertension, Diabetes Type 2"
  static String formatConditionsForPdf(List<String> conditions) {
    if (conditions.isEmpty) return 'No conditions specified';
    return conditions.join(', ');
  }

  /// Format PRN max doses for PDF display
  /// Example: 4 returns "4 doses"
  /// Example: null returns "Not specified"
  static String formatMaxDoses(int? maxDoses) {
    if (maxDoses == null) return 'Not specified';
    return maxDoses == 1 ? '1 dose' : '$maxDoses doses';
  }

  /// Format current dose count for PRN medications
  /// Example: 2 returns "2 doses taken"
  /// Example: 0 returns "No doses taken"
  static String formatCurrentDoseCount(int count) {
    if (count == 0) return 'No doses taken';
    return count == 1 ? '1 dose taken' : '$count doses taken';
  }

  /// Format streak count for PDF display
  /// Example: 5 returns "5 days"
  /// Example: 0 returns "No streak"
  static String formatStreak(int streak) {
    if (streak == 0) return 'No streak';
    return streak == 1 ? '1 day' : '$streak days';
  }

  /// Truncate text to maximum length with ellipsis if needed
  /// Example: ("Very Long Medication Name", 20) returns "Very Long Medicati..."
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Format date of birth for PDF
  /// Example: "1990-05-15" returns "May 15, 1990"
  static String formatDobForPdf(String dob) {
    if (dob.isEmpty) return 'Not set';
    try {
      // Try parsing various formats
      DateTime? date;

      // Try YYYY-MM-DD format
      if (dob.contains('-')) {
        date = DateTime.tryParse(dob);
      }

      if (date != null) {
        return formatDateForPdf(date);
      }
    } catch (e) {
      // If parsing fails, return original string
    }
    return dob;
  }

  /// Format placeholder text when data is missing
  static String formatPlaceholder(String? value, String placeholder) {
    return value != null && value.isNotEmpty ? value : placeholder;
  }
}
