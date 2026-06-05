import 'package:flutter_bloc/flutter_bloc.dart';

import 'EmailVerificationRepo.dart';
import 'EmailVerificationStates.dart';

class EmailVerificationCubit extends Cubit<EmailVerificationStates> {
  final EmailVerificationRepo emailVerificationRepo;

  EmailVerificationCubit(this.emailVerificationRepo)
      : super(EmailVerificationInitially());

  // Send OTP
  Future<void> sendOTP(Map<String, dynamic> data) async {
    try {
      emit(SendOTPLoading());
      final response = await emailVerificationRepo.sendOTP(data);
      if (response != null && response.success == true) {
        emit(SendOTPSuccess(response));
      } else {
        emit(SendOTPFailure(response?.message ?? "Failed to send OTP"));
      }
    } catch (e) {
      emit(SendOTPFailure(e.toString()));
    }
  }

  // Verify OTP
  Future<void> verifyOTP(Map<String, dynamic> data) async {
    try {
      emit(VerifyOTPLoading());
      final response = await emailVerificationRepo.verifyOTP(data);
      if (response != null && response.success == true) {
        emit(VerifyOTPSuccess(response));
      } else {
        emit(VerifyOTPFailure(response?.message ?? "Failed to verify OTP"));
      }
    } catch (e) {
      emit(VerifyOTPFailure(e.toString()));
    }
  }
}

