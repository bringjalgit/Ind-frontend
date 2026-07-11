
import 'package:flutter/material.dart';

import '../theme/AppTextStyles.dart';
import '../theme/app_colors.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  const ActionButton({
    required this.icon,
    required this.label,
    this.textColor = AppColors.primary,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.bodySmall(textColor)),
          ],
        ),
      ),
    );
  }
}