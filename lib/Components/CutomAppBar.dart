import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/ThemeHelper.dart';

class CustomAppBar1 extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  const CustomAppBar1({Key? key, required this.title, required this.actions})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final isDarkMode = ThemeHelper.isDarkMode(context);
    return AppBar(
      backgroundColor: Color(isDarkMode?0xff0D0D0D:0xffFFFFFF),
      centerTitle: true,
      leading: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: () {
          context.pop(true);
        },
        icon: Icon(Icons.arrow_back, size: 24, color:Color(isDarkMode?0xffFFFFFF: 0xff374151)),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
