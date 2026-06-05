import 'package:flutter/material.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import '../theme/app_colors.dart';
import '../utils/color_constants.dart';

class CustomSnackBar {
  static void show(BuildContext context, String message) {
    final textColor = ThemeHelper.textColor(context);
    final backgroundColor = ThemeHelper.backgroundColor(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.titleSmall(
            textColor,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class CustomSnackBar1 {
  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16, // below status bar
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primarycolor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: "roboto_serif",
              ),
            ),
          ),
        ),
      ),
    );

    // Insert the overlay
    overlay.insert(overlayEntry);

    // Remove after 2 seconds
    Future.delayed(const Duration(seconds: 2)).then((_) => overlayEntry.remove());
  }
}