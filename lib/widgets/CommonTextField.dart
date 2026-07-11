import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/AppTextStyles.dart';
import '../Components/ShakeWidget.dart';
import '../theme/ThemeHelper.dart';
import '../utils/color_constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonTextField1 extends StatelessWidget {
  final String? hint;
  final String lable;
  final Color color;
  final double? lableFontSize;
  final FontWeight? lableFontWeight;
  final int maxLines;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool? isRead;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final void Function()? onTap;

  const CommonTextField1({
    super.key,
    this.hint,
    required this.color,
    required this.lable,
    this.maxLines = 1,
    this.controller,
    this.lableFontSize,
    this.lableFontWeight,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
    this.isRead,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final bool readOnly = isRead ?? false;
    final bool isMultiline = maxLines > 1;

    // Enforce Flutter rule: if using newline on multiline, keyboardType must be multiline.
    final TextInputType effectiveKeyboardType = isMultiline
        ? TextInputType.multiline
        : (keyboardType ?? TextInputType.text);

    // Sensible default actions: newline for multiline, next for single-line.
    final TextInputAction effectiveAction = isMultiline
        ? TextInputAction.newline
        : TextInputAction.next;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          lable,
          style: AppTextStyles.bodyLarge(textColor).copyWith(
            color: textColor,
            fontWeight: lableFontWeight ?? FontWeight.w600,
            fontSize: lableFontSize,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          readOnly: readOnly,
          onTap: () {
            if (readOnly)
              FocusScope.of(context).unfocus(); // prevent IME on pickers
            onTap?.call();
          },
          inputFormatters: inputFormatters,
          style: AppTextStyles.bodyMedium(textColor),
          controller: controller,
          keyboardType: effectiveKeyboardType,
          textInputAction: effectiveAction,
          obscureText: obscureText,
          maxLines: maxLines,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          validator: validator, // return a message or null; Flutter shows it
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            // Let Flutter render errorText; no custom error widgets = no extra rebuilds
          ),
        ),
      ],
    );
  }
}
