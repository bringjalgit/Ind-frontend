class ChatUsersModel {
  bool? success;
  List<Data>? data;
  bool? nextPage;
  int? page;

  ChatUsersModel({this.success, this.data, this.nextPage, this.page});

  ChatUsersModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    if (json['settings'] != null) {
      nextPage = json['settings']['next_page'];
      page = json['settings']['page'];
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
  String? listingId;
  String? listingTitle;

  String? userId;
  String? name;
  String? profileImage;

  String? lastMessageTime;
  String? lastMessage;
  String? lastType;
  int? unreadCount;
  bool? pinned;

  Data({
    this.listingId,
    this.listingTitle,
    this.userId,
    this.name,
    this.profileImage,
    this.lastMessageTime,
    this.lastMessage,
    this.lastType,
    this.unreadCount,
    this.pinned,
  });

  Data.fromJson(Map<String, dynamic> json) {
    listingId = json['listing_id']?.toString();
    listingTitle = json['listing_title'];

    userId = json['user_id']?.toString();
    name = json['name'];
    profileImage = json['profile_image'];

    lastMessageTime = json['last_message_time']?.toString();
    lastMessage = json['last_message'];
    lastType = json['last_type'];
    unreadCount = (json['unread_count'] is int) ? json['unread_count'] : int.tryParse(json['unread_count']?.toString() ?? '');
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
      'last_message': lastMessage,
      'last_type': lastType,
      'unread_count': unreadCount,
      'pinned': pinned,
    };
  }
}
