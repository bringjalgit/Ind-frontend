import 'package:flutter/material.dart';

class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;
  static late double blockWidth;
  static late double blockHeight;

  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;

    // Define blocks as percentages of screen size
    blockWidth = screenWidth / 100;
    blockHeight = screenHeight / 100;
  }

  // Get width as percentage
  static double width(double percent) {
    return blockWidth * percent;
  }

  // Get height as percentage
  static double height(double percent) {
    return blockHeight * percent;
  }

  // Responsive font size (based on width)
  static double fontSize(double size) {
    return blockWidth * (size / 3);
  }
}
