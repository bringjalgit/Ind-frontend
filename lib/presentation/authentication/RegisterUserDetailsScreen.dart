import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
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
import 'package:classifieds/theme/app_colors.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../Components/ShakeWidget.dart';
import '../../data/cubit/EmailVerification/EmailVerificationCubit.dart';
import '../../data/cubit/EmailVerification/EmailVerificationStates.dart';
import '../../data/cubit/States/states_cubit.dart';
import '../../data/cubit/States/states_repository.dart';
import '../../data/remote_data_source.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../widgets/CommonTextField.dart';
import '../../widgets/SelectStateBottomSheet.dart';

class RegisterUserDetailsScreen extends StatefulWidget {
  final String from;
  const RegisterUserDetailsScreen({super.key, required this.from});
  @override
  State<RegisterUserDetailsScreen> createState() =>
      _RegisterUserDetailsScreenState();
}

class _RegisterUserDetailsScreenState extends State<RegisterUserDetailsScreen> {
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
    serverClientId: '11012475744-m162f66s0f949gujiq2l596p4gv3v4bj.apps.googleusercontent.com',
  );

  /// Onboarding Option A — LOCAL pre-filler only. No backend call.
  ///
  /// Flow:
  ///   1. Open the Google account picker via GoogleSignIn SDK.
  ///   2. If user cancels, restore loading state and exit silently.
  ///   3. On success, read displayName/email/photoUrl/idToken from the
  ///      GoogleSignInAccount.
  ///   4. Write displayName + email into the form's text controllers so
  ///      the user sees the pre-filled fields.
  ///   5. Stash idToken + photoUrl in widget state so _submit() can
  ///      forward them to POST /app/register-user-details.
  ///   6. Show a snackbar reminding the user to pick a state and submit.
  ///
  /// Deliberately does NOT:
  ///   - Call /app/google-auth (commented out in serverless.onboarding.yml)
  ///   - Touch GoogleAuthCubit (left as dead code for easy revert)
  ///   - Fetch the FCM token (not needed on this code path — the mobile
  ///     OTP flow already delivered it when the user signed in upstream)
  ///   - Call AuthService.saveTokens (the user's auth session was
  ///     established by the mobile OTP that led them here; we only need
  ///     to update the profilePicture cache after a successful submit)
  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await _googleSignIn.signOut(); // ensure fresh sign-in picker
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _googleLoading = false);
        return; // user cancelled
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        // ID token is essential for the email_verified boost on the
        // backend. Without it we can still pre-fill the form but the
        // user's email won't be marked verified — they'd need to verify
        // via the Profile → Verify Email flow later. Rather than
        // silently degrade, surface the failure so the user knows to
        // retry.
        setState(() => _googleLoading = false);
        if (mounted) {
          CustomSnackBar1.show(
            context,
            "Google sign-in failed. Try again.",
          );
        }
        return;
      }

      if (!mounted) return;
      // Pre-fill form fields. displayName may be null for some Google
      // accounts (though uncommon with `profile` scope); photoUrl is
      // also nullable.
      _nameCtrl.text = account.displayName ?? '';
      _emailCtrl.text = account.email;
      setState(() {
        _googleIdToken = idToken;
        _googlePictureUrl = account.photoUrl;
        _googleLoading = false;
      });
      CustomSnackBar1.show(
        context,
        "Google details filled in. Pick your state and tap Submit.",
      );
    } catch (e) {
      setState(() => _googleLoading = false);
      if (mounted) CustomSnackBar1.show(context, "Google sign-in error: $e");
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate text fields first
    if (!_formKey.currentState!.validate()) return;

    // 🔴 Validate State selection
    if (selectedStateId == null || stateController.text.trim().isEmpty) {
      setState(() {
        _showStateError = true;
      });
      return;
    }

    setState(() {
      _showStateError = false;
      _submitting = true;
    });

    Map<String, dynamic> data = {
      "name": _nameCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "state_id": selectedStateId,
      // Google pre-filler fields — only forwarded when the user actually
      // tapped "Continue with Google" earlier on this screen. The backend
      // verifies the idToken server-side and, on success, atomically
      // sets email_verified + googleId + authProvider + profilePicture
      // in the same write that persists name/email/state_id.
      if (_googleIdToken != null) "idToken": _googleIdToken,
      if (_googlePictureUrl != null) "profilePicture": _googlePictureUrl,
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

  @override
  Widget build(BuildContext context) {
    // THEME-DRIVEN COLORS
    final isDark = ThemeHelper.isDarkMode(context);
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);

    // Accent/brand hues for gradients & focus states
    final gradStart = isDark
        ? const Color(0xFF111827)
        : const Color(0xFF3B82F6);
    final gradEnd = isDark ? const Color(0xFF1F2937) : const Color(0xFF8B5CF6);
    final accent = isDark ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6);
    final accentSoft = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF0EA5E9);

    // Borders for inputs
    OutlineInputBorder _outline(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: 1),
    );

    final idleBorder = _outline(isDark ? Colors.white24 : Colors.black12);
    final focusedBorder = _outline(accent);

    // Onboarding Option A (2026-04-15): BlocListener<GoogleAuthCubit>
    // removed — the Google button on this screen is now a LOCAL pre-
    // filler that never hits /app/google-auth. The register submit
    // handles Google-linking via the RegisterCubit listener below
    // (it calls AuthService.setProfilePicture on RegisterLoaded so the
    // dashboard has the avatar cached immediately).
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Register User Details',
          style: AppTextStyles.titleLarge(
            textColor,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          // THEMED GRADIENT BACKDROP
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradStart, gradEnd],
              ),
            ),
          ),

          // CONTENT
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                kToolbarHeight + 40,
                20,
                20,
              ),
              child: Column(
                children: [
                  // HEADLINE
                  Text(
                    'Let’s get you set up',
                    style: AppTextStyles.headlineMedium(
                      Colors.white,
                    ).copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Provide your name and email to continue',
                    style: AppTextStyles.bodyMedium(
                      Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // GLASS CARD (outer)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                      backgroundBlendMode: BlendMode.overlay,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // INNER CARD (form)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _LabeledField(
                                  label: 'Full Name',
                                  labelStyle: AppTextStyles.labelLarge(
                                    textColor,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                  child: TextFormField(
                                    controller: _nameCtrl,
                                    focusNode: _nameFocus,
                                    style: AppTextStyles.bodyMedium(
                                      ThemeHelper.textColor(context),
                                    ),
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    validator: _validateName,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.badge_outlined,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      hintText: 'Enter your full name',
                                      hintStyle: AppTextStyles.bodyMedium(
                                        isDark
                                            ? Colors.white60
                                            : Colors.black45,
                                      ),
                                      border: idleBorder,
                                      enabledBorder: idleBorder,
                                      focusedBorder: focusedBorder,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                _LabeledField(
                                  label: 'Email Address',
                                  labelStyle: AppTextStyles.labelLarge(
                                    textColor,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                  child: TextFormField(
                                    controller: _emailCtrl,
                                    focusNode: _emailFocus,
                                    style: AppTextStyles.bodyMedium(
                                      ThemeHelper.textColor(context),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.email],
                                    validator: _validateEmail,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.alternate_email,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      hintText: 'name@example.com',
                                      hintStyle: AppTextStyles.bodyMedium(
                                        isDark
                                            ? Colors.white60
                                            : Colors.black45,
                                      ),
                                      border: idleBorder,
                                      enabledBorder: idleBorder,
                                      focusedBorder: focusedBorder,
                                    ),
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final selectedState =
                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) {
                                            return BlocProvider(
                                              create: (_) => SelectStatesCubit(
                                                SelectStatesImpl(
                                                  remoteDataSource:
                                                      RemoteDataSourceImpl(),
                                                ),
                                              ),
                                              child: SelectStateBottomSheet(),
                                            );
                                          },
                                        );

                                    if (selectedState != null) {
                                      stateController.text =
                                          selectedState.name ?? "";
                                      selectedStateId = selectedState.id;
                                      setState(() {});
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: CommonTextField1(
                                      lable: 'State',
                                      hint: 'Select State',
                                      controller: stateController,
                                      color: textColor,
                                      keyboardType: TextInputType.text,
                                      isRead: true,
                                      prefixIcon: Icon(
                                        Icons.location_city_outlined,
                                        color: textColor,
                                        size: 16,
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                          ? 'State required'
                                          : null,
                                    ),
                                  ),
                                ),
                                if (_showStateError) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: ShakeWidget(
                                      key: Key("state"),
                                      duration: const Duration(
                                        milliseconds: 700,
                                      ),
                                      child: const Text(
                                        'Please Select State',
                                        style: TextStyle(
                                          fontFamily: 'roboto_serif',
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 32),

                                BlocConsumer<RegisterCubit, RegisterStates>(
                                  listener: (context, state) async {
                                    if (state is RegisterLoaded) {
                                      // If the user completed registration
                                      // after tapping "Continue with Google",
                                      // persist the stashed Google picture
                                      // URL to the cached auth data so the
                                      // Dashboard's first render has the
                                      // right avatar — no need to wait for a
                                      // getMyProfileDetails round-trip.
                                      // Silently no-ops when _googlePictureUrl
                                      // is null (manual registration path).
                                      await AuthService.setProfilePicture(
                                        _googlePictureUrl,
                                      );
                                      if (!context.mounted) return;
                                      if (widget.from == "ad") {
                                        context.pop();
                                      } else {
                                        context.pushReplacement("/dashboard");
                                      }
                                      AuthService.setUserStatus("false");
                                    } else if (state is RegisterFailure) {
                                      CustomSnackBar1.show(
                                        context,
                                        state.error,
                                      );
                                    }
                                    if (state is RegisterLoaded ||
                                        state is RegisterFailure) {
                                      setState(() => _submitting = false);
                                    }
                                  },
                                  builder: (context, state) {
                                    final isLoading =
                                        state is RegisterLoading || _submitting;

                                    return CustomAppButton1(
                                      text: "Submit",
                                      isLoading: isLoading,
                                      color: AppColors.primary,
                                      onPlusTap: isLoading ? null : _submit,
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),

                                // OR divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.white38, thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        "OR",
                                        style: AppTextStyles.bodyMedium(Colors.white70),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.white38, thickness: 1)),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Continue with Google button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _googleLoading ? null : _signInWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(color: Colors.white24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _googleLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/google_logo.png',
                                                height: 22,
                                                width: 22,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                "Continue with Google",
                                                style: AppTextStyles.bodyMedium(Colors.black87)
                                                    .copyWith(fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class _RegisterUserDetailsScreenState extends State<RegisterUserDetailsScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameCtrl = TextEditingController(text: '');
//   final _emailCtrl = TextEditingController(text: '');
//   final _nameFocus = FocusNode();
//   final _emailFocus = FocusNode();
//   final TextEditingController _otpController = TextEditingController();
//
//   bool _submitting = false;
//   bool _isOtpVerified = false;
//
//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _emailCtrl.dispose();
//     _nameFocus.dispose();
//     _emailFocus.dispose();
//     super.dispose();
//   }
//
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     Map<String, dynamic> data = {
//       "name": _nameCtrl.text,
//       "email": _emailCtrl.text,
//     };
//     context.read<RegisterCubit>().register(data);
//   }
//
//   String? _validateName(String? v) {
//     final t = (v ?? '').trim();
//     if (t.isEmpty) return 'Please enter your name';
//     if (t.length < 3) return 'Name must be at least 3 characters';
//     return null;
//   }
//
//   String? _validateEmail(String? v) {
//     final t = (v ?? '').trim();
//     if (t.isEmpty) return 'Please enter your email';
//     final emailRegex = RegExp(r'^[\w\.\-+%]+@[\w\.\-]+\.[A-Za-z]{2,}$');
//     if (!emailRegex.hasMatch(t)) return 'Enter a valid email address';
//     return null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // THEME-DRIVEN COLORS
//     final isDark = ThemeHelper.isDarkMode(context);
//     final bgColor = ThemeHelper.backgroundColor(context);
//     final textColor = ThemeHelper.textColor(context);
//     final cardColor = ThemeHelper.cardColor(context);
//
//     // Accent/brand hues for gradients & focus states
//     final gradStart = isDark
//         ? const Color(0xFF111827)
//         : const Color(0xFF3B82F6); // slate-900 vs blue-500
//     final gradEnd = isDark
//         ? const Color(0xFF1F2937)
//         : const Color(0xFF8B5CF6); // slate-800 vs violet-500
//     final accent = isDark ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6);
//
//     final accentSoft = isDark
//         ? const Color(0xFF60A5FA)
//         : const Color(0xFF0EA5E9);
//     final pinIdleBorder = isDark ? Colors.white24 : const Color(0xFFE5E7EB);
//     final pinActiveBorder = accent;
//     final pinSelectedBorder = accentSoft;
//
//     // Borders for inputs
//     OutlineInputBorder _outline(Color c) => OutlineInputBorder(
//       borderRadius: BorderRadius.circular(14),
//       borderSide: BorderSide(color: c, width: 1),
//     );
//
//     final idleBorder = _outline(isDark ? Colors.white24 : Colors.black12);
//     final focusedBorder = _outline(accent);
//
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         centerTitle: true,
//         title: Text(
//           'Register User Details',
//           style: AppTextStyles.titleLarge(
//             textColor,
//           ).copyWith(fontWeight: FontWeight.w700),
//         ),
//         iconTheme: IconThemeData(color: textColor),
//       ),
//       body: Stack(
//         children: [
//           // THEMED GRADIENT BACKDROP
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [gradStart, gradEnd],
//               ),
//             ),
//           ),
//
//           // CONTENT
//           Align(
//             alignment: Alignment.topCenter,
//             child: SingleChildScrollView(
//               physics: NeverScrollableScrollPhysics(),
//               padding: const EdgeInsets.fromLTRB(
//                 20,
//                 kToolbarHeight + 40,
//                 20,
//                 20,
//               ),
//               child: Column(
//                 children: [
//                   // HEADLINE
//                   Text(
//                     'Let’s get you set up',
//                     style: AppTextStyles.headlineMedium(
//                       Colors.white,
//                     ).copyWith(fontWeight: FontWeight.w800),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Provide your name and email to continue',
//                     style: AppTextStyles.bodyMedium(
//                       Colors.white.withOpacity(0.9),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 28),
//
//                   // GLASS CARD (outer)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(18),
//                     decoration: BoxDecoration(
//                       color: isDark
//                           ? Colors.white.withOpacity(0.06)
//                           : Colors.white.withOpacity(0.12),
//                       borderRadius: BorderRadius.circular(24),
//                       border: Border.all(color: Colors.white.withOpacity(0.18)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.18),
//                           blurRadius: 30,
//                           offset: const Offset(0, 18),
//                         ),
//                       ],
//                       backgroundBlendMode: BlendMode.overlay,
//                     ),
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 16),
//                         // INNER CARD (form)
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(18),
//                           decoration: BoxDecoration(
//                             color: cardColor,
//                             borderRadius: BorderRadius.circular(18),
//                           ),
//                           child: Form(
//                             key: _formKey,
//                             child: Column(
//                               children: [
//                                 _LabeledField(
//                                   label: 'Full Name',
//                                   labelStyle: AppTextStyles.labelLarge(
//                                     textColor,
//                                   ).copyWith(fontWeight: FontWeight.w700),
//                                   child: TextFormField(
//                                     controller: _nameCtrl,
//                                     focusNode: _nameFocus,
//                                     style: AppTextStyles.bodyMedium(
//                                       ThemeHelper.textColor(context),
//                                     ),
//                                     textInputAction: TextInputAction.next,
//                                     autofillHints: const [AutofillHints.name],
//                                     validator: _validateName,
//                                     decoration: InputDecoration(
//                                       prefixIcon: Icon(
//                                         Icons.badge_outlined,
//                                         color: isDark
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       hintText: 'Enter your full name',
//                                       hintStyle: AppTextStyles.bodyMedium(
//                                         isDark
//                                             ? Colors.white60
//                                             : Colors.black45,
//                                       ),
//                                       border: idleBorder,
//                                       enabledBorder: idleBorder,
//                                       focusedBorder: focusedBorder,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 14),
//                                 _LabeledField(
//                                   label: 'Email Address',
//                                   labelStyle: AppTextStyles.labelLarge(
//                                     textColor,
//                                   ).copyWith(fontWeight: FontWeight.w700),
//                                   child: TextFormField(
//                                     controller: _emailCtrl,
//                                     focusNode: _emailFocus,
//                                     style: AppTextStyles.bodyMedium(
//                                       ThemeHelper.textColor(context),
//                                     ),
//                                     keyboardType: TextInputType.emailAddress,
//                                     textInputAction: TextInputAction.done,
//                                     autofillHints: const [AutofillHints.email],
//                                     validator: _validateEmail,
//                                     decoration: InputDecoration(
//                                       prefixIcon: Icon(
//                                         Icons.alternate_email,
//                                         color: isDark
//                                             ? Colors.white70
//                                             : Colors.black54,
//                                       ),
//                                       hintText: 'name@example.com',
//                                       hintStyle: AppTextStyles.bodyMedium(
//                                         isDark
//                                             ? Colors.white60
//                                             : Colors.black45,
//                                       ),
//                                       border: idleBorder,
//                                       enabledBorder: idleBorder,
//                                       focusedBorder: focusedBorder,
//                                     ),
//                                     onFieldSubmitted: (_) => _submit(),
//                                   ),
//                                 ),
//                                 BlocConsumer<
//                                   EmailVerificationCubit,
//                                   EmailVerificationStates
//                                 >(
//                                   listener: (context, state) {
//                                     if (!mounted) return;
//                                     if (state is SendOTPSuccess) {
//                                       _otpController.clear();
//                                       CustomSnackBar1.show(
//                                         context,
//                                         "OTP sent to ${_emailCtrl.text}",
//                                       );
//                                     } else if (state is SendOTPFailure) {
//                                       CustomSnackBar1.show(
//                                         context,
//                                         "${state.error}",
//                                       );
//                                     } else if (state is VerifyOTPSuccess) {
//                                       _isOtpVerified = true;
//                                       setState(() {});
//                                       CustomSnackBar1.show(
//                                         context,
//                                         "OTP Verified Successfully!",
//                                       );
//                                     } else if (state is VerifyOTPFailure) {
//                                       _isOtpVerified = false;
//                                       setState(() {});
//                                       CustomSnackBar1.show(
//                                         context,
//                                         "${state.error}",
//                                       );
//                                     }
//                                   },
//                                   builder: (context, state) {
//                                     final isSending = state is SendOTPLoading;
//                                     final isVerifying =
//                                         state is VerifyOTPLoading;
//
//                                     // Determine if OTP has been sent
//                                     final otpSent =
//                                         state is SendOTPSuccess ||
//                                         state is VerifyOTPLoading ||
//                                         state is VerifyOTPFailure;
//
//                                     return Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.end,
//                                       children: [
//                                         // Send OTP button (hide after OTP is sent)
//                                         // if (!otpSent)
//                                         if (!_isOtpVerified) ...[
//                                           Align(
//                                             alignment: Alignment.topRight,
//                                             child: TextButton(
//                                               onPressed: isSending
//                                                   ? null
//                                                   : () {
//                                                       _otpController.clear();
//                                                       _isOtpVerified =
//                                                           false; // reset verification
//                                                       setState(() {});
//                                                       context
//                                                           .read<
//                                                             EmailVerificationCubit
//                                                           >()
//                                                           .sendOTP({
//                                                             "email":
//                                                                 _emailCtrl.text,
//                                                           });
//                                                     },
//                                               child: isSending
//                                                   ? const SizedBox(
//                                                       width: 16,
//                                                       height: 16,
//                                                       child:
//                                                           CircularProgressIndicator(
//                                                             strokeWidth: 2,
//                                                           ),
//                                                     )
//                                                   : Text(
//                                                       "Send OTP",
//                                                       style:
//                                                           AppTextStyles.titleSmall(
//                                                             textColor,
//                                                           ),
//                                                     ),
//                                             ),
//                                           ),
//                                         ],
//                                         // OTP input field (show only after OTP is sent)
//                                         if (otpSent) ...[
//                                           SizedBox(height: 16),
//                                           PinCodeTextField(
//                                             autoUnfocus: true,
//                                             autoDisposeControllers: false,
//                                             appContext: context,
//                                             controller: _otpController,
//                                             backgroundColor: Colors.transparent,
//                                             length: 6,
//                                             animationType: AnimationType.fade,
//                                             hapticFeedbackTypes:
//                                                 HapticFeedbackTypes.heavy,
//                                             cursorColor: isDark
//                                                 ? Colors.white70
//                                                 : Colors.grey[700],
//                                             keyboardType: TextInputType.number,
//                                             enableActiveFill: true,
//                                             useExternalAutoFillGroup: true,
//                                             beforeTextPaste: (text) => true,
//                                             autoFocus: true,
//                                             autoDismissKeyboard: false,
//                                             showCursor: true,
//                                             pastedTextStyle: TextStyle(
//                                               color: textColor,
//                                               fontWeight: FontWeight.w700,
//                                               fontFamily: 'Roboto',
//                                             ),
//                                             pinTheme: PinTheme(
//                                               shape: PinCodeFieldShape.box,
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                               fieldHeight: 40,
//                                               fieldWidth: 40,
//                                               fieldOuterPadding:
//                                                   const EdgeInsets.only(
//                                                     right: 2,
//                                                   ),
//                                               activeFillColor: isDark
//                                                   ? const Color(0xFF131A22)
//                                                   : Colors.white,
//                                               selectedFillColor: isDark
//                                                   ? const Color(0xFF131A22)
//                                                   : Colors.white,
//                                               inactiveFillColor: isDark
//                                                   ? const Color(0xFF0D141B)
//                                                   : Colors.white,
//                                               activeColor: pinActiveBorder,
//                                               selectedColor: pinSelectedBorder,
//                                               inactiveColor: pinIdleBorder,
//                                               activeBorderWidth: 1.6,
//                                               selectedBorderWidth: 1.6,
//                                               inactiveBorderWidth: 1.1,
//                                             ),
//                                             textStyle: TextStyle(
//                                               color: textColor,
//                                               fontSize: 17,
//                                               fontFamily: 'Inter',
//                                               fontWeight: FontWeight.w400,
//                                             ),
//                                             inputFormatters: [
//                                               FilteringTextInputFormatter
//                                                   .digitsOnly,
//                                             ],
//                                             textInputAction: Platform.isAndroid
//                                                 ? TextInputAction.none
//                                                 : TextInputAction.done,
//                                             onCompleted: (value) {
//                                               final otp = int.tryParse(
//                                                 _otpController.text,
//                                               );
//                                               if (otp != null &&
//                                                   _otpController.text.length ==
//                                                       6) {
//                                                 context
//                                                     .read<
//                                                       EmailVerificationCubit
//                                                     >()
//                                                     .verifyOTP({
//                                                       "email": _emailCtrl.text
//                                                           .trim(),
//                                                       "otp": otp,
//                                                     });
//                                               }
//                                             },
//                                             onSubmitted: (value) {
//                                               final otp = int.tryParse(
//                                                 _otpController.text,
//                                               );
//                                               if (otp != null &&
//                                                   _otpController.text.length ==
//                                                       6) {
//                                                 context
//                                                     .read<
//                                                       EmailVerificationCubit
//                                                     >()
//                                                     .verifyOTP({
//                                                       "email": _emailCtrl.text
//                                                           .trim(),
//                                                       "otp": otp,
//                                                     });
//                                               }
//                                             },
//                                           ),
//                                         ],
//                                         // Verify OTP button (show only after OTP is sent)
//                                         if (otpSent)
//                                           Align(
//                                             alignment: Alignment.topRight,
//                                             child: TextButton(
//                                               onPressed: isVerifying
//                                                   ? null
//                                                   : () {
//                                                       context
//                                                           .read<
//                                                             EmailVerificationCubit
//                                                           >()
//                                                           .verifyOTP({
//                                                             "email":
//                                                                 _emailCtrl.text,
//                                                             "otp": int.parse(
//                                                               _otpController
//                                                                   .text,
//                                                             ),
//                                                           });
//                                                     },
//                                               child: isVerifying
//                                                   ? const SizedBox(
//                                                       width: 16,
//                                                       height: 16,
//                                                       child:
//                                                           CircularProgressIndicator(
//                                                             strokeWidth: 2,
//                                                           ),
//                                                     )
//                                                   : Text(
//                                                       "Verify OTP",
//                                                       style:
//                                                           AppTextStyles.titleSmall(
//                                                             textColor,
//                                                           ),
//                                                     ),
//                                             ),
//                                           ),
//                                       ],
//                                     );
//                                   },
//                                 ),
//                                 const SizedBox(height: 24),
//                                 BlocConsumer<RegisterCubit, RegisterStates>(
//                                   listener: (context, state) {
//                                     if (state is RegisterLoaded) {
//                                       if (widget.from == "ad") {
//                                         context.pop();
//                                       } else {
//                                         context.pushReplacement("/dashboard");
//                                       }
//                                       AuthService.setUserStatus("false");
//                                     } else if (state is RegisterFailure) {
//                                       CustomSnackBar1.show(
//                                         context,
//                                         state.error,
//                                       );
//                                     }
//                                   },
//                                   builder: (context, state) {
//                                     final isLoading = state is RegisterLoading;
//                                     return CustomAppButton1(
//                                       text: "Submit",
//                                       isLoading: isLoading,
//                                       color: _isOtpVerified
//                                           ? AppColors.primary
//                                           : Colors.grey,
//                                       onPlusTap: _isOtpVerified
//                                           ? () {
//                                               _submit();
//                                             }
//                                           : () {
//                                               CustomSnackBar1.show(
//                                                 context,
//                                                 "OTP Not yet Verified!",
//                                               );
//                                             },
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.labelStyle,
  });

  final String label;
  final Widget child;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
