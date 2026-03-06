import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    // Asset 2 is white, Asset 3 is blue (#0100cb)
    // For light mode, we want a primary blue background with white logo
    // For dark mode, we want a dark background with blue logo
    final String assetPath = isDarkMode
        ? 'assets/Asset 3- SVG transparent.svg'
        : 'assets/Asset 2- SVG transparent.svg';

    final Color backgroundColor = isDarkMode
        ? AppColors.backgroundDark
        : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: SvgPicture.asset(
            assetPath,
            width: MediaQuery.of(context).size.width * 0.6,
            semanticsLabel: 'ComplyHealth Logo',
          ),
        ),
      ),
    );
  }
}
