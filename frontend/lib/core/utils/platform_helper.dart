import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper class for platform detection and adaptive UI decisions
class PlatformHelper {
  PlatformHelper._();

  /// Whether the app is running on the web
  static bool get isWeb => kIsWeb;

  /// Whether the app is running on a mobile platform (iOS or Android)
  static bool get isMobile =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Whether the app is running on a desktop platform (Windows, macOS, or Linux)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Whether the app is running on a touch-enabled device
  static bool get isTouchDevice => isMobile || isWeb;

  /// Whether to use mobile-specific UI patterns
  static bool get useMobileUI => isMobile || isWeb;
}
