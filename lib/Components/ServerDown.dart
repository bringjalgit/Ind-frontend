import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:classifieds/theme/app_colors.dart';

import 'CustomAppButton.dart';

class Serverdown extends StatelessWidget {
  const Serverdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Whoops! ",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    fontFamily: "Inter",
                  ),
                  children: [
                    TextSpan(
                      text: "The server’s on a coffee break.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff9E9E9E),
                        fontFamily: "Inter",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Image.asset("assets/images/server_error.png"),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CustomAppButton1(text: "Try later", onPlusTap: () {})],
        ),
      ),
    );
  }
}
