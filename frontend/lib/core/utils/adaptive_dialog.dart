import 'package:flutter/material.dart';
import '../utils/platform_helper.dart';

/// Adaptive dialog utility that shows fullscreen dialogs on mobile
/// and regular dialogs on desktop/web
class AdaptiveDialog {
  AdaptiveDialog._();

  /// Shows an adaptive dialog that adapts to the current platform
  ///
  /// On mobile devices, shows a fullscreen dialog using showGeneralDialog
  /// On desktop/web, shows a standard dialog using showDialog
  ///
  /// [context] The build context
  /// [builder] Widget builder for the dialog content
  /// [barrierDismissible] Whether the dialog can be dismissed by tapping outside
  /// [useFullscreen] Override the automatic platform detection
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool? useFullscreen,
  }) {
    final isFullscreen = useFullscreen ?? PlatformHelper.isMobile;

    if (isFullscreen) {
      return showGeneralDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: MaterialLocalizations.of(context).dialogLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Dialog(
                    insetPadding: EdgeInsets.zero,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.95,
                        maxWidth: MediaQuery.of(context).size.width * 0.95,
                      ),
                      child: builder(context),
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: builder,
      );
    }
  }

  /// Shows a fullscreen dialog specifically for mobile devices
  /// This provides a consistent fullscreen experience across mobile platforms
  static Future<T?> showMobileFullscreen<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return show<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      useFullscreen: true,
    );
  }

  /// Shows a standard dialog for desktop/web platforms
  static Future<T?> showStandard<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return show<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      useFullscreen: false,
    );
  }
}
