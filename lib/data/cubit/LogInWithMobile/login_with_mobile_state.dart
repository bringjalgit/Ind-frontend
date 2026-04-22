import 'package:classifieds/model/SendOtpModel.dart';
import 'package:classifieds/model/VerifyOtpModel.dart';

abstract class LogInWithMobileState {}

class LogInWithMobileInitial extends LogInWithMobileState {}

class LogInwithMobileLoading extends LogInWithMobileState {}

class verifyWithMobileLoading extends LogInWithMobileState {}

class LogInwithMobileSuccess extends LogInWithMobileState {
  final SendOtpModel sendOtpModel;
  LogInwithMobileSuccess(this.sendOtpModel);
}

class LogInwithEmailSuccess extends LogInWithMobileState {
  final SendOtpModel sendOtpModel;
  LogInwithEmailSuccess(this.sendOtpModel);
}

class verifyMobileSuccess extends LogInWithMobileState {
  final VerifyOtpModel verifyOtpModel;
  verifyMobileSuccess(this.verifyOtpModel);
}

class verifyEmailSuccess extends LogInWithMobileState {
  final VerifyOtpModel verifyOtpModel;
  verifyEmailSuccess(this.verifyOtpModel);
}

class LogInwithMobileFailure extends LogInWithMobileState {
  final String error;
  // When the failure is a 429 RATE_LIMITED, the screen uses this to drive
  // a precise countdown + keep the button disabled until the window closes.
  // null for non-rate-limit failures (invalid mobile, network, etc.).
  final int? retryAfterSec;
  LogInwithMobileFailure(this.error, {this.retryAfterSec});
}

class OtpVerifyFailure extends LogInWithMobileState {
  final String error;
  final int? retryAfterSec;
  OtpVerifyFailure(this.error, {this.retryAfterSec});
}
