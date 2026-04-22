/// Response shape for POST /app/send-otp and POST /app/send-otp-email.
/// The backend returns only `success` and `message` — the UI uses both
/// (success branches navigation, message displays on failure). Older
/// versions of this model had `otp` and `newUser` fields that the
/// backend never sends and the UI never reads — removed during cleanup.
class SendOtpModel {
  bool? success;
  String? message;
  String? code;
  // Populated from backend's { retry_after_sec } on a 429 RATE_LIMITED
  // response. Screens read this to drive a precise countdown timer + keep
  // the resend button disabled until the window closes — without it the
  // user would keep tapping and piling on more rate-limit hits.
  int? retryAfterSec;

  SendOtpModel({this.success, this.message, this.code, this.retryAfterSec});

  SendOtpModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    code = json['code']?.toString();
    retryAfterSec = (json['retry_after_sec'] is num)
        ? (json['retry_after_sec'] as num).toInt()
        : int.tryParse(json['retry_after_sec']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['code'] = code;
    data['retry_after_sec'] = retryAfterSec;
    return data;
  }
}
