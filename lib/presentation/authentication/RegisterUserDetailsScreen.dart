import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:classifieds/Components/CustomSnackBar.dart';
// Onboarding Option A (2026-04-15): GoogleAuthCubit is NO LONGER used on
// this screen. The Google button is a LOCAL pre-filler — it calls the
// GoogleSignIn SDK directly, populates the form fields, and stashes the
// idToken + photoUrl to forward through the existing RegisterCubit call.
// No backend /app/google-auth endpoint is hit. The cubit files under
// data/cubit/GoogleAuth/ are left in place as dead code for easy revert.
import 'package:classifieds/data/cubit/Register/register_cubit.dart';
import 'package:classifieds/data/cubit/Register/register_states.dart';
import 'package:classifieds/services/AuthService.dart';

import '../../Components/ShakeWidget.dart';
import '../../data/cubit/States/states_cubit.dart';
import '../../data/cubit/States/states_repository.dart';
import '../../data/remote_data_source.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../widgets/SelectStateBottomSheet.dart';

/// Register screen — 2026-05-17 pixel-faithful rebuild of
/// `mockups/onboarding-mocks.html` (variant 3 · Register User Details).
///
/// Visual contract — identical chrome to Login / OTP:
///   • Layered radial-gradient background (cool blue top-left, warm
///     yellow bottom-right, on #F4F6FA grey-blue base).
///   • Brand row with the Logout iconbutton on the LEFT and the
///     "Register User Details" title (the existing copy stays).
///   • 3/3 stepper → "ALMOST THERE" eyebrow → Fraunces serif headline
///     with italic gradient on "set up" → lifted white card holding
///     Continue with Google → OR divider → optional pre-fill banner →
///     Full Name → Email → State picker → pill Submit button → trust
///     footer pinned at the bottom.
///
/// Business logic preserved EXACTLY:
///   • PopScope(canPop:false) — Bug #4 guard against system back
///     dropping the user on a dashboard with an empty profile.
///   • Logout escape hatch — `AuthService.logout()` clears tokens +
///     routes to /login (only legit way out of a half-registered state).
///   • Google sign-in is a LOCAL pre-filler. idToken + photoUrl are
///     stashed; forwarded to /app/register-user-details so the backend
///     verifies the idToken and atomically attaches email_verified +
///     googleId + authProvider + profilePicture.
///   • Email-change listener clears the stashed Google token + picture
///     when the user manually edits the pre-filled email — keeps the
///     forwarded idToken bound to the actual email being registered.
///   • State picker bottom sheet (SelectStateBottomSheet + cubit).
///   • ShakeWidget + red error text on state-required violation.
///   • Double-submit guard via the _submitting flag.
///   • On RegisterLoaded: setProfilePicture(_googlePictureUrl) +
///     setUserStatus("false") AWAITED before navigating, so the
///     dashboard sees fresh isNewUser=false on first render.
///   • widget.from == "ad" → context.pop() back to the post-ad flow;
///     otherwise pushReplacement('/dashboard').
class RegisterUserDetailsScreen extends StatefulWidget {
  final String from;
  const RegisterUserDetailsScreen({super.key, required this.from});
  @override
  State<RegisterUserDetailsScreen> createState() =>
      _RegisterUserDetailsScreenState();
}

class _RegisterUserDetailsScreenState extends State<RegisterUserDetailsScreen>
    with SingleTickerProviderStateMixin {
  // ── Form state ──────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: '');
  final _emailCtrl = TextEditingController(text: '');
  final stateController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  bool _showStateError = false;
  int? selectedStateId;
  bool _submitting = false;
  bool _googleLoading = false;

  // Stashed from the local Google SDK call when the user taps "Continue
  // with Google". Forwarded to the backend on _submit() so the register
  // endpoint can verify the idToken server-side and atomically set
  // email_verified + googleId + authProvider + profilePicture. See the
  // doc comment on handler/onboarding/user.js →
  // updateUserDetailsByUserInRegister for the full flow.
  String? _googleIdToken;
  String? _googlePictureUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Explicit 'profile' scope ensures Google's ID token payload carries
    // `name` and `picture` claims. Without it, the default `['email']`
    // scope sometimes returns an ID token with only `sub` + `email` +
    // `email_verified`, which drops the name + photoUrl — exactly the
    // regression we chased earlier in this session.
    scopes: const ['email', 'profile'],
    serverClientId:
        '11012475744-m162f66s0f949gujiq2l596p4gv3v4bj.apps.googleusercontent.com',
  );

  // ── Brand palette (matches Login + OTP) ──────────────────────────────
  static const Color _brandBlue = Color(0xFF1677FF);
  static const Color _brandBlueDeep = Color(0xFF0F5FCE);
  static const Color _brandViolet = Color(0xFF7C5CFF);
  static const Color _lineSoft = Color(0xFFE5E8EE);
  static const Color _mute = Color(0xFF8A8F99);
  static const Color _bgBaseLight = Color(0xFFF4F6FA);
  static const Color _cardLight = Color(0xFFFFFFFF);

  // Continuous sliding-sheen for the Submit CTA — same motion language
  // as Login's Send OTP and OTP's Verify & Continue.
  late final AnimationController _sheenCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // If the user edits the pre-filled email, drop the stashed Google
    // idToken + picture. Without this, we'd forward Google's idToken
    // (bound to alice@gmail.com) to the register endpoint alongside a
    // manually-typed bob@example.com.
    _emailCtrl.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    if (_googleIdToken == null && _googlePictureUrl == null) return;
    final typed = _emailCtrl.text.trim().toLowerCase();
    final google = _googleSignIn.currentUser?.email.toLowerCase();
    if (google == null || typed.isEmpty || typed != google) {
      setState(() {
        _googleIdToken = null;
        _googlePictureUrl = null;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_onEmailChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    stateController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  /// Onboarding Option A — LOCAL pre-filler only. No backend call.
  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      // Only force the account picker when the user's currently-signed-in
      // Google account differs from whatever's in the email field.
      final current = _googleSignIn.currentUser;
      final typedEmail = _emailCtrl.text.trim().toLowerCase();
      if (current != null &&
          typedEmail.isNotEmpty &&
          current.email.toLowerCase() != typedEmail) {
        await _googleSignIn.signOut();
      }
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _googleLoading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        setState(() => _googleLoading = false);
        if (mounted) {
          CustomSnackBar1.show(context, 'Google sign-in failed. Try again.');
        }
        return;
      }

      if (!mounted) return;
      _nameCtrl.text = account.displayName ?? '';
      _emailCtrl.text = account.email;
      setState(() {
        _googleIdToken = idToken;
        _googlePictureUrl = account.photoUrl;
        _googleLoading = false;
      });
      CustomSnackBar1.show(
        context,
        'Google details filled in. Pick your state and tap Submit.',
      );
    } catch (e) {
      setState(() => _googleLoading = false);
      if (mounted) CustomSnackBar1.show(context, 'Google sign-in error: $e');
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (selectedStateId == null || stateController.text.trim().isEmpty) {
      setState(() => _showStateError = true);
      return;
    }
    setState(() {
      _showStateError = false;
      _submitting = true;
    });

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'state_id': selectedStateId,
      if (_googleIdToken != null) 'idToken': _googleIdToken,
      if (_googlePictureUrl != null) 'profilePicture': _googlePictureUrl,
    };

    context.read<RegisterCubit>().register(data);
  }

  String? _validateName(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Please enter your name';
    if (t.length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w\.\-+%]+@[\w\.\-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(t)) return 'Enter a valid email address';
    return null;
  }

  Future<void> _onStateTapped() async {
    final selectedState = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocProvider(
          create: (_) => SelectStatesCubit(
            SelectStatesImpl(remoteDataSource: RemoteDataSourceImpl()),
          ),
          child: const SelectStateBottomSheet(),
        );
      },
    );
    if (selectedState != null) {
      stateController.text = selectedState.name ?? '';
      selectedStateId = selectedState.id;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = isDark ? const Color(0xFF1A1F2E) : _cardLight;
    final bgBase = isDark ? const Color(0xFF0E1116) : _bgBaseLight;

    return PopScope(
      canPop: false,
      child: Scaffold(
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
      ),
    );
  }

  // ── Layered background wash (identical to Login/OTP) ─────────────────
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

  // ── Brand row (Logout left, title centred) ──────────────────────────
  // Mock variant 3 swaps the "Need help?" pill for a "Register User
  // Details" title row, since the user can't bail out to help here —
  // their only legit exit is the logout icon (sets up _signOut + go
  // back to /login). The right side keeps a 34px spacer so the centred
  // title is genuinely centred.
  Widget _buildBrandRow(bool isDark, Color textColor) {
    return Row(
      children: [
        Material(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () async {
              // Clears the cached token + profile and routes to /login
              // via navigatorKey. Bug #4 escape hatch — the only way
              // out of a half-registered state.
              await AuthService.logout();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : _lineSoft,
                ),
              ),
              child: Icon(Icons.logout_rounded,
                  size: 18, color: textColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Register ',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const TextSpan(
                    text: 'User Details',
                    style: TextStyle(
                      color: _brandBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 38px spacer so the title is genuinely centred (matches the
        // logout button on the left).
        const SizedBox(width: 38),
      ],
    );
  }

  // ── Hero block ───────────────────────────────────────────────────────
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
        _buildStepper(currentStep: 3),
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
                'ALMOST THERE',
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
              const TextSpan(text: "Let's get you "),
              TextSpan(
                text: 'set up',
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
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Provide your name and email to continue.',
          style: TextStyle(
            color: _mute,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// 3-bar onboarding stepper. Mirrors Login + OTP.
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
  Widget _buildCard(bool isDark, Color cardColor, Color textColor) {
    final showPrefillBanner = _googleIdToken != null;
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
          _buildGoogleButton(isDark, textColor),
          const SizedBox(height: 4),
          const Text(
            'Fills your name & email automatically. You can still edit anything below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mute,
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildOrDivider(isDark),
          const SizedBox(height: 12),
          if (showPrefillBanner) ...[
            _buildPrefillBanner(),
            const SizedBox(height: 12),
          ],
          _buildFieldLabel('FULL NAME'),
          const SizedBox(height: 8),
          _buildNameField(isDark, textColor),
          const SizedBox(height: 12),
          _buildFieldLabel('EMAIL ADDRESS'),
          const SizedBox(height: 8),
          _buildEmailField(isDark, textColor),
          const SizedBox(height: 12),
          _buildFieldLabel('STATE'),
          const SizedBox(height: 8),
          _buildStateField(isDark, textColor),
          if (_showStateError) ...[
            const SizedBox(height: 6),
            ShakeWidget(
              key: const Key('state'),
              duration: const Duration(milliseconds: 700),
              child: const Text(
                'Please Select State',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _buildSubmitButton(),
          const SizedBox(height: 10),
          const Text(
            "You can edit any of this later from Profile → Edit.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mute,
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
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

  Widget _buildGoogleButton(bool isDark, Color textColor) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: _googleLoading ? null : _signInWithGoogle,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.10) : _lineSoft,
                width: 1.5,
              ),
            ),
            child: Center(
              child: _googleLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _brandBlue,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 18,
                          width: 18,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.g_mobiledata,
                                  size: 22, color: Colors.red),
                        ),
                        const SizedBox(width: 11),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider(bool isDark) {
    final line = isDark ? Colors.white.withOpacity(0.08) : _lineSoft;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: line)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR FILL IN MANUALLY',
            style: TextStyle(
              color: _mute,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: line)),
      ],
    );
  }

  Widget _buildPrefillBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFF0E2B0)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/google_logo.png',
            width: 14,
            height: 14,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.g_mobiledata, size: 16, color: Colors.red),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: Color(0xFF5A4A1A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: 'Pre-filled from Google.',
                    style: TextStyle(
                      color: Color(0xFF2A2210),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: ' Tap any field to edit.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Text fields ──────────────────────────────────────────────────────
  BoxDecoration _fieldDeco(bool isDark) => BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : _lineSoft,
          width: 1.5,
        ),
      );

  Widget _buildNameField(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: _fieldDeco(isDark),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, size: 18, color: _mute),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: _validateName,
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
                hintText: 'Enter your full name',
                hintStyle: TextStyle(
                  color: _mute,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 13),
                isDense: true,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: _fieldDeco(isDark),
      child: Row(
        children: [
          const Icon(Icons.alternate_email_rounded, size: 18, color: _mute),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
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
                isDense: true,
                filled: false,
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateField(bool isDark, Color textColor) {
    final hasValue = stateController.text.trim().isNotEmpty;
    return InkWell(
      onTap: _onStateTapped,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _fieldDeco(isDark),
        child: Row(
          children: [
            const Icon(Icons.location_city_outlined, size: 18, color: _mute),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? stateController.text : 'Select your state',
                style: TextStyle(
                  color: hasValue ? textColor : _mute,
                  fontSize: 14.5,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: _mute),
          ],
        ),
      ),
    );
  }

  // ── Submit button (pill + sliding sheen, same as Login/OTP) ──────────
  Widget _buildSubmitButton() {
    return BlocConsumer<RegisterCubit, RegisterStates>(
      listener: (context, state) async {
        if (state is RegisterLoaded) {
          // Persist the stashed Google picture URL to the cached auth
          // data so the Dashboard's first render has the right avatar
          // — no need to wait for a getMyProfileDetails round-trip.
          // Silently no-ops when _googlePictureUrl is null (manual
          // registration path).
          await AuthService.setProfilePicture(_googlePictureUrl);
          // Await the subscription flag write BEFORE navigating — the
          // Dashboard's first render reads isNewUser, and a fire-and-
          // forget call here produced a race where the Dashboard saw
          // the stale "true" value and disabled the Post-Ad CTA on
          // freshly-registered users.
          await AuthService.setUserStatus('false');
          if (!context.mounted) return;
          if (widget.from == 'ad') {
            context.pop();
          } else {
            context.pushReplacement('/dashboard');
          }
        } else if (state is RegisterFailure) {
          CustomSnackBar1.show(context, state.error);
        }
        if (state is RegisterLoaded || state is RegisterFailure) {
          setState(() => _submitting = false);
        }
      },
      builder: (context, state) {
        final isLoading = state is RegisterLoading || _submitting;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: isLoading ? null : _submit,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [_brandBlue, _brandBlueDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _brandBlue.withOpacity(0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
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
                            if (isLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            const SizedBox(width: 9),
                            Text(
                              isLoading ? 'Submitting…' : 'Get me started',
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

  Widget _buildTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.lock_outline_rounded, size: 13, color: _mute),
        SizedBox(width: 6),
        Text(
          'Your details are private & encrypted at rest',
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
