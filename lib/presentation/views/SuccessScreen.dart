import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:lottie/lottie.dart';
import '../../theme/ThemeHelper.dart';

class SuccessScreen extends StatefulWidget {
  final String?title;
  final String? nextRoute;
  const SuccessScreen({super.key, this.nextRoute,this.title});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(
        context,
      ), // ✅ Themed background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/successfully.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
              const SizedBox(height: 10),
              Text(
                widget.title??"",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ThemeHelper.textColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: CustomAppButton1(
            text: "Done",
            onPlusTap: () {
              if (widget.nextRoute != null && widget.nextRoute!.isNotEmpty) {
                context.pushReplacement(widget.nextRoute!);
              } else {
                context.pushReplacement("/dashboard");
              }
            },
          ),
        ),
      ),
    );
  }
}
