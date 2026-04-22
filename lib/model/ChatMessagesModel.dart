class ChatMessagesModel {
  bool? success;
  String? message;
  int? status;
  Data? data;
  Settings? settings;

  ChatMessagesModel(
      {this.success, this.message, this.status, this.data, this.settings});

  ChatMessagesModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    status = json['status'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    settings = json['settings'] != null
        ? new Settings.fromJson(json['settings'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (this.settings != null) {
      data['settings'] = this.settings!.toJson();
    }
    return data;
  }
}

class Data {
  Friend? friend;
  List<Messages>? messages;

  // SWA bleed-through surfaced by the unified chat endpoint so the
  // ChatScreen can render a status banner + deep-link to the SWA
  // dashboard without a second round-trip. `conversationStatus` is
  // the state-machine value: active | pending_acceptance | accepted |
  // completed | declined | expired | seller_takeover | legal_hold.
  // Null when the thread is pure P2P (no SWA conversation ever created).
  String? conversationId;
  String? conversationStatus;

  Data({
    this.friend,
    this.messages,
    this.conversationId,
    this.conversationStatus,
  });

  Data.fromJson(Map<String, dynamic> json) {
    friend =
    json['friend'] != null ? new Friend.fromJson(json['friend']) : null;
    if (json['messages'] != null) {
      messages = <Messages>[];
      json['messages'].forEach((v) {
        messages!.add(new Messages.fromJson(v));
      });
    }
    conversationId = json['conversation_id']?.toString();
    conversationStatus = json['conversation_status']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.friend != null) {
      data['friend'] = this.friend!.toJson();
    }
    if (this.messages != null) {
      data['messages'] = this.messages!.map((v) => v.toJson()).toList();
    }
    data['conversation_id'] = conversationId;
    data['conversation_status'] = conversationStatus;
    return data;
  }
}

class Friend {
  dynamic id;
  String? name;
  String? image;
  String? mobile;

  Friend({this.id, this.name, this.image,this.mobile});

  Friend.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    name = json['name'];
    image = json['image'];
    mobile = json['mobile']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image'] = this.image;
    data['mobile'] = this.mobile;
    return data;
  }
}

class Messages {
  dynamic id;
  String? senderId;
  String? receiverId;
  String? type;
  String? message;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;

  // SWA fields (populated when message comes from AI pipeline via WebSocket)
  bool isSystemMessage;
  String? swaType;     // pill_response, offer_accepted, offer_response, keyword_chat_response, etc.
  String? decision;    // AUTO_ACCEPT, AUTO_COUNTER, AUTO_DECLINE, ROUND_CAP_EXHAUSTED
  int? counterPrice;
  int? acceptPrice;

  Messages(
      {this.id,
        this.senderId,
        this.receiverId,
        this.type,
        this.message,
        this.imageUrl,
        this.createdAt,
        this.updatedAt,
        this.isSystemMessage = false,
        this.swaType,
        this.decision,
        this.counterPrice,
        this.acceptPrice});

  Messages copyWith({dynamic id, String? senderId, String? receiverId, String? type, String? message, String? imageUrl, String? createdAt, String? updatedAt, bool? isSystemMessage, String? swaType, String? decision, int? counterPrice, int? acceptPrice}) {
    return Messages(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      swaType: swaType ?? this.swaType,
      decision: decision ?? this.decision,
      counterPrice: counterPrice ?? this.counterPrice,
      acceptPrice: acceptPrice ?? this.acceptPrice,
    );
  }

  Messages.fromJson(Map<String, dynamic> json)
      : isSystemMessage = false {
    id = (json['id'] ?? json['_id'])?.toString();
    senderId = json['sender_id']?.toString();
    receiverId = json['receiver_id']?.toString();
    type = json['type'];
    message = json['message'];
    imageUrl = json['image_url'];
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['sender_id'] = this.senderId;
    data['receiver_id'] = this.receiverId;
    data['type'] = this.type;
    data['message'] = this.message;
    data['image_url'] = this.imageUrl;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class Settings {
  int? count;
  int? page;
  int? rowsPerPage;
  int? totalPages;
  bool? nextPage;
  bool? prevPage;

  Settings(
      {this.count,
        this.page,
        this.rowsPerPage,
        this.totalPages,
        this.nextPage,
        this.prevPage});

  Settings.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    page = json['page'];
    rowsPerPage = json['rows_per_page'];
    totalPages = json['total_pages'];
    nextPage = json['next_page'];
    prevPage = json['prev_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['count'] = this.count;
    data['page'] = this.page;
    data['rows_per_page'] = this.rowsPerPage;
    data['total_pages'] = this.totalPages;
    data['next_page'] = this.nextPage;
    data['prev_page'] = this.prevPage;
    return data;
  }
}
