import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:classifieds/Components/CustomSnackBar.dart';
import 'package:classifieds/data/cubit/LogInWithMobile/login_with_mobile.dart';
import 'package:classifieds/data/cubit/LogInWithMobile/login_with_mobile_state.dart';
import 'package:classifieds/presentation/authentication/widgets/RateLimitCountdown.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

/// Login screen — 2026-05-17 pixel-faithful rebuild of
/// `mockups/onboarding-mocks.html` (variant 1A · Mobile / 1B · Email).
///
/// Visual contract:
///   • Layered radial-gradient background (cool blue top-left, warm
///     yellow bottom-right, on #F4F6FA grey-blue base).
///   • Brand row → eyebrow chip → Fraunces serif headline with italic
///     gradient on the word "journey" → lifted white card holding a
///     Mobile / Email tab toggle + the form + an animated CTA → terms
///     fine print → trust footer.
///   • CTA carries a continuous sliding sheen on a 4.5 s loop.
///
/// Logic preserved end-to-end:
///   • Mobile path: `postLogInWithMobile` → `/otp?mobile=...`
///   • Email path: `postLogInWithEmail`  → `/otp?email=...`
///   • Rate-limit countdown via [RateLimitCountdownMixin]; the Send
///     OTP button greys with "Try again in Xs" while blocked.
///   • `listenWhen` guard prevents the navigation-loop bug when the
///     user returns to Login with the cubit still holding Success.
///   • Email-not-registered failure surfaces via a dialog.
///
/// Replaces the previous gradient-full-screen layout AND the legacy
/// "OR Login With Email" text link.
class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen>
    with RateLimitCountdownMixin, SingleTickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Opens the in-app Terms & Conditions page from the legal fine print.
  late final TapGestureRecognizer _termsRecognizer =
      TapGestureRecognizer()..onTap = () => context.push('/terms');

  /// false → Mobile mode (default). true → Email mode.
  bool _isEmailMode = false;

  late final AnimationController _sheenCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  )..repeat();

  // ── Brand palette (light) ────────────────────────────────────────────
  static const Color _brandBlue = Color(0xFF1677FF);
  static const Color _brandBlueDeep = Color(0xFF0F5FCE);
  static const Color _brandViolet = Color(0xFF7C5CFF);
  static const Color _lineSoft = Color(0xFFE5E8EE);
  static const Color _mute = Color(0xFF8A8F99);
  static const Color _bgBaseLight = Color(0xFFF4F6FA);
  static const Color _cardLight = Color(0xFFFFFFFF);

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _sheenCtrl.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  void _onSendOtpPressed() {
    if (_isEmailMode) {
      final email = _emailController.text.trim().toLowerCase();
      if (email.isEmpty) {
        CustomSnackBar.show(context, 'Email is required');
        return;
      }
      if (!RegExp(r'^[\w-\.\+]+@([\w-]+\.)+[A-Za-z]{2,}$').hasMatch(email)) {
        CustomSnackBar.show(context, 'Enter a valid email');
        return;
      }
      context.read<LogInwithMobileCubit>().postLogInWithEmail({'email': email});
    } else {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        CustomSnackBar.show(context, 'Phone number is required');
        return;
      }
      if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
        CustomSnackBar.show(context, 'Enter a valid 10-digit phone number');
        return;
      }
      context.read<LogInwithMobileCubit>().postLogInWithMobile({'mobile': phone});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = isDark ? const Color(0xFF1A1F2E) : _cardLight;
    final bgBase = isDark ? const Color(0xFF0E1116) : _bgBaseLight;

    return Scaffold(
      backgroundColor: bgBase,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundWashes(isDark),
          SafeArea(
            // LayoutBuilder + ConstrainedBox + IntrinsicHeight gives
            // the Column a known max height so we can use a Spacer to
            // push the trust footer flush to the bottom (matching the
            // mock's `margin-top: auto` on `.trust`). The Scrollable
            // wrapper handles keyboard-open overflow.
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            _buildBrandRow(context, isDark, textColor),
                            const SizedBox(height: 22),
                            _buildHero(context, textColor),
                            const SizedBox(height: 36),
                            _buildCard(context, isDark, cardColor, textColor),
                            // Spacer pushes the trust footer to the
                            // bottom of the available height.
                            const Spacer(),
                            _buildTrustFooter(context),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Layered background wash ──────────────────────────────────────────
  // Two radial gradients on top of the base colour. Each fades from the
  // hue colour to the SAME hue with alpha 0 — never `Colors.transparent`
  // (= transparent BLACK), which would interpolate through muddy dark
  // tones and produce a dark blob at the gradient's fade edge (the
  // bottom-right "dark shade" bug the user spotted).
  Widget _buildBackgroundWashes(bool isDark) {
    final coolColor = isDark ? _brandViolet : _brandBlue;
    final warmColor =
        isDark ? _brandViolet : const Color(0xFFFFF4D6);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cool radial — top-left
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.1, -1.1),
                radius: 1.6,
                colors: [
                  coolColor.withOpacity(isDark ? 0.18 : 0.12),
                  coolColor.withOpacity(0),
                ],
                stops: const [0.0, 0.55],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          // Warm radial — bottom-right
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.1, 1.1),
                radius: 1.6,
                colors: [
                  warmColor.withOpacity(isDark ? 0.14 : 1.0),
                  warmColor.withOpacity(0),
                ],
                stops: const [0.0, 0.55],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          // Tighter hero wash — concentrated at the top.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 340,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -1),
                  radius: 1.0,
                  colors: [
                    _brandViolet.withOpacity(isDark ? 0.16 : 0.08),
                    _brandViolet.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Brand row ────────────────────────────────────────────────────────
  Widget _buildBrandRow(BuildContext context, bool isDark, Color textColor) {
    return Row(
      children: [
        // Bare logo — no rounded box wrapper. The asset is
        // `applogonew.png` because it's the only icon-only logo with a
        // transparent background (the other "logo.png" / "appLogo.png"
        // assets are branded panels with white backgrounds that don't
        // sit cleanly on a dark scaffold). It's a heavy file (2.9 MB /
        // 15K×7K source), which is why the splash precaches it — see
        // SplashScreen.didChangeDependencies.
        Image.asset(
          'assets/images/applogonew.png',
          width: 64,
          height: 64,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        // Brand wordmark moved from beside the logo to the right side
        // — replaces the old "Need help?" pill (which had no actual
        // action wired). The blue dot after "IndClassifieds" is the
        // existing brand accent kept from the previous layout.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'IndClassifieds',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const TextSpan(
                text: '.',
                style: TextStyle(
                  color: _brandBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero block (eyebrow + Fraunces serif headline) ───────────────────
  // The headline is Fraunces serif. The word "journey" is italic and
  // painted with a blue→violet horizontal gradient via a Paint shader
  // on its TextSpan — matches the mock's `em` element exactly.
  Widget _buildHero(BuildContext context, Color textColor) {
    // The shader needs a fixed Rect; the 500x80 box is generous enough
    // for the word "journey" at 28 px italic, and the gradient is
    // direction-only (left-to-right) so absolute size doesn't matter.
    final journeyShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [_brandBlue, _brandViolet],
    ).createShader(const Rect.fromLTWH(0, 0, 500, 80));

    final headlineStyle = GoogleFonts.fraunces(
      textStyle: TextStyle(
        color: textColor,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        height: 1.15,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3-step onboarding stepper. Login is step 1.
        _buildStepper(currentStep: 1),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _brandBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'SIGN IN',
                style: TextStyle(
                  color: _brandBlue,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: headlineStyle,
            children: [
              const TextSpan(text: 'Login to continue\nyour '),
              TextSpan(
                text: 'journey',
                style: GoogleFonts.fraunces(
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.6,
                    height: 1.15,
                    foreground: Paint()..shader = journeyShader,
                  ),
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }

  /// 3-bar onboarding stepper. Bars before `currentStep` render done
  /// (blue→violet gradient), the current bar is solid brand blue, and
  /// later bars are muted. Matches the `.stepper` element from the
  /// onboarding mock.
  Widget _buildStepper({required int currentStep}) {
    Widget bar(int i) {
      final bool done = i < currentStep;
      final bool current = i == currentStep;
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: done
                ? null
                : (current ? _brandBlue : const Color(0xFFE5E8EE)),
            gradient: done
                ? const LinearGradient(colors: [_brandBlue, _brandViolet])
                : null,
          ),
        ),
      );
    }

    return Row(
      children: [
        bar(1),
        bar(2),
        bar(3),
        const SizedBox(width: 6),
        Text(
          '$currentStep / 3',
          style: const TextStyle(
            color: _mute,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Form card ────────────────────────────────────────────────────────
  Widget _buildCard(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : _lineSoft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.32 : 0.08),
            blurRadius: 60,
            offset: const Offset(0, 30),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabs(isDark, textColor),
          const SizedBox(height: 14),
          _buildFieldLabel(_isEmailMode ? 'Email Address' : 'Mobile Number'),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isEmailMode
                ? _buildEmailField(isDark, textColor)
                : _buildPhoneField(isDark, textColor),
          ),
          const SizedBox(height: 10),
          _buildHelper(),
          const SizedBox(height: 16),
          _buildSendOtpButton(isDark, textColor),
          const SizedBox(height: 14),
          _buildLegal(textColor),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : _lineSoft,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              label: 'Mobile',
              icon: Icons.smartphone_rounded,
              active: !_isEmailMode,
              onTap: () {
                if (_isEmailMode && mounted) {
                  setState(() {
                    _isEmailMode = false;
                    _emailController.clear();
                  });
                }
              },
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTab(
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              active: _isEmailMode,
              onTap: () {
                if (!_isEmailMode && mounted) {
                  setState(() {
                    _isEmailMode = true;
                    _phoneController.clear();
                  });
                }
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: active
          ? (isDark ? Colors.white.withOpacity(0.08) : Colors.white)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _brandBlue.withOpacity(0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? _brandBlue : _mute,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? _brandBlue : _mute,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _mute,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }

  // ── Phone field ──────────────────────────────────────────────────────
  // Country code pill on the left (matches mock: flag emoji + +91 +
  // chevron), then the 10-digit numeric field on the right.
  Widget _buildPhoneField(bool isDark, Color textColor) {
    return Container(
      key: const ValueKey('phone-field'),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : _lineSoft,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(11),
              ),
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.08) : _lineSoft,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indian flag — three coloured stripes drawn inline so
                // we don't depend on emoji-font flag rendering (which
                // shows "IN" letters on most Android stock fonts).
                _buildIndianFlag(),
                const SizedBox(width: 8),
                Text(
                  '+91',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: _mute),
              ],
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
              // ALL border slots set to none so the TextFormField
              // doesn't paint its own outline on top of the outer
              // Container's border (was showing as a nested box).
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'Enter 10-digit number',
                hintStyle: TextStyle(
                  color: _mute,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Inline Indian flag — three horizontal stripes (saffron, white,
  /// green) with a tiny dharma chakra in the middle. Doesn't depend
  /// on the platform's flag-emoji rendering.
  Widget _buildIndianFlag() {
    return Container(
      width: 22,
      height: 16,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(color: const Color(0xFFFF9933)),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(color: Colors.white),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF000080),
                      width: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(color: const Color(0xFF138808)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(bool isDark, Color textColor) {
    return Container(
      key: const ValueKey('email-field'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : _lineSoft,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.alternate_email_rounded, size: 18, color: _mute),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                color: textColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'name@example.com',
                hintStyle: TextStyle(
                  color: _mute,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 13),
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelper() {
    final text = _isEmailMode
        ? "We'll send a 6-digit OTP to this email."
        : "We'll send a 6-digit OTP to this number.";
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 13, color: _mute),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _mute,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Send OTP button (with sliding sheen) ─────────────────────────────
  Widget _buildSendOtpButton(bool isDark, Color textColor) {
    return BlocConsumer<LogInwithMobileCubit, LogInWithMobileState>(
      listenWhen: (prev, next) =>
          ((next is LogInwithMobileSuccess ||
                  next is LogInwithEmailSuccess) &&
              prev is LogInwithMobileLoading) ||
          (next is LogInwithMobileFailure && prev is LogInwithMobileLoading),
      listener: (context, state) async {
        if (state is LogInwithMobileSuccess) {
          clearRateLimit();
          context.pushReplacement('/otp?mobile=${_phoneController.text}');
        } else if (state is LogInwithEmailSuccess) {
          clearRateLimit();
          context.pushReplacement(
            '/otp?email=${_emailController.text.trim().toLowerCase()}',
          );
        } else if (state is LogInwithMobileFailure) {
          final retry = state.retryAfterSec;
          if (retry != null && retry > 0) {
            startRateLimit(retry);
            CustomSnackBar.show(
              context,
              state.error.isNotEmpty
                  ? state.error
                  : 'Too many attempts. Try again shortly.',
            );
          } else if (_isEmailMode) {
            _showNotRegisteredDialog(context, state.error);
          } else {
            CustomSnackBar.show(
              context,
              state.error.isNotEmpty
                  ? state.error
                  : 'Failed to send OTP. Try again.',
            );
          }
        }
      },
      builder: (context, state) {
        final bool loading = state is LogInwithMobileLoading;
        final bool blocked = isRateLimited;
        final String label = blocked
            ? 'Try again in $rateLimitMessage'
            : (loading ? 'Sending OTP...' : 'Send OTP');
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: (loading || blocked) ? null : _onSendOtpPressed,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Ink(
                  decoration: BoxDecoration(
                    // Explicit pill radius on the BoxDecoration so the
                    // shadow follows the curve instead of painting a
                    // rectangular halo behind the clipped pill.
                    borderRadius: BorderRadius.circular(26),
                    gradient: blocked
                        ? LinearGradient(
                            colors: [
                              Colors.grey.shade500,
                              Colors.grey.shade700,
                            ],
                          )
                        : const LinearGradient(
                            colors: [_brandBlue, _brandBlueDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: blocked
                        ? const []
                        : [
                            BoxShadow(
                              color: _brandBlue.withOpacity(0.32),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Stack(
                    children: [
                      if (!blocked)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _sheenCtrl,
                            builder: (context, _) {
                              return FractionalTranslation(
                                translation: Offset(
                                  -1.0 + 2.0 * _sheenCtrl.value,
                                  0,
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        Color(0x55FFFFFF),
                                        Colors.transparent,
                                      ],
                                      stops: [0.3, 0.5, 0.7],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (loading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                blocked
                                    ? Icons.lock_clock_rounded
                                    : Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            const SizedBox(width: 9),
                            Text(
                              label,
                              style: AppTextStyles.titleMedium(Colors.white)
                                  .copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegal(Color textColor) {
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: const TextStyle(
          color: _mute,
          fontSize: 11,
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: 'Terms & Conditions',
            recognizer: _termsRecognizer,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTrustFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline_rounded, size: 13, color: _mute),
        const SizedBox(width: 6),
        Text(
          _isEmailMode
              ? 'Encrypted end-to-end · Your email is never shared'
              : 'Encrypted end-to-end · Your number is never shared',
          style: const TextStyle(
            color: _mute,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Two distinct cases land here from /send-otp-email:
  //   • USER_NOT_FOUND      → "Email not found"        → "Account not registered"
  //   • EMAIL_NOT_VERIFIED  → "Email is not verified"  → "Email not verified"
  // We branch on the message text since the cubit doesn't propagate the
  // error code. Body copy is tailored to each case so the user understands
  // why mobile login is being suggested.
  void _showNotRegisteredDialog(BuildContext context, String error) {
    final textColor = ThemeHelper.textColor(context);
    final isNotVerified = error.toLowerCase().contains('not verified');
    final title = isNotVerified
        ? 'Email not verified'
        : 'Account not registered';
    final body = isNotVerified
        ? 'This email is registered but hasn\'t been verified yet. '
            'Please log in using your mobile number — you can verify '
            'this email later from Profile → Verify Email.'
        : (error.isNotEmpty
            ? '$error. Try logging in with your mobile number instead.'
            : 'No account is registered with this email. Try logging in with your mobile number instead.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: AppTextStyles.titleLarge(textColor).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          body,
          style: AppTextStyles.bodyMedium(textColor.withOpacity(.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: _brandBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
