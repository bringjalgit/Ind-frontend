import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classifieds/widgets/PremiumUpgradeDialog.dart';
import 'package:classifieds/services/AppConfigService.dart';

import '../../services/AuthService.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with TickerProviderStateMixin {
  // Halo + ambient animation controllers. Mirror the CSS keyframes from
  // the approved splash mock: two counter-rotating dashed rings, a
  // breathing glow, a shimmer sweep across the SELL WITH AI pill, a
  // looping loader bar, and a gentle float on the scattered icons.
  late final AnimationController _ring1Ctrl;
  late final AnimationController _ring2Ctrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _loaderCtrl;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _ring1Ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..repeat();
    _ring2Ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 42))
          ..repeat();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3400))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
    _loaderCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..repeat();
    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..repeat();

    _initialize();
    requestTrackingPermission();
  }

  @override
  void dispose() {
    _ring1Ctrl.dispose();
    _ring2Ctrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    _loaderCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
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
      // No login wall at startup — tokenless users land straight on the
      // home dashboard and browse as guests. Login is prompted only when
      // they hit a gated action (chat, contact, sell, profile, etc.).
      if (!mounted) return;
      context.pushReplacement('/dashboard');
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
              launchUrl(Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  // ── Scattered background icons (the 10 marketplace illustrations) ──
  // Positions are fractions of the screen, hand-tuned against the mock's
  // 390×844 layout so they spread to the corners + edges and leave an
  // oval of clean space around the centre logo.
  static const List<_SplashIcon> _icons = [
    _SplashIcon('assets/images/splash/car_rental.png',
        topF: .071, leftF: .056, size: 90, rot: -7, op: .42, phase: 0.0),
    _SplashIcon('assets/images/splash/idea.png',
        topF: .113, rightF: .046, size: 78, rot: 5, op: .40, phase: 0.4),
    _SplashIcon('assets/images/splash/connections.png',
        topF: .231, leftF: .041, size: 64, rot: 4, op: .34, phase: 1.1),
    _SplashIcon('assets/images/splash/home_address.png',
        topF: .255, rightF: .077, size: 84, rot: -3, op: .36, phase: 1.8),
    _SplashIcon('assets/images/splash/shopping.png',
        topF: .711, leftF: .062, size: 90, rot: 6, op: .42, phase: 0.7),
    _SplashIcon('assets/images/splash/support_group.png',
        topF: .687, rightF: .077, size: 78, rot: -6, op: .40, phase: 2.1),
    _SplashIcon('assets/images/splash/aerobics.png',
        topF: .817, leftF: .308, size: 64, rot: 3, op: .34, phase: 1.4),
    _SplashIcon('assets/images/splash/maintenance.png',
        topF: .835, rightF: .231, size: 74, rot: -4, op: .36, phase: 2.6),
    _SplashIcon('assets/images/splash/exercise_bike.png',
        topF: .178, leftF: .410, size: 60, rot: 8, op: .30, phase: 3.2),
    _SplashIcon('assets/images/splash/physical_fitness.png',
        topF: .782, leftF: .615, size: 60, rot: -5, op: .30, phase: 2.3),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xffFAF7F2),
      body: Stack(
        children: [
          // Base warm-cream gradient + soft white wash near the top-centre.
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xffFAF7F2), Color(0xffF2EFE8)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.1,
                  colors: [Colors.white, Color(0x00FFFFFF)],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ),

          // Scattered floating icons.
          ..._icons.map((ic) => _buildFloatingIcon(ic, w, h)),

          // Vignette — focuses the eye on the centre.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Color(0x00FAF7F2),
                      Color(0x4DFAF7F2),
                      Color(0x8CFAF7F2),
                    ],
                    stops: [0.34, 0.62, 0.96],
                  ),
                ),
              ),
            ),
          ),

          // Centre: glow + rotating dashed rings + logo + pill + tagline.
          // Shifted up slightly (Alignment y -0.10) to match the mock's
          // top:47% and leave room for the bottom loader/footer.
          Align(
            alignment: const Alignment(0, -0.10),
            child: _buildCentreStack(),
          ),

          // Bottom loader + signature.
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoaderBar(),
                const SizedBox(height: 12),
                Text(
                  'BUY · SELL · MARKETPLACE',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 2.8,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff8A8F99),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(_SplashIcon ic, double w, double h) {
    final top = ic.topF * h;
    final double? left = ic.leftF != null ? ic.leftF! * w : null;
    final double? right = ic.rightF != null ? ic.rightF! * w : null;
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (context, child) {
          final t = (_floatCtrl.value * 2 * math.pi) + ic.phase;
          final dy = math.sin(t) * 8.0; // ±8px float
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: ic.rot * math.pi / 180,
              child: child,
            ),
          );
        },
        child: Opacity(
          opacity: ic.op,
          child: Image.asset(
            ic.asset,
            width: ic.size,
            height: ic.size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildCentreStack() {
    return SizedBox(
      width: 360,
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Breathing glow.
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (context, child) {
              final v = Curves.easeInOut.transform(_glowCtrl.value);
              final scale = 0.94 + (0.12 * v);
              final opacity = 0.55 + (0.30 * v);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Container(
              width: 330,
              height: 330,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xC7FFFFFF), Color(0x00FFFFFF)],
                  stops: [0.0, 0.65],
                ),
              ),
            ),
          ),

          // Outer dashed ring (violet, slow, reverse).
          AnimatedBuilder(
            animation: _ring2Ctrl,
            builder: (context, child) => Transform.rotate(
              angle: -_ring2Ctrl.value * 2 * math.pi,
              child: child,
            ),
            child: CustomPaint(
              size: const Size(352, 352),
              painter: _DashedCirclePainter(color: const Color(0x387C5CFF)),
            ),
          ),

          // Inner dashed ring (blue).
          AnimatedBuilder(
            animation: _ring1Ctrl,
            builder: (context, child) => Transform.rotate(
              angle: _ring1Ctrl.value * 2 * math.pi,
              child: child,
            ),
            child: CustomPaint(
              size: const Size(312, 312),
              painter: _DashedCirclePainter(color: const Color(0x4D1677FF)),
            ),
          ),

          // Logo + pill + tagline.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/applogonew.png',
                width: 248,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              _buildSwaPill(),
              const SizedBox(height: 20),
              const SizedBox(
                width: 250,
                child: Text(
                  'An AI dealmaker for every listing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: Color(0xff3A3F4A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwaPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff1677FF), Color(0xff7C5CFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff7C5CFF).withOpacity(0.32),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'SELL WITH AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
          ),
          // Shimmer sweep.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (context, child) {
                // Sweep from off-left to off-right, then idle (matches the
                // CSS keyframe that holds at the end for the remainder).
                final p = (_shimmerCtrl.value / 0.55).clamp(0.0, 1.0);
                final dx = -1.2 + (2.4 * p);
                return FractionalTranslation(
                  translation: Offset(dx, 0),
                  child: child,
                );
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0x73FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0.3, 0.5, 0.7],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaderBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 140,
        height: 3,
        color: const Color(0x0F000000),
        child: AnimatedBuilder(
          animation: _loaderCtrl,
          builder: (context, child) {
            final dx = -1.0 + (2.0 * _loaderCtrl.value);
            return FractionalTranslation(
              translation: Offset(dx, 0),
              child: child,
            );
          },
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00FFFFFF),
                  Color(0xff1677FF),
                  Color(0xff7C5CFF),
                  Color(0x00FFFFFF),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────

class _SplashIcon {
  final String asset;
  final double topF;
  final double? leftF;
  final double? rightF;
  final double size;
  final double rot; // degrees
  final double op;
  final double phase; // float animation phase offset (radians)
  const _SplashIcon(
    this.asset, {
    required this.topF,
    this.leftF,
    this.rightF,
    required this.size,
    required this.rot,
    required this.op,
    required this.phase,
  });
}

/// Draws a dashed circle stroke inset within [size]. Flutter has no
/// native dashed border, so the splash halo rings paint their dashes
/// here. The circle is inscribed in the square canvas.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  static const double _dash = 4;
  static const double _gap = 6;
  static const double _strokeWidth = 1;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );
    final path = Path()..addOval(rect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.color != color;
}
