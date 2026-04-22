import 'dart:convert';

class VerifyOtpModel {
  bool? success;
  String? message;
  String? code;
  String? id;
  // P0-profile-1: when the backend returns 400 ACCOUNT_DELETED on an
  // OTP-verify (mobile or email) or a google-auth call, it now also
  // returns a short-lived signed recovery_token. The recovery endpoint
  // requires this token instead of the raw user id, so the Flutter
  // flow has to carry it through from the failure response to the
  // recovery screen.
  String? recoveryToken;
  String? accessToken;
  String? refreshToken;
  int? refreshTokenExpiry;
  int? accessTokenExpiry;
  bool? newUser;
  User? user;
  // Populated from backend's { retry_after_sec } on a 429 RATE_LIMITED.
  // OTPScreen reads this to disable the Verify button + drive a countdown
  // until the window closes.
  int? retryAfterSec;

  VerifyOtpModel({
    this.success,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.refreshTokenExpiry,
    this.accessTokenExpiry,
    this.newUser,
    this.user,
    this.id,
    this.recoveryToken,
    this.retryAfterSec,
  });

  /// Factory method to handle both String and Map inputs
  factory VerifyOtpModel.fromResponse(dynamic data) {
    if (data is String) {
      return VerifyOtpModel.fromJson(jsonDecode(data));
    } else if (data is Map<String, dynamic>) {
      return VerifyOtpModel.fromJson(data);
    } else {
      throw Exception("❌ Invalid response type: ${data.runtimeType}");
    }
  }

  VerifyOtpModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    code = json['code'];
    id = json['id']?.toString();
    recoveryToken = json['recovery_token'];
    accessToken = json['accessToken'];
    refreshToken = json['refreshToken'];
    accessTokenExpiry = json['accessTokenExpiry'];
    refreshTokenExpiry = json['refreshTokenExpiry'];
    newUser = json['new_user'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    retryAfterSec = (json['retry_after_sec'] is num)
        ? (json['retry_after_sec'] as num).toInt()
        : int.tryParse(json['retry_after_sec']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['success'] = success;
    data['message'] = message;
    data['id'] = id;
    data['code'] = code;
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    data['accessTokenExpiry'] = accessTokenExpiry;
    data['refreshTokenExpiry'] = refreshTokenExpiry;
    data['new_user'] = newUser;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

/// User object returned in auth responses (verifyOtpFromMobile, verifyOtpFromEmail,
/// googleAuth, etc.). Only contains fields the Flutter UI actually reads —
/// dead fields removed during the production cleanup audit.
///
/// Field map vs backend (`buildUserResponse` in authService.js):
///   id             ← _id            — AuthService.saveTokens()
///   name           ← name           — AuthService.saveTokens()
///   email          ← email          — AuthService.saveTokens()
///   mobile         ← mobile         — AuthService.saveTokens()
///   state          ← state_name     — AuthService.saveTokens()
///   city           ← city_name      — AuthService.saveTokens()
///   stateId        ← state_id       — AuthService.saveTokens()
///   cityId         ← city_id        — AuthService.saveTokens()
///   image          ← image          — user-uploaded S3 URL (EditProfile)
///   profilePicture ← profilePicture — Google-sourced reference picture
///
/// Display priority: `image ?? profilePicture`. The uploaded S3 URL
/// wins when both exist; Google falls back cleanly otherwise.
class User {
  String? id;
  String? name;
  String? email;
  String? mobile;
  String? state;
  String? city;
  int? stateId;
  int? cityId;
  String? image;
  String? profilePicture;

  User({
    this.id,
    this.name,
    this.email,
    this.mobile,
    this.state,
    this.city,
    this.stateId,
    this.cityId,
    this.image,
    this.profilePicture,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name'];
    email = json['email'];
    mobile = json['mobile'];
    state = json['state_name'];
    city = json['city_name'];
    stateId = json['state_id'];
    cityId = json['city_id'];
    image = json['image'];
    profilePicture = json['profilePicture'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['mobile'] = mobile;
    data['state_name'] = state;
    data['city_name'] = city;
    data['state_id'] = stateId;
    data['city_id'] = cityId;
    data['image'] = image;
    data['profilePicture'] = profilePicture;
    return data;
  }
}
