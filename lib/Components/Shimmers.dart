import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// ============================================================
/// PREMIUM THEME AWARE SHIMMER SYSTEM
/// Works perfectly for both Light & Dark themes
/// ============================================================

class AppShimmer {
  /// Base color depending on theme
  static Color baseColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF2A2A2A) // Deep dark grey
        : const Color(0xFFE0E0E0); // Soft light grey
  }

  /// Highlight color depending on theme
  static Color highlightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF3A3A3A) // Slight glow in dark
        : const Color(0xFFF5F5F5); // Soft highlight in light
  }
}

/// ============================================================
/// REUSABLE SHIMMER BOX (Main Core Widget)
/// ============================================================

Widget shimmerBox({
  required double width,
  required double height,
  required BuildContext context,
  double radius = 12,
  ShapeBorder? shape,
}) {
  return Shimmer.fromColors(
    baseColor: AppShimmer.baseColor(context),
    highlightColor: AppShimmer.highlightColor(context),
    period: const Duration(milliseconds: 1500),
    direction: ShimmerDirection.ltr,
    child: Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
        color: Theme.of(context).cardColor,
      ),
    ),
  );
}

/// ============================================================
/// CIRCLE SHIMMER
/// ============================================================

Widget shimmerCircle(double size, BuildContext context) {
  return shimmerBox(
    width: size,
    height: size,
    context: context,
    shape: const CircleBorder(),
  );
}

/// ============================================================
/// RECTANGLE SHIMMER
/// ============================================================

Widget shimmerRectangle({
  required double width,
  required double height,
  required BuildContext context,
  double radius = 12,
}) {
  return shimmerBox(
    width: width,
    height: height,
    context: context,
    radius: radius,
  );
}

/// ============================================================
/// TEXT SHIMMER (Rounded Premium Style)
/// ============================================================

Widget shimmerText({
  required double width,
  double height = 14,
  required BuildContext context,
}) {
  return shimmerBox(
    width: width,
    height: height,
    context: context,
    radius: 20,
  );
}

/// ============================================================
/// BUTTON SHIMMER (Modern Gradient Feel)
/// ============================================================

Widget shimmerButton(
    double width,
    double height,
    BuildContext context,
    ) {
  return Shimmer.fromColors(
    baseColor: AppShimmer.baseColor(context),
    highlightColor: AppShimmer.highlightColor(context),
    period: const Duration(milliseconds: 1500),
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppShimmer.baseColor(context),
            AppShimmer.highlightColor(context),
            AppShimmer.baseColor(context),
          ],
        ),
      ),
    ),
  );
}

/// ============================================================
/// FULL WIDTH LINEAR SHIMMER (Progress / Divider)
/// ============================================================

Widget shimmerLinear(
    double height,
    BuildContext context,
    ) {
  return shimmerBox(
    width: double.infinity,
    height: height,
    context: context,
    radius: 30,
  );
}

/// ============================================================
/// LIST TILE SHIMMER (Commonly Used in Apps)
/// ============================================================

Widget shimmerListTile(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        shimmerCircle(50, context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              shimmerText(width: double.infinity, context: context),
              const SizedBox(height: 8),
              shimmerText(width: 150, context: context),
            ],
          ),
        ),
      ],
    ),
  );
}