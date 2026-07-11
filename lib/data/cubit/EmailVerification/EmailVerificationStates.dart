import '../../../model/AdSuccessModel.dart';
abstract class EmailVerificationStates {}

class EmailVerificationInitially extends EmailVerificationStates {}

// Sending OTP States
class SendOTPLoading extends EmailVerificationStates {}
class SendOTPSuccess extends EmailVerificationStates {
  final AdSuccessModel successModel;
  SendOTPSuccess(this.successModel);
}
class SendOTPFailure extends EmailVerificationStates {
  final String error;
  SendOTPFailure(this.error);
}

// Verifying OTP States
class VerifyOTPLoading extends EmailVerificationStates {}
class VerifyOTPSuccess extends EmailVerificationStates {
  final AdSuccessModel successModel;
  VerifyOTPSuccess(this.successModel);
}
class VerifyOTPFailure extends EmailVerificationStates {
  final String error;
  VerifyOTPFailure(this.error);
}
