import 'package:classifieds/model/VerifyOtpModel.dart';

abstract class GoogleAuthStates {}

class GoogleAuthInitial extends GoogleAuthStates {}

class GoogleAuthLoading extends GoogleAuthStates {}

class GoogleAuthSuccess extends GoogleAuthStates {
  final VerifyOtpModel data;
  GoogleAuthSuccess(this.data);
}

class GoogleAuthFailure extends GoogleAuthStates {
  final String error;
  // Optional fields preserved from the backend response so the UI can branch
  // on specific failure codes (ACCOUNT_DELETED → recovery, ACCOUNT_BLOCKED →
  // blocked screen). When absent, the listener falls through to a snackbar.
  final String? code;
  final String? userId;
  // P0-profile-1: short-lived signed token returned with ACCOUNT_DELETED so
  // the recovery screen can call /recovery-my-account without leaking userId.
  final String? recoveryToken;
  GoogleAuthFailure(this.error, {this.code, this.userId, this.recoveryToken});
}
