/// Response shape for GET /app/get-aadhaar-status (U3).
///
/// Backend shape:
///   { success, message, data: {
///       status: 'none'|'pending'|'approved'|'rejected',
///       submitted_at, reviewed_at, rejection_reason,
///       front_url, back_url, is_verified
///   } }
///
/// URL-hiding rule (enforced server-side — client trusts it):
///   - none    → front_url/back_url null
///   - pending → URLs returned (user can see what they submitted)
///   - rejected→ URLs returned (user sees what to fix)
///   - approved→ URLs hidden (null) — proof lives in S3 for audit only
class AadhaarStatusModel {
  bool? success;
  String? message;
  AadhaarStatusData? data;

  AadhaarStatusModel({this.success, this.message, this.data});

  AadhaarStatusModel.fromJson(Map<String, dynamic> json) {
    success = json['success'] == true;
    message = json['message']?.toString();
    data = json['data'] != null
        ? AadhaarStatusData.fromJson(json['data'])
        : null;
  }
}

class AadhaarStatusData {
  String status;
  String? submittedAt;
  String? reviewedAt;
  String? rejectionReason;
  String? frontUrl;
  String? backUrl;
  bool isVerified;

  AadhaarStatusData({
    this.status = 'none',
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.frontUrl,
    this.backUrl,
    this.isVerified = false,
  });

  AadhaarStatusData.fromJson(Map<String, dynamic> json)
      : status = (json['status']?.toString() ?? 'none'),
        submittedAt = json['submitted_at']?.toString(),
        reviewedAt = json['reviewed_at']?.toString(),
        rejectionReason = json['rejection_reason']?.toString(),
        frontUrl = json['front_url']?.toString(),
        backUrl = json['back_url']?.toString(),
        isVerified = json['is_verified'] == true;

  bool get isNone => status == 'none';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get canSubmit => isNone || isRejected;
}
