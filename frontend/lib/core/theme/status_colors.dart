import 'package:flutter/material.dart';

/// Adaptive status colors that adjust based on theme brightness
/// Maintains semantic meaning (green=success, red=error, etc.) across themes
class StatusColors {
  final Brightness brightness;

  const StatusColors(this.brightness);

  /// Success color (Green - positive outcomes, high adherence)
  /// Light: emerald-600, Dark: emerald-400
  Color get success => brightness == Brightness.light
      ? const Color(0xFF059669)
      : const Color(0xFF34D399);

  /// Warning color (Orange - caution, moderate adherence)
  /// Light: orange-600, Dark: orange-400
  Color get warning => brightness == Brightness.light
      ? const Color(0xFFEA580C)
      : const Color(0xFFFB923C);

  /// Error color (Red - problems, low adherence, missed doses)
  /// Light: red-600, Dark: red-400
  Color get error => brightness == Brightness.light
      ? const Color(0xFFDC2626)
      : const Color(0xFFF87171);

  /// Info color (Blue - informational, scheduled medications)
  /// Matches primary brand blue
  Color get info => brightness == Brightness.light
      ? const Color(0xFF0000CC)
      : const Color(0xFF668CFF);

  /// Streak color (Amber - achievements, XP, streaks)
  /// Light: amber-500, Dark: amber-300
  Color get streak => brightness == Brightness.light
      ? const Color(0xFFF59E0B)
      : const Color(0xFFFCD34D);

  /// PRN/Special color (Purple - as-needed medications, special features)
  /// Matches secondary purple
  Color get prn => brightness == Brightness.light
      ? const Color(0xFF6600CC)
      : const Color(0xFFA366FF);
}

/// Extension to easily access StatusColors from ThemeData
extension StatusColorsExtension on ThemeData {
  StatusColors get statusColors => StatusColors(brightness);
}
