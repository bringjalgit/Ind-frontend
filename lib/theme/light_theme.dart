import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'AppTextStyles.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  visualDensity: VisualDensity.compact,
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
  scaffoldBackgroundColor: Colors.white,
  dialogBackgroundColor: Colors.white,
  cardColor: Colors.white,
  searchBarTheme: const SearchBarThemeData(),
  tabBarTheme: const TabBarThemeData(),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    labelStyle: AppTextStyles.titleMedium(Colors.black.withOpacity(0.25)),
    hintStyle: AppTextStyles.titleSmall(Colors.black.withOpacity(0.35)),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: AppColors.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: AppColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: AppColors.lightBorder),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: AppColors.lightBorder),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: AppColors.lightBorder),
    ),
    errorStyle: TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      color: Colors.red,
    ),
  ),
  dialogTheme: const DialogThemeData(
    shadowColor: Colors.white,
    surfaceTintColor: Colors.white,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(5.0)),
    ),
  ),
  buttonTheme: const ButtonThemeData(),
  popupMenuTheme: const PopupMenuThemeData(
    color: Colors.white,
    shadowColor: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    surfaceTintColor: Colors.white,
    backgroundColor: Colors.white,
    shadowColor: Colors.white,
    foregroundColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    shadowColor: Colors.white,
    surfaceTintColor: Colors.white,
    color: Colors.white,
  ),
  textButtonTheme: TextButtonThemeData(style: ButtonStyle()),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle()),
  outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle()),
  bottomSheetTheme: const BottomSheetThemeData(
    surfaceTintColor: Colors.white,
    backgroundColor: Colors.white,
  ),
  colorScheme: const ColorScheme.light(
    primary: Colors.black, // 🔴 Add this
    background: Colors.black,
  ).copyWith(background: Colors.black),
  // Optionally, set directly as fallback
  primaryColor: Colors.black,
  fontFamily: 'Roboto',
  textTheme: TextTheme(
    displayLarge: AppTextStyles.displayLarge(AppColors.lightText),
    displayMedium: AppTextStyles.displayMedium(AppColors.lightText),
    displaySmall: AppTextStyles.displaySmall(AppColors.lightText),
    headlineLarge: AppTextStyles.headlineLarge(AppColors.lightText),
    headlineMedium: AppTextStyles.headlineMedium(AppColors.lightText),
    headlineSmall: AppTextStyles.headlineSmall(AppColors.lightText),
    titleLarge: AppTextStyles.titleLarge(AppColors.lightText),
    titleMedium: AppTextStyles.titleMedium(AppColors.lightText),
    titleSmall: AppTextStyles.titleSmall(AppColors.lightText),
    bodyLarge: AppTextStyles.bodyLarge(AppColors.lightText),
    bodyMedium: AppTextStyles.bodyMedium(AppColors.lightText),
    bodySmall: AppTextStyles.bodySmall(AppColors.lightText),
    labelLarge: AppTextStyles.labelLarge(AppColors.lightText),
    labelMedium: AppTextStyles.labelMedium(AppColors.lightText),
    labelSmall: AppTextStyles.labelSmall(AppColors.lightText),
  ),
);
