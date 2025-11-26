/// Utility class for time parsing and formatting operations
class TimeFormattingUtils {
  static const int hoursPerDay = 24;
  static const int minutesPerHour = 60;
  static const int minutesPerDay = hoursPerDay * minutesPerHour; // 1440
  static const int noonHour = 12;

  /// Parse time string "HH:mm" to minutes since midnight
  /// Returns null if parsing fails
  ///
  /// Example: "14:30" returns 870 (14*60 + 30)
  static int? parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * minutesPerHour + minutes;
    } catch (e) {
      return null;
    }
  }

  /// Format 24-hour time string "HH:mm" to 12-hour format with AM/PM
  /// Returns original string if parsing fails
  ///
  /// Example: "14:30" returns "2:30 PM"
  static String formatTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= noonHour ? 'PM' : 'AM';
        final displayHour =
            hour == 0 ? noonHour : (hour > noonHour ? hour - noonHour : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        return '$displayHour:$displayMinute $period';
      }
    } catch (e) {
      // Return original if parsing fails
    }
    return timeString;
  }

  /// Parse time group string like "12:30 PM" or "12:30 PM (Tomorrow)" to minutes
  /// Returns null for special cases like "As Needed (PRN)" or "No Schedule"
  /// Adds minutesPerDay for tomorrow times
  ///
  /// Example: "2:30 PM (Tomorrow)" returns 870 + 1440 = 2310
  static int? parseTimeGroupToMinutes(String timeGroup) {
    try {
      // Handle special cases
      if (timeGroup == 'As Needed (PRN)' || timeGroup == 'No Schedule') {
        return null;
      }

      // Remove "(Tomorrow)" suffix if present
      final isTomorrow = timeGroup.contains('(Tomorrow)');
      final cleanTime = timeGroup.replaceAll(' (Tomorrow)', '').trim();

      // Parse "12:30 PM" format
      final parts = cleanTime.split(' ');
      if (parts.length != 2) return null;

      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;

      var hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);
      final period = parts[1];

      // Convert to 24-hour format
      if (period == 'PM' && hours != noonHour) {
        hours += noonHour;
      } else if (period == 'AM' && hours == noonHour) {
        hours = 0;
      }

      var timeInMinutes = hours * minutesPerHour + minutes;

      // Add 24 hours for tomorrow times
      if (isTomorrow) {
        timeInMinutes += minutesPerDay;
      }

      return timeInMinutes;
    } catch (e) {
      return null;
    }
  }

  /// Find the next scheduled time (in minutes since midnight) after the current time
  /// Returns null if there are no scheduled times
  /// For times that have passed today, adds minutesPerDay to indicate tomorrow
  static int? getNextScheduledTime(
    List<String> scheduledTimes,
    int currentTime,
  ) {
    if (scheduledTimes.isEmpty) return null;

    final times = scheduledTimes
        .map((timeStr) => parseTimeToMinutes(timeStr))
        .whereType<int>()
        .toList()
      ..sort();

    // Find the next time that's after current time
    for (final time in times) {
      if (time > currentTime) {
        return time;
      }
    }

    // If no time is after current time, return the first time (next day)
    // Add 24 hours worth of minutes to indicate it's tomorrow
    return times.isNotEmpty ? times.first + minutesPerDay : null;
  }

  /// Get current time in minutes since midnight
  static int getCurrentTimeInMinutes() {
    final now = DateTime.now();
    return now.hour * minutesPerHour + now.minute;
  }
}
