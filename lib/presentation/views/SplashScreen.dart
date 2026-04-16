import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classifieds/widgets/CommonBackground.dart';
import 'package:classifieds/widgets/PremiumUpgradeDialog.dart';
import 'package:classifieds/services/AppConfigService.dart';

import '../../services/AuthService.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
    requestTrackingPermission();
  }

  Future<void> requestTrackingPermission() async {
    if (!kIsWeb && Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
  }

  Future<void> _initialize() async {
    // Fetch app config (with 3s timeout fallback)
    await AppConfigService.fetch();

    // Brief splash display
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1. Maintenance check — blocking full screen
    if (AppConfigService.isMaintenanceActive) {
      context.pushReplacement('/maintenance');
      return;
    }

    // 2. Force update check — blocking dialog (no dismiss)
    if (AppConfigService.needsForceUpdate) {
      _showForceUpdateDialog();
      return;
    }

    // 3. All clear — go to dashboard (handles guest mode internally)
    context.pushReplacement('/dashboard');
  }

  void _showForceUpdateDialog() {
    final storeUrl = AppConfigService.storeUrl;
    final message = AppConfigService.updateMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => PopScope(
        canPop: false,
        child: PremiumUpgradeDialog(
          isForceUpdate: true,
          releaseNotes: message.isNotEmpty ? message : null,
          onUpdatePressed: () {
            if (storeUrl.isNotEmpty) {
              launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F5),
      body: Background(
        child: Center(
          child: Image.asset(
            "assets/images/appLogo.png",
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}
