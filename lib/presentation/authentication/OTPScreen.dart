import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../Components/CustomSnackBar.dart';
import '../../data/cubit/LogInWithMobile/login_with_mobile.dart';
import '../../data/cubit/LogInWithMobile/login_with_mobile_state.dart';
import '../../model/VerifyOtpModel.dart';
import '../../services/AuthService.dart';
import '../../services/FcmTokenManager.dart';
import '../../services/MetaEventTracker.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import 'widgets/RateLimitCountdown.dart';

/// OTP verify screen — 2026-05-17 pixel-faithful rebuild of
/// `mockups/onboarding-mocks.html` (variant 2 · Verify OTP).
///
/// Visual contract — identical to the new Login chrome so the user
/// recognises the visual language across the onboarding flow:
///   • Layered radial-gradient background (cool blue top-left, warm
///     yellow bottom-right, on #F4F6FA grey-blue base).
///   • Brand row → eyebrow `VERIFY OTP` → Fraunces serif headline with
///     italic gradient on the words "6-digit code" → masked-number
///     read-back chip with "Change number" pencil link → lifted white
///     card holding the 6-box pin grid + resend meta + animated CTA.
///   • Pill-shaped Verify & Continue button (radius 26 = full pill).
///   • Trust footer at the bottom: "Your code is safe and encrypted".
///
/// Business logic preserved end-to-end:
///   • 6-digit numeric pin field with auto-unfocus on completion.
///   • 30 s resend countdown, then a Resend OTP button that posts to
///     the right cubit method (mobile or email).
///   • Rate-limit mixin blocks Verify + Resend while the server's
///     countdown window is active.
///   • FCM token is fetched non-blockingly before verify (matches the
///     legacy screen — null token still allows login).
///   • verifyMobileSuccess / verifyEmailSuccess → saveTokens + route
///     to /register?from=otp (newUser) or /dashboard.
///   • ACCOUNT_DELETED → /recover_account?recovery_token=…
///   • ACCOUNT_BLOCKED (403) → handled globally by ApiClient.
///   • RATE_LIMITED → startRateLimit(retry).
class Otpscreen extends StatefulWidget {
  final String mobile;
  final String email;
  const Otpscreen({super.key, required this.email, required this.mobile});

  @override
  State<Otpscreen> createState() => _OtpscreenState();
}

class _OtpscreenState extends State<Otpscreen>
    with RateLimitCountdownMixin, SingleTickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  Timer? _timer;
  int _secondsRemaining = 30;

  late final AnimationController _sheenCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  )..repeat();

  // ── Brand palette ───────────────────────────────────────────────────
  static const Color _brandBlue = Color(0xFF1677FF);
  static const Color _brandBlueDeep = Color(0xFF0F5FCE);
  static const Color _brandViolet = Color(0xFF7C5CFF);
  static const Color _lineSoft = Color(0xFFE5E8EE);
  static const Color _mute = Color(0xFF8A8F99);
  static const Color _bgBaseLight = Color(0xFFF4F6FA);
  static const Color _cardLight = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  String? _validateOtp(String otp) {
    if (otp.length < 6) return 'Please enter a 6-digit OTP';
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) return 'OTP must contain only digits';
    return null;
  }

  void _onOtpChanged(String otp) {
    if (_validateOtp(otp) == null && mounted) _otpFocusNode.unfocus();
  }

  void _startTimer() {
    setState(() => _secondsRemaining = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  /// Masked phone for the read-back chip — show the +91 prefix and
  /// the last 4 digits, mask the middle so a shoulder-surfer can't
  /// pick the full number off the screen.
  String get _readbackText {
    if (widget.mobile.isNotEmpty) return '+91 ${widget.mobile}';
    return widget.email;
  }

  bool get _isMobileMode => widget.mobile.isNotEmpty;

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
                            _buildBrandRow(isDark, textColor),
                            const SizedBox(height: 22),
                            _buildHero(textColor),
                            const SizedBox(height: 22),
                            _buildCard(isDark, cardColor, textColor),
                            // Spacer pushes the trust footer flush to
                            // the bottom of the available height.
                            const Spacer(),
                            _buildTrustFooter(),
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

  // ── Layered background wash (matches Login) ──────────────────────────
  // Fade endpoints use the same hue at alpha 0 instead of
  // `Colors.transparent` (= transparent BLACK), which would render a
  // muddy dark blob where the gradient fades. Same fix applied in
  // LoginScreen.
  Widget _buildBackgroundWashes(bool isDark) {
    final coolColor = isDark ? _brandViolet : _brandBlue;
    final warmColor =
        isDark ? _brandViolet : const Color(0xFFFFF4D6);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
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

  // ── Brand row (same recipe as Login) ─────────────────────────────────
  Widget _buildBrandRow(bool isDark, Color textColor) {
    return Row(
      children: [
        // Bare logo — matches LoginScreen. Drops the rounded "box"
        // wrapper. Uses `applogonew.png` because that's the icon-only
        // logo with a transparent background; the source was resized
        // from 15K×7K (2.9 MB) down to 512×234 (≈50 KB) on disk so
        // first paint is instant.
        Image.asset(
          'assets/images/applogonew.png',
          width: 64,
          height: 64,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        // Brand wordmark moved to the right side — mirrors LoginScreen.
        // Replaces the old "Need help?" pill (decorative only, never
        // wired to an action).
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

  // ── Hero block ───────────────────────────────────────────────────────
  // Eyebrow + Fraunces headline with italic gradient on "6-digit code",
  // plus the read-back chip below ("Sent to +91 …" + Change number).
  Widget _buildHero(Color textColor) {
    final accentShader = const LinearGradient(
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
        // 3-step onboarding stepper. OTP is step 2.
        _buildStepper(currentStep: 2),
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
                'VERIFY OTP',
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
              const TextSpan(text: 'Enter the '),
              TextSpan(
                text: '6-digit code',
                style: GoogleFonts.fraunces(
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.6,
                    height: 1.15,
                    foreground: Paint()..shader = accentShader,
                  ),
                ),
              ),
              const TextSpan(text: '\nto continue.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Read-back chip — "Sent to +91 …" + Change number link
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => context.pushReplacement('/login'),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sent to $_readbackText',
                  style: const TextStyle(
                    color: _brandBlue,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 12,
                  color: _brandBlue.withOpacity(0.30),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined,
                    size: 13, color: _brandBlue),
                const SizedBox(width: 4),
                Text(
                  _isMobileMode ? 'Change number' : 'Change email',
                  style: const TextStyle(
                    color: _brandBlue,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 3-bar onboarding stepper. Mirrors LoginScreen._buildStepper.
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

  // ── Form card (pin grid + resend + verify CTA) ───────────────────────
  Widget _buildCard(bool isDark, Color cardColor, Color textColor) {
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
          _buildFieldLabel('ONE-TIME PASSWORD'),
          const SizedBox(height: 8),
          _buildPinField(isDark, textColor),
          const SizedBox(height: 14),
          _buildResendRow(isDark),
          const SizedBox(height: 16),
          _buildVerifyButton(isDark),
          const SizedBox(height: 12),
          _buildFinePrint(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _mute,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildPinField(bool isDark, Color textColor) {
    final pinIdleBorder =
        isDark ? Colors.white.withOpacity(0.10) : _lineSoft;
    final pinActiveBorder = _brandBlue;
    final pinSelectedBorder = _brandBlue;
    final fillColor =
        isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF6F8FC);
    final activeFill = isDark ? Colors.white.withOpacity(0.06) : Colors.white;

    return PinCodeTextField(
      autoUnfocus: true,
      appContext: context,
      controller: _otpController,
      focusNode: _otpFocusNode,
      backgroundColor: Colors.transparent,
      length: 6,
      onChanged: _onOtpChanged,
      animationType: AnimationType.fade,
      hapticFeedbackTypes: HapticFeedbackTypes.heavy,
      cursorColor: _brandBlue,
      keyboardType: TextInputType.number,
      enableActiveFill: true,
      useExternalAutoFillGroup: true,
      beforeTextPaste: (text) => true,
      autoFocus: true,
      autoDismissKeyboard: false,
      showCursor: true,
      pastedTextStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w800,
      ),
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(13),
        fieldHeight: 48,
        fieldWidth: 44,
        fieldOuterPadding: const EdgeInsets.only(right: 4),
        activeFillColor: activeFill,
        selectedFillColor: activeFill,
        inactiveFillColor: fillColor,
        activeColor: pinActiveBorder,
        selectedColor: pinSelectedBorder,
        inactiveColor: pinIdleBorder,
        activeBorderWidth: 1.5,
        selectedBorderWidth: 1.5,
        inactiveBorderWidth: 1.5,
      ),
      textStyle: TextStyle(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction:
          Platform.isAndroid ? TextInputAction.none : TextInputAction.done,
    );
  }

  Widget _buildResendRow(bool isDark) {
    if (_secondsRemaining > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: _mute),
              const SizedBox(width: 6),
              Text.rich(
                TextSpan(
                  style: const TextStyle(color: _mute, fontSize: 12),
                  children: [
                    const TextSpan(text: 'Resend in '),
                    TextSpan(
                      text: '${_secondsRemaining.toString().padLeft(2, '0')} sec',
                      style: TextStyle(
                        color: ThemeHelper.textColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Text(
            'Resend OTP',
            style: TextStyle(
              color: _mute,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    // Timer elapsed — resend is tappable.
    return BlocBuilder<LogInwithMobileCubit, LogInWithMobileState>(
      builder: (context, state) {
        final isLoading = state is LogInwithMobileLoading;
        final blocked = isRateLimited;
        final disabled = isLoading || blocked;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.access_time_rounded, size: 13, color: _mute),
                SizedBox(width: 6),
                Text(
                  'Didn\'t get it?',
                  style: TextStyle(color: _mute, fontSize: 12),
                ),
              ],
            ),
            InkWell(
              onTap: disabled ? null : _onResendTapped,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: _brandBlue,
                        ),
                      )
                    else
                      Icon(
                        blocked
                            ? Icons.lock_clock_rounded
                            : Icons.refresh_rounded,
                        size: 14,
                        color: disabled ? _mute : _brandBlue,
                      ),
                    const SizedBox(width: 5),
                    Text(
                      blocked
                          ? 'Wait $rateLimitMessage'
                          : (isLoading ? 'Sending…' : 'Resend OTP'),
                      style: TextStyle(
                        color: disabled ? _mute : _brandBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        decoration:
                            disabled ? null : TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onResendTapped() {
    if (_isMobileMode) {
      context.read<LogInwithMobileCubit>().postLogInWithMobile({
        'mobile': widget.mobile,
      });
    } else {
      context.read<LogInwithMobileCubit>().postLogInWithEmail({
        'email': widget.email,
      });
    }
    _startTimer();
  }

  // ── Verify & Continue button (pill shape + sliding sheen) ────────────
  Widget _buildVerifyButton(bool isDark) {
    return BlocConsumer<LogInwithMobileCubit, LogInWithMobileState>(
      listener: (context, state) async {
        // Shared handler for mobile + email success states — the only
        // difference between the two branches was the MetaEventTracker
        // method label; centralised here so the mounted-guards and
        // return-after-push safety are written once.
        Future<void> handleVerifySuccess(
          VerifyOtpModel data, {
          required String trackerMethod,
        }) async {
          if (data.success == true) {
            await AuthService.saveTokens(
              data.accessToken ?? "",
              data.user?.name ?? "",
              data.user?.email ?? "",
              data.user?.mobile ?? "",
              data.user?.id ?? "",
              data.refreshToken ?? "",
              data.accessTokenExpiry ?? 0,
              data.newUser ?? false,
              data.user?.state,
              data.user?.city,
              data.user?.stateId,
              data.user?.cityId,
              data.user?.image,
              data.user?.profilePicture,
            );
            if (!context.mounted) return;
            if (data.newUser == true) {
              context.pushReplacement('/register?from=otp');
            } else {
              context.pushReplacement('/dashboard');
            }
            // Fire-and-forget analytics — must run AFTER the
            // navigation so a slow tracker doesn't delay UX.
            MetaEventTracker.login(method: trackerMethod);
            return;
          }

          if (data.code == "ACCOUNT_DELETED") {
            final token = data.recoveryToken ?? '';
            if (token.isEmpty) {
              CustomSnackBar1.show(
                context,
                data.message ??
                    'Account recovery unavailable. Contact support.',
              );
              return;
            }
            context.pushReplacement(
              "/recover_account?recovery_token=${Uri.encodeComponent(token)}",
            );
            return;
          }
          // ACCOUNT_BLOCKED (HTTP 403) is handled globally by
          // ApiClient's 403 interceptor (routes to /blocked_account).
          // Navigating here would double-push.
          if (data.code == "RATE_LIMITED") {
            final retry = data.retryAfterSec;
            if (retry != null && retry > 0) startRateLimit(retry);
          }
          CustomSnackBar1.show(context, data.message ?? "");
        }

        if (state is verifyMobileSuccess) {
          await handleVerifySuccess(
            state.verifyOtpModel,
            trackerMethod: "mobile",
          );
        } else if (state is verifyEmailSuccess) {
          await handleVerifySuccess(
            state.verifyOtpModel,
            trackerMethod: "email",
          );
        } else if (state is OtpVerifyFailure) {
          CustomSnackBar1.show(context, state.error);
        } else if (state is LogInwithMobileSuccess ||
            state is LogInwithEmailSuccess) {
          // Fresh resend → clear any stale countdown.
          clearRateLimit();
        } else if (state is LogInwithMobileFailure) {
          final retry = state.retryAfterSec;
          if (retry != null && retry > 0) startRateLimit(retry);
          CustomSnackBar1.show(context, state.error);
        }
      },
      builder: (context, state) {
        final loading = state is verifyWithMobileLoading;
        final blocked = isRateLimited;
        final label = blocked
            ? 'Try again in $rateLimitMessage'
            : (loading ? 'Verifying…' : 'Verify & Continue');

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: (loading || blocked) ? null : _onVerifyPressed,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Ink(
                  decoration: BoxDecoration(
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
                                    : Icons.verified_rounded,
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

  // ── Verify handler — exact same flow as the legacy screen ────────────
  // Validate the OTP locally BEFORE we spend 3-8 s fetching the FCM
  // token; malformed OTPs should fail instantly without hanging on
  // token provisioning. Token is non-blocking either way (null token
  // is fine — push just stays off until permission is granted).
  void _onVerifyPressed() async {
    final otp = _otpController.text.trim();
    final msg = _validateOtp(otp);
    if (msg != null) {
      CustomSnackBar.show(context, msg);
      return;
    }
    final String? fcmToken = await FcmTokenManager.ensureFcmToken();
    if (!mounted) return;

    if (_isMobileMode) {
      context.read<LogInwithMobileCubit>().verifyLoginOtp({
        "mobile": widget.mobile,
        "otp": otp,
        "fcm_token": fcmToken ?? "",
        "fcm_type": "app",
      });
    } else {
      context.read<LogInwithMobileCubit>().verifyEmailLoginOtp({
        "email": widget.email,
        "otp": otp,
        "fcm_token": fcmToken ?? "",
        "fcm_type": "app",
      });
    }
  }

  Widget _buildFinePrint() {
    return Text.rich(
      TextSpan(
        text: "Didn't get the SMS? Check your spam folder, then tap ",
        style: const TextStyle(color: _mute, fontSize: 11, height: 1.5),
        children: [
          const TextSpan(
            text: 'Resend OTP',
            style: TextStyle(
              color: _brandBlue,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.lock_outline_rounded, size: 13, color: _mute),
        SizedBox(width: 6),
        Text(
          'Your code is safe and encrypted',
          style: TextStyle(
            color: _mute,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
