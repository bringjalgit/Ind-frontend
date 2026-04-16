import 'package:classifieds/model/AadhaarStatusModel.dart';

/// State machine for the Aadhaar verification screen.
///
/// Flow:
///   Initial → (loadStatus) → Loaded(status)
///   Loaded(none|rejected) → (pickAndUpload side) → Loaded(holding local URLs)
///   Loaded(both URLs held) → (submit) → Submitting → Loaded(pending)
///
/// The cubit keeps AadhaarStatusData as the source of truth and
/// overlays transient fields (frontUrl/backUrl held after S3 PUT but
/// before U2 commit) on the same `current` model. No separate "holding"
/// state class — just a Loaded with local URLs set.
abstract class AadhaarState {
  const AadhaarState();
}

class AadhaarInitial extends AadhaarState {
  const AadhaarInitial();
}

class AadhaarLoading extends AadhaarState {
  const AadhaarLoading();
}

class AadhaarLoaded extends AadhaarState {
  final AadhaarStatusData data;
  /// Local URL held after a successful S3 PUT for the front side,
  /// before U2 commit. Null when not yet uploaded in this session.
  final String? pendingFrontUrl;
  final String? pendingBackUrl;

  const AadhaarLoaded(
    this.data, {
    this.pendingFrontUrl,
    this.pendingBackUrl,
  });

  AadhaarLoaded copyWith({
    AadhaarStatusData? data,
    String? pendingFrontUrl,
    String? pendingBackUrl,
  }) =>
      AadhaarLoaded(
        data ?? this.data,
        pendingFrontUrl: pendingFrontUrl ?? this.pendingFrontUrl,
        pendingBackUrl: pendingBackUrl ?? this.pendingBackUrl,
      );

  bool get hasFront => pendingFrontUrl != null;
  bool get hasBack => pendingBackUrl != null;
  bool get canSubmit => hasFront && hasBack;
}

class AadhaarUploading extends AadhaarState {
  final AadhaarStatusData data;
  final String side; // 'front' | 'back'
  final String? pendingFrontUrl;
  final String? pendingBackUrl;

  const AadhaarUploading(
    this.data,
    this.side, {
    this.pendingFrontUrl,
    this.pendingBackUrl,
  });
}

class AadhaarSubmitting extends AadhaarState {
  final AadhaarStatusData data;
  const AadhaarSubmitting(this.data);
}

class AadhaarFailure extends AadhaarState {
  final String message;
  final String? code;
  /// Last-known data so UI can still render the underlying screen
  /// while showing the error as a SnackBar / inline banner.
  final AadhaarStatusData? data;
  final String? pendingFrontUrl;
  final String? pendingBackUrl;

  const AadhaarFailure(
    this.message, {
    this.code,
    this.data,
    this.pendingFrontUrl,
    this.pendingBackUrl,
  });
}
