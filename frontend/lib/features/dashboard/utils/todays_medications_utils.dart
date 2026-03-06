import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/theme/status_colors.dart';

/// Constants for Today's Medications widget
class TodaysMedicationsConstants {
  TodaysMedicationsConstants._();

  /// Time window in hours for showing medications as "due now"
  static const int immediateWindowHours = 2;

  /// Grace period in minutes before a dose is considered overdue
  static const int graceWindowMinutes = 60;

  /// Dose ratio at which PRN count shows as error (at max)
  static const double maxDoseRatio = 1.0;

  /// Dose ratio at which PRN count shows as warning (approaching max)
  static const double warningDoseRatio = 0.75;
}

/// Shared list of skip reasons used across dialogs
const List<String> kSkipReasons = [
  'Forgot',
  'Side effects',
  'Unavailable',
  'Not needed',
  'Other',
];

/// Formats a DateTime to a user-friendly time string (e.g., "2:30 PM")
String formatMedicationTime(DateTime time) {
  return DateFormat('h:mm a').format(time);
}

/// Returns a color based on adherence percentage
Color getAdherenceColor(double adherence, ThemeData theme) {
  if (adherence >= 90) return theme.statusColors.success;
  if (adherence >= 75) return theme.statusColors.info;
  if (adherence >= 50) return theme.statusColors.warning;
  return theme.statusColors.error;
}

/// Returns a color for PRN dose count based on current/max ratio
Color getDoseCountColor(int current, int max, ThemeData theme) {
  if (max == 0) return theme.colorScheme.onSurfaceVariant;
  final ratio = current / max;
  if (ratio >= TodaysMedicationsConstants.maxDoseRatio) {
    return theme.statusColors.error;
  }
  if (ratio >= TodaysMedicationsConstants.warningDoseRatio) {
    return theme.statusColors.warning;
  }
  return theme.statusColors.success;
}

/// Returns a BorderSide indicating urgency level for a medication instance
BorderSide getUrgencyBorder(MedicationInstance instance, ThemeData theme) {
  final now = DateTime.now();
  final scheduledTime = instance.scheduledTime;

  // Overdue (past grace period)
  if (instance.medication.isTimeSensitive &&
      now.isAfter(
        scheduledTime.add(
          const Duration(
            minutes: TodaysMedicationsConstants.graceWindowMinutes,
          ),
        ),
      )) {
    return BorderSide(color: theme.statusColors.error, width: 6);
  }

  // Within 30 minutes of scheduled time
  if (now.isAfter(scheduledTime.subtract(const Duration(minutes: 30))) &&
      now.isBefore(scheduledTime.add(const Duration(minutes: 30)))) {
    return BorderSide(color: theme.statusColors.warning, width: 4);
  }

  // Within 2-hour window
  return BorderSide(color: theme.statusColors.info, width: 4);
}

/// Checks if a medication instance is overdue (past grace period)
bool isInstanceOverdue(MedicationInstance instance) {
  // If not time sensitive, it's never considered overdue for the purpose of the "late" popup
  if (!instance.medication.isTimeSensitive) return false;

  final now = DateTime.now();
  return now.isAfter(
    instance.scheduledTime.add(
      const Duration(minutes: TodaysMedicationsConstants.graceWindowMinutes),
    ),
  );
}
