import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomSnackBar.dart';
import 'package:classifieds/data/cubit/LogInWithMobile/login_with_mobile.dart';
import 'package:classifieds/data/cubit/LogInWithMobile/login_with_mobile_state.dart';
import 'package:classifieds/widgets/CommonTextField.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final bgColor = ThemeHelper.backgroundColor(context);
    final cardColor = ThemeHelper.cardColor(context);

    // Brand-ish accents
    final gradStart = isDark
        ? const Color(0xFF111827)
        : const Color(0xFF1677FF);
    final gradEnd = isDark ? const Color(0xFF1F2937) : const Color(0xFF18345B);
    final accent = isDark ? const Color(0xFF8B5CF6) : const Color(0xFF1677FF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradStart, gradEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Content
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                kToolbarHeight + 48,
                24,
                48,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Headline with gradient shader
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [accent, Colors.white.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "Sign In",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMedium(
                          Colors.white,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Login to continue your journey",
                      style: AppTextStyles.titleMedium(
                        Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Glass outer card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.06 : 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Inner solid card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Phone field
                                CommonTextField1(
                                  lable: "Mobile Number",
                                  hint: "Enter 10-digit number",
                                  controller: _phoneController,
                                  color: textColor,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Phone required'
                                      : (!RegExp(
                                              r'^[0-9]{10}$',
                                            ).hasMatch(v.trim())
                                            ? 'Enter a valid 10-digit phone number'
                                            : null),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.06)
                                                : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white24
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Text(
                                            "+91",
                                            style:
                                                AppTextStyles.bodyMedium(
                                                  textColor,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                                // Helper/info
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "We’ll send a 6-digit OTP to this number.",
                                        style: AppTextStyles.bodySmall(
                                          isDark
                                              ? Colors.white70
                                              : Colors.grey[700]!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // Send OTP button with Bloc
                                BlocConsumer<
                                  LogInwithMobileCubit,
                                  LogInWithMobileState
                                >(
                                  listener: (context, state) async {
                                    if (state is LogInwithMobileSuccess) {
                                      context.pushReplacement(
                                        '/otp?mobile=${_phoneController.text}',
                                      );
                                    } else if (state
                                        is LogInwithMobileFailure) {
                                      // Prefer showing backend message if available
                                      CustomSnackBar.show(
                                        context,
                                        state.error ??
                                            "Failed to send OTP. Try again.",
                                      );
                                    }
                                  },
                                  builder: (context, state) {
                                    final bool loading =
                                        state is LogInwithMobileLoading;
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [accent, gradEnd],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: loading
                                              ? null
                                              : () async {
                                                  final phone = _phoneController
                                                      .text
                                                      .trim();
                                                  if (phone.isEmpty) {
                                                    CustomSnackBar.show(
                                                      context,
                                                      "Phone number is required",
                                                    );
                                                  } else if (!RegExp(
                                                    r'^[0-9]{10}$',
                                                  ).hasMatch(phone)) {
                                                    CustomSnackBar.show(
                                                      context,
                                                      "Enter a valid 10-digit phone number",
                                                    );
                                                  } else {
                                                    context
                                                        .read<
                                                          LogInwithMobileCubit
                                                        >()
                                                        .postLogInWithMobile({
                                                          "mobile": phone,
                                                        });
                                                  }
                                                },
                                          icon: loading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Icon(Icons.sms_outlined),
                                          label: Text(
                                            loading
                                                ? "Sending OTP..."
                                                : "Send OTP",
                                            style:
                                                AppTextStyles.titleMedium(
                                                  Colors.white,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: Text(
                                    "OR",
                                    style: AppTextStyles.bodyLarge(textColor),
                                  ),
                                ),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      context.pushReplacement("/email_login");
                                    },
                                    child: Text(
                                      "Login With Email",
                                      style: AppTextStyles.titleSmall(textColor)
                                          .copyWith(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: textColor,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Terms
                    Text.rich(
                      TextSpan(
                        text: "By continuing, you agree to our ",
                        style: AppTextStyles.bodySmall(
                          Colors.white.withOpacity(0.9),
                        ),
                        children: [
                          TextSpan(
                            text: "Terms & Conditions",
                            style: AppTextStyles.bodySmall(Colors.white)
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
