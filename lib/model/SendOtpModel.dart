/// Response shape for POST /app/send-otp and POST /app/send-otp-email.
/// The backend returns only `success` and `message` — the UI uses both
/// (success branches navigation, message displays on failure). Older
/// versions of this model had `otp` and `newUser` fields that the
/// backend never sends and the UI never reads — removed during cleanup.
class SendOtpModel {
  bool? success;
  String? message;

  SendOtpModel({this.success, this.message});

  SendOtpModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    return data;
  }
}
