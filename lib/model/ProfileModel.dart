/// Response shape for POST /app/get-my-profile-details.
/// Backend returns { success, message, data: { ... } } — the backend sends
/// 12 fields in `data`, but the Flutter UI only reads 9 of them. Dead
/// fields (id, created_at, updated_at) removed during the profile cleanup.
class ProfileModel {
  bool? success;
  String? message;
  Data? data;

  ProfileModel({this.success, this.message, this.data});

  ProfileModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

/// Nested user profile data. Only fields actually displayed by the UI
/// (ProfileScreen + EditProfile) are kept here.
class Data {
  String? name;
  String? email;
  String? mobile;
  /// User-uploaded S3 URL. Set via EditProfile flow. When null/empty,
  /// display falls back to [profilePicture] (Google).
  String? image;
  /// Google-sourced reference picture. Only set during Google sign-in.
  /// Never overwrites [image]. Used as a fallback when [image] is empty.
  String? profilePicture;
  String? city_name;
  String? state_name;
  int? state_id;
  int? city_id;
  bool? email_verified;
  bool? is_verified;
  String? aadhaar_status;

  Data({
    this.name,
    this.email,
    this.mobile,
    this.image,
    this.profilePicture,
    this.city_id,
    this.email_verified,
    this.is_verified,
    this.aadhaar_status,
    this.city_name,
    this.state_id,
    this.state_name,
  });

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    mobile = json['mobile'];
    city_id = json['city_id'] is int
        ? json['city_id']
        : int.tryParse(json['city_id']?.toString() ?? '');
    city_name = json['city_name'];
    state_name = json['state_name'];
    state_id = json['state_id'] is int
        ? json['state_id']
        : int.tryParse(json['state_id']?.toString() ?? '');
    image = json['image'];
    profilePicture = json['profilePicture'];
    email_verified = json['email_verified'] == true || json['email_verified'] == 1;
    is_verified = json['is_verified'] == true || json['is_verified'] == 1;
    aadhaar_status = json['aadhaar_status']?.toString() ?? 'none';
  }

  /// Unified avatar URL for the current user. Returns null if neither
  /// an uploaded image nor a Google picture is present.
  String? get displayImage {
    if (image != null && image!.trim().isNotEmpty) return image;
    if (profilePicture != null && profilePicture!.trim().isNotEmpty) {
      return profilePicture;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['email'] = email;
    data['mobile'] = mobile;
    data['image'] = image;
    data['profilePicture'] = profilePicture;
    data['state_id'] = state_id;
    data['state_name'] = state_name;
    data['city_name'] = city_name;
    data['city_id'] = city_id;
    data['email_verified'] = email_verified;
    data['is_verified'] = is_verified;
    data['aadhaar_status'] = aadhaar_status;
    return data;
  }
}
