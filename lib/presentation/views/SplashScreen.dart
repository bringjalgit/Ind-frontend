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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up the auth-screen logo so it's already decoded and on the
    // GPU by the time the user reaches LoginScreen / OTPScreen. The
    // splash is on-screen for several seconds anyway — wasting that
    // time waiting on an image decode at login is silly. precacheImage
    // needs a BuildContext, so it lives here (not initState).
    precacheImage(const AssetImage('assets/images/applogonew.png'), context);
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

    // 3. Auth gate — only registered users with a valid cached token
    //    go straight to the dashboard. Everyone else (first-time
    //    install, logged out, expired token that can't be refreshed)
    //    lands on the login screen.
    final guest = await AuthService.isGuest;
    if (guest) {
      if (!mounted) return;
      context.pushReplacement('/login');
      return;
    }

    // Has a cached access token. Check expiry and refresh if needed —
    // a stale token where the refresh fails (refresh token expired or
    // revoked) is functionally guest, so route to login rather than
    // letting the dashboard hit 401 on every call.
    //
    // Bug #7 fix — on refresh failure, call AuthService.logout()
    // instead of a bare pushReplacement. logout() clears the stale
    // auth_session_v1 blob AND navigates to /login, mirroring exactly
    // what the ApiClient interceptor does on a failed mid-session
    // refresh. Without this, the splash would leave the dead tokens
    // sitting in SecureStorage; the user's next cold-start would read
    // them, attempt refresh, fail again, and re-loop — wasting a
    // refresh round-trip every launch until something else (manual
    // logout, app uninstall) wipes the cache.
    if (await AuthService.isTokenExpired()) {
      final refreshed = await AuthService.refreshToken();
      if (!refreshed) {
        if (!mounted) return;
        await AuthService.logout();
        return;
      }
    }

    // Bug #4 — Onboarded check.
    //
    // Token is valid, but that ALONE is not enough to land on the
    // dashboard. A user who verifies OTP receives a token immediately
    // (so they can submit the next step's register form) and is
    // dropped on the Register screen. If they walk away or force-close
    // before completing the form, their cache holds a valid token AND
    // `isNewUser=true`. Without this check the splash would route them
    // to the dashboard on next launch, where every screen reads a
    // half-filled profile — visible day-one bug.
    //
    // `AuthService.isNewUser` reads the cached flag (stored in the
    // atomic auth_session_v1 blob from Bug #1's fix). The backend sets
    // it on OTP verify and the Register screen flips it to "false"
    // after a successful submit — see
    // RegisterUserDetailsScreen.dart:531.
    if (await AuthService.isNewUser) {
      if (!mounted) return;
      context.pushReplacement('/register');
      return;
    }

    if (!mounted) return;
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
