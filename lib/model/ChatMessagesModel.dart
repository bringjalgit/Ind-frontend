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
  ChatListingSummary? listing;
  List<Messages>? messages;

  // ── SWA bleed-through ─────────────────────────────────────────────────
  // Populated from /app/get-my-friend-messages whenever the (listing,
  // friend) pair has an SWA Conversation. All null on a pure-P2P thread
  // — that's the signal ChatScreen uses (via [isSwa]) to decide whether
  // to render SWA chrome (pill rail, banners, mode-aware composer) or
  // stay with the plain P2P layout. No second screen; one UI adapts.
  //
  // Backend shape: see handler/chat/chatApi.js getChatMessages response
  // (the top-level `data` object carries these as siblings of `friend`
  // and `messages`).
  String? conversationId;
  String? conversationStatus; // active | pending_acceptance | accepted |
  //                             completed | declined | expired |
  //                             seller_takeover | legal_hold
  String? chatModeSnapshot; // disabled (pills-only) | human (P2P) |
  //                           keyword_chat (AI)
  String? pendingAcceptanceExpiresAt; // ISO string — drives cooling-off countdown
  int? currentOffer;
  int? counterOffer;
  int? agreedPrice;

  /// Opener pill IDs the backend supplies for a fresh SWA conversation
  /// (no messages yet, or no message carries `follow_up_pills`). The
  /// pill rail falls back to this list via `lastFollowUpPills` when the
  /// message walk comes up empty. Empty/null on pure-P2P threads.
  List<String>? initialPills;

  Data({
    this.friend,
    this.listing,
    this.messages,
    this.conversationId,
    this.conversationStatus,
    this.chatModeSnapshot,
    this.pendingAcceptanceExpiresAt,
    this.currentOffer,
    this.counterOffer,
    this.agreedPrice,
    this.initialPills,
  });

  Data.fromJson(Map<String, dynamic> json) {
    friend =
    json['friend'] != null ? new Friend.fromJson(json['friend']) : null;
    listing = json['listing'] != null
        ? ChatListingSummary.fromJson(
            Map<String, dynamic>.from(json['listing'] as Map))
        : null;
    if (json['messages'] != null) {
      messages = <Messages>[];
      json['messages'].forEach((v) {
        messages!.add(new Messages.fromJson(v));
      });
    }
    conversationId = json['conversation_id']?.toString();
    conversationStatus = json['conversation_status']?.toString();
    chatModeSnapshot = json['chat_mode_snapshot']?.toString();
    pendingAcceptanceExpiresAt =
        json['pending_acceptance_expires_at']?.toString();
    currentOffer = _parseInt(json['current_offer']);
    counterOffer = _parseInt(json['counter_offer']);
    agreedPrice = _parseInt(json['agreed_price']);

    final rawOpener = json['initial_pills'];
    if (rawOpener is List) {
      initialPills = rawOpener.map((e) => e.toString()).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.friend != null) {
      data['friend'] = this.friend!.toJson();
    }
    if (this.listing != null) {
      data['listing'] = this.listing!.toJson();
    }
    if (this.messages != null) {
      data['messages'] = this.messages!.map((v) => v.toJson()).toList();
    }
    data['conversation_id'] = conversationId;
    data['conversation_status'] = conversationStatus;
    data['chat_mode_snapshot'] = chatModeSnapshot;
    data['pending_acceptance_expires_at'] = pendingAcceptanceExpiresAt;
    data['current_offer'] = currentOffer;
    data['counter_offer'] = counterOffer;
    data['agreed_price'] = agreedPrice;
    data['initial_pills'] = initialPills;
    return data;
  }

  // ── Convenience getters ───────────────────────────────────────────────
  // ChatScreen reads these instead of comparing magic strings. Keeps the
  // mode-name drift (backend 'disabled' ≠ user-facing "Quick Replies")
  // out of the UI layer.
  //
  // `isSwa` keys off `chatModeSnapshot != null` — NOT `conversationId`
  // — because the backend now surfaces the listing's chat_mode on
  // fresh chats (before any Conversation doc is created). Using
  // conversationId would leave the rail hidden until after the buyer
  // sent their first message, breaking the opener-pill flow.
  bool get isSwa => chatModeSnapshot != null;
  bool get isPillsOnly => chatModeSnapshot == 'disabled';
  bool get isAiChat => chatModeSnapshot == 'keyword_chat';
  bool get isP2PMode => chatModeSnapshot == 'human';

  bool get isActive => conversationStatus == 'active';
  bool get isPendingAcceptance => conversationStatus == 'pending_acceptance';
  bool get isAccepted => conversationStatus == 'accepted';
  bool get isSellerTakeover => conversationStatus == 'seller_takeover';
  bool get isCompleted => conversationStatus == 'completed';
  bool get isTerminal =>
      conversationStatus == 'expired' ||
      conversationStatus == 'completed' ||
      conversationStatus == 'declined';

  /// Pill rail data source for the chat screen. Resolution order:
  ///   1. The `follow_up_pills` on the most recent message that carries
  ///      any — reflects what the AI just proposed as next steps.
  ///   2. The backend-supplied `initial_pills` opener set — used when
  ///      the thread has no messages yet (fresh conversation) or when
  ///      no message carries follow-ups.
  ///
  /// Returns null on pure-P2P threads (no SWA conversation, no opener
  /// set sent by the backend).
  ///
  /// NOTE: messages in this model are stored NEWEST-FIRST by the cubit
  /// (see ChatMessagesCubit.fetchMessages), so walk FORWARD to find the
  /// most recent follow-up set.
  List<String>? get lastFollowUpPills {
    if (messages != null) {
      for (final m in messages!) {
        final pills = m.followUpPills;
        if (pills != null && pills.isNotEmpty) return pills;
      }
    }
    // No follow-ups on any message → fall back to the backend-supplied
    // opener set for fresh SWA conversations. Null on pure-P2P threads
    // where the backend sends no opener set.
    if (initialPills != null && initialPills!.isNotEmpty) {
      return initialPills;
    }
    return null;
  }

  DateTime? get pendingAcceptanceExpiresAtDate {
    if (pendingAcceptanceExpiresAt == null) return null;
    return DateTime.tryParse(pendingAcceptanceExpiresAt!);
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
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

/// Minimal listing projection embedded in /app/get-my-friend-messages.
/// Backend sends `{id, title, price, sold}` — see chatApi.js response
/// shape. Used by the offer sheet to show the listed price as a
/// reference ("Listed at ₹55,000") and by the future "item sold"
/// banner to hide the composer once the listing is closed.
class ChatListingSummary {
  dynamic id;
  String? title;
  int? price;
  bool? sold;

  ChatListingSummary({this.id, this.title, this.price, this.sold});

  ChatListingSummary.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    title = json['title']?.toString();
    price = _parseInt(json['price']);
    sold = json['sold'] == true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'sold': sold,
      };

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

class Messages {
  dynamic id;
  String? senderId;
  String? receiverId;
  // `type` is the legacy P2P message type — 'text' or 'image'. On the REST
  // unified timeline the backend collapses every SWA message to one of
  // these two values for backwards compatibility. Richer SWA semantics
  // live on `swaType` (see below) and/or are inferred from `sender` +
  // `pillId`.
  String? type;
  String? message;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;

  // ── SWA fields ────────────────────────────────────────────────────────
  // Populated from two sources:
  //   a) REST /app/get-my-friend-messages — snake_case fields on each
  //      timeline row (pill_id, offer_amount, source, sender).
  //   b) WebSocket `newMessage` push from messaging.js — camelCase
  //      (swaType, decision, counterPrice, acceptPrice, followUpPills,
  //      isSystemMessage).
  // fromJson reads both casings so the same model serves both wire
  // shapes. Absent fields stay null.
  bool isSystemMessage;
  String? swaType;          // pill_tap / pill_response / offer / offer_accepted / offer_response / counter_offer / system_event / human_text / agreement / decline_reason / keyword_chat_response
  String? decision;         // AUTO_ACCEPT / AUTO_COUNTER / AUTO_DECLINE / ROUND_CAP_EXHAUSTED (ORACLE_BLOCK normalized to AUTO_DECLINE server-side)
  int? counterPrice;
  int? acceptPrice;
  String? pillId;           // semantic id like 'is_available', 'agreement', 'below_floor_decline'
  List<String>? followUpPills; // pill IDs for the next buyer action — drives the pill rail
  int? offerAmount;         // amount attached to offer/counter_offer messages
  String? source;           // 'p2p' | 'swa' — REST unified timeline only
  String? sender;           // 'buyer' | 'seller' | 'system' | 'keyword_bot' — REST SWA side only

  // ── Convenience flags for renderer branching ─────────────────────────
  bool get isPillResponse => swaType == 'pill_response';
  bool get isOfferResponse =>
      swaType == 'offer_response' || swaType == 'offer_accepted';
  bool get isSystemEvent => isSystemMessage || sender == 'system';
  bool get isAgreement => pillId == 'agreement';

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
        this.acceptPrice,
        this.pillId,
        this.followUpPills,
        this.offerAmount,
        this.source,
        this.sender});

  Messages copyWith({
    dynamic id,
    String? senderId,
    String? receiverId,
    String? type,
    String? message,
    String? imageUrl,
    String? createdAt,
    String? updatedAt,
    bool? isSystemMessage,
    String? swaType,
    String? decision,
    int? counterPrice,
    int? acceptPrice,
    String? pillId,
    List<String>? followUpPills,
    int? offerAmount,
    String? source,
    String? sender,
  }) {
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
      pillId: pillId ?? this.pillId,
      followUpPills: followUpPills ?? this.followUpPills,
      offerAmount: offerAmount ?? this.offerAmount,
      source: source ?? this.source,
      sender: sender ?? this.sender,
    );
  }

  Messages.fromJson(Map<String, dynamic> json)
      : isSystemMessage = json['isSystemMessage'] == true {
    // Accept both snake_case (REST — /app/get-my-friend-messages) and
    // camelCase (WebSocket `newMessage` push from messaging.js). Either
    // side wins when only one is present; snake_case takes precedence
    // when both are set so the REST fetch never gets overridden by a
    // stale WS field.
    id = (json['id'] ?? json['_id'])?.toString();
    senderId = (json['sender_id'] ?? json['senderId'])?.toString();
    receiverId = (json['receiver_id'] ?? json['receiverId'])?.toString();
    type = json['type'];
    // `content` is the SWA-endpoint name for the same field REST's
    // unified timeline calls `message`. Fall back so one model serves
    // /app/get-my-friend-messages and /app/sell-with-ai/conversations/{id}.
    message = json['message'] ?? json['content'];
    imageUrl = json['image_url'] ?? json['imageUrl'];
    createdAt = (json['created_at'] ?? json['createdAt'])?.toString();
    updatedAt = (json['updated_at'] ?? json['updatedAt'])?.toString();

    // SWA fields — parse both snake_case (REST) and camelCase (WS).
    swaType = json['swaType']?.toString() ?? json['swa_type']?.toString();
    decision = json['decision']?.toString();
    counterPrice = _parseInt(json['counterPrice'] ?? json['counter_price']);
    acceptPrice = _parseInt(json['acceptPrice'] ?? json['accept_price']);
    pillId = json['pill_id']?.toString() ?? json['pillId']?.toString();
    offerAmount = _parseInt(json['offer_amount'] ?? json['offerAmount']);
    source = json['source']?.toString();
    sender = json['sender']?.toString();

    final raw = json['followUpPills'] ?? json['follow_up_pills'];
    if (raw is List) {
      followUpPills = raw.map((e) => e.toString()).toList();
    }
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
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
    data['isSystemMessage'] = this.isSystemMessage;
    data['swaType'] = this.swaType;
    data['decision'] = this.decision;
    data['counterPrice'] = this.counterPrice;
    data['acceptPrice'] = this.acceptPrice;
    data['pill_id'] = this.pillId;
    data['follow_up_pills'] = this.followUpPills;
    data['offer_amount'] = this.offerAmount;
    data['source'] = this.source;
    data['sender'] = this.sender;
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
