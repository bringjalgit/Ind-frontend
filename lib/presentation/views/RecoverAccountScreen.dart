import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomSnackBar.dart';
import '../../data/cubit/RecoverAccount/recover_account_cubit.dart';
import '../../data/cubit/RecoverAccount/recover_account_states.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

class RecoverAccountScreen extends StatefulWidget {
  // P0-profile-1: carries the signed recovery token minted by the
  // preceding OTP-verify (or google-auth) call. If this is empty, the
  // screen was reached via a deep link or stale navigation and the
  // user must re-login to get a fresh token.
  final String recoveryToken;
  const RecoverAccountScreen({super.key, required this.recoveryToken});

  @override
  State<RecoverAccountScreen> createState() => _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends State<RecoverAccountScreen> {
  void _onRecoverPressed(BuildContext context) {
    if (widget.recoveryToken.isNotEmpty) {
      context.read<RecoverAccountCubit>().recoverAccount(widget.recoveryToken);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Recovery session expired — please log in again"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Cute Illustration
                Icon(
                  Icons.restore,
                  size: 90,
                  color: textColor.withOpacity(0.8),
                ),
                const SizedBox(height: 16),

                Text(
                  "Recover Your Account",
                  style: AppTextStyles.headlineLarge(
                    textColor,
                  ).copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Your account was deleted earlier. Don’t worry — you can easily recover by just tapping on Recover Account Button.",
                  style: AppTextStyles.bodyMedium(
                    textColor,
                  ).copyWith(height: 1.5, color: textColor.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card for input
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      BlocConsumer<RecoverAccountCubit, RecoverAccountStates>(
                        listener: (context, state) {
                          if (state is RecoverAccountLoaded) {
                            CustomSnackBar1.show(
                              context,
                              state.adSuccessModel.message ?? "Recovered!",
                            );
                            context.push("/login");
                          } else if (state is RecoverAccountFailure) {
                            CustomSnackBar1.show(
                              context,
                              state.error ?? "Failed",
                            );
                          }
                        },
                        builder: (context, state) {
                          final isLoading = state is RecoverAccountLoading;
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _onRecoverPressed(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "Recover Account",
                                      style: AppTextStyles.titleMedium(
                                        Colors.white,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // TextButton(
                //   onPressed: () {
                //     Navigator.pop(context);
                //   },
                //   child: Text(
                //     "Back to Login",
                //     style: AppTextStyles.bodyMedium(
                //       textColor,
                //     ).copyWith(decoration: TextDecoration.underline),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
