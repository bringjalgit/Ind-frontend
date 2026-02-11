class ChatUsersModel {
  bool? success;
  List<Data>? data;

  ChatUsersModel({this.success, this.data});

  ChatUsersModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.map((v) => v.toJson()).toList(),
    };
  }
}

class Data {
  int? listingId;
  String? listingTitle;

  int? userId;
  String? name;
  String? profileImage;

  String? lastMessageTime;
  int? unreadCount;
  bool? pinned;

  Data({
    this.listingId,
    this.listingTitle,
    this.userId,
    this.name,
    this.profileImage,
    this.lastMessageTime,
    this.unreadCount,
    this.pinned,
  });

  Data.fromJson(Map<String, dynamic> json) {
    listingId = json['listing_id'];
    listingTitle = json['listing_title'];

    userId = json['user_id'];
    name = json['name'];
    profileImage = json['profile_image'];

    lastMessageTime = json['last_message_time'];
    unreadCount = json['unread_count'];
    pinned = json['pinned'];
  }

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'listing_title': listingTitle,
      'user_id': userId,
      'name': name,
      'profile_image': profileImage,
      'last_message_time': lastMessageTime,
      'unread_count': unreadCount,
      'pinned': pinned,
    };
  }
}
