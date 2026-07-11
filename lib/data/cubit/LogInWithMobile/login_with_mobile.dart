import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/model/VerifyOtpModel.dart';
import 'login_with_mobile_repository.dart';
import 'login_with_mobile_state.dart';

class LogInwithMobileCubit extends Cubit<LogInWithMobileState> {
  final LogInWithMobileRepository logInWithMobileRepository;
  LogInwithMobileCubit(this.logInWithMobileRepository)
    : super(LogInWithMobileInitial());

  Future<void> postLogInWithMobile(Map<String, dynamic> data) async {
    emit(LogInwithMobileLoading());
    try {
      final response = await logInWithMobileRepository.SendMobileOtp(data);
      if (response != null && response.success == true) {
        emit(LogInwithMobileSuccess(response));
      } else {
        emit(LogInwithMobileFailure(
          "${response?.message ?? ''}",
          retryAfterSec: response?.retryAfterSec,
        ));
      }
    } catch (e) {
      emit(LogInwithMobileFailure(e.toString()));
    }
  }

  Future<void> verifyLoginOtp(Map<String, dynamic> data) async {
    emit(verifyWithMobileLoading());
    try {
      final response = await logInWithMobileRepository.verifyMobileOtp(data);
      // The repo now parses 4xx error bodies into a VerifyOtpModel with
      // success=false + code + message populated. Emit verifyMobileSuccess
      // unconditionally so the OTPScreen listener can read data.success
      // and branch between login-OK / ACCOUNT_DELETED / error flows.
      // Only a true exception (network, parse) falls through to
      // OtpVerifyFailure in the catch below.
      emit(verifyMobileSuccess(
        response ?? VerifyOtpModel(success: false, message: 'Something went wrong'),
      ));
    } catch (e) {
      emit(OtpVerifyFailure(e.toString()));
    }
  }

  Future<void> postLogInWithEmail(Map<String, dynamic> data) async {
    emit(LogInwithMobileLoading());
    try {
      final response = await logInWithMobileRepository.SendEmailOtp(data);
      if (response != null && response.success == true) {
        emit(LogInwithEmailSuccess(response));
      } else {
        emit(LogInwithMobileFailure(
          "${response?.message ?? ''}",
          retryAfterSec: response?.retryAfterSec,
        ));
      }
    } catch (e) {
      emit(LogInwithMobileFailure(e.toString()));
    }
  }

  Future<void> verifyEmailLoginOtp(Map<String, dynamic> data) async {
    emit(verifyWithMobileLoading());
    try {
      final response = await logInWithMobileRepository.verifyEmailOtp(data);
      // The repo now parses 4xx error bodies into a VerifyOtpModel with
      // success=false + code + message populated. Emit verifyEmailSuccess
      // unconditionally so the OTPScreen listener can read data.success
      // and branch between login-OK / ACCOUNT_DELETED / error flows.
      emit(verifyEmailSuccess(
        response ?? VerifyOtpModel(success: false, message: 'Something went wrong'),
      ));
    } catch (e) {
      emit(OtpVerifyFailure(e.toString()));
    }
  }

}
