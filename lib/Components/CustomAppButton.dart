import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:classifieds/theme/app_colors.dart';

import '../theme/AppTextStyles.dart';

class CustomAppButton extends StatelessWidget implements PreferredSizeWidget {
  final String text;
  final Color? color;
  final double? width;
  final double? height;
  final Color? textcolor;
  final VoidCallback? onPlusTap;
  final bool isLoading;
  CustomAppButton({
    Key? key,
    required this.text,
    required this.onPlusTap,
    this.color,
    this.textcolor,
    this.height,
    this.width,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width ?? w,
      height: height ?? 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: isLoading ? null : onPlusTap,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: AppTextStyles.titleSmall(Colors.black).copyWith(
                  color: textcolor ?? AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  @override
  Size get preferredSize => throw UnimplementedError();
}

class CustomAppButton1 extends StatelessWidget implements PreferredSizeWidget {
  final String text;
  final Color? color;
  final double? width;
  final double? height;
  final Color? textcolor;
  final double? textSize;
  final VoidCallback? onPlusTap;
  final bool isLoading;

  const CustomAppButton1({
    Key? key,
    required this.text,
    required this.onPlusTap,
    this.color,
    this.textcolor,
    this.textSize,
    this.height,
    this.width,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width ?? w,
      height: height ?? 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: textcolor ?? Colors.white,
          shadowColor: Colors.transparent,
          overlayColor: Colors.transparent,
        ),
        // keep button active but ignore taps when loading
        onPressed: isLoading ? () {} : onPlusTap,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ), // 👈 loader white
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: textcolor ?? Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: textSize?? 16,
                ),
              ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? 48);
}
