import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cubit/theme_cubit.dart';
import 'app_colors.dart';

class ThemeHelper {
  static bool isDarkMode(BuildContext context) {
    final themeMode = context.read<ThemeCubit>().state;
    final platformBrightness = MediaQuery.of(context).platformBrightness;

    return switch (themeMode) {
      AppThemeMode.dark => true,
      AppThemeMode.light => false,
      AppThemeMode.system => platformBrightness == Brightness.dark,
    };
  }

  static Color backgroundColor(BuildContext context) =>
      isDarkMode(context) ? AppColors.darkBackground : AppColors.lightBackground;

  static Color textColor(BuildContext context) =>
      isDarkMode(context) ? AppColors.lightText : AppColors.darkText;

  static Color cardColor(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF1E1E1E) : Colors.white;
}

