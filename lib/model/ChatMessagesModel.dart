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
  // Phase 2 spam-lowball cooldown (2026-04-26): null when not
  // applicable. ChatScreen renders the "Chat paused" banner when
  // conversationStatus == 'closed' && expiryReason == 'spam_lowball'
  // && completedAt + 48h is still in the future. Computed entirely
  // client-side; no extra server call.
  String? expiryReason;
  String? completedAt; // ISO timestamp string

  /// True when the caller owns the listing (i.e. is the seller). Set
  /// by the backend in [chatApi.js getChatMessages]. Used by ChatScreen
  /// to hide the buyer-only pill rail and force the regular text
  /// composer when the seller opens this thread from his chat list.
  /// Defaults to false on responses that don't carry the field (legacy /
  /// cached payloads), keeping the existing buyer experience intact.
  bool viewerIsSeller = false;

  /// Opener pill IDs the backend supplies for a fresh SWA conversation
  /// (no messages yet, or no message carries `follow_up_pills`). The
  /// pill rail falls back to this list via `lastFollowUpPills` when the
  /// message walk comes up empty. Empty/null on pure-P2P threads.
  List<String>? initialPills;

  /// True when the listing's category supports SWA-style chat (offers,
  /// pills, AI-managed flow). False for the four blocklist categories
  /// (Community, Events, Films, Find Investor) where chat must be
  /// plain text P2P only. ChatScreen reads this to hide the P2P
  /// pill rail / hero "Make an offer" pill so buyers don't see
  /// nonsensical openers on a community post. Defaults to true so
  /// older API responses don't accidentally suppress pills.
  bool swaCategoryEligible = true;

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
    this.expiryReason,
    this.completedAt,
    this.initialPills,
    this.viewerIsSeller = false,
    this.swaCategoryEligible = true,
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
    expiryReason = json['expiry_reason']?.toString();
    completedAt = json['completed_at']?.toString();
    viewerIsSeller = json['viewer_is_seller'] == true;
    // Default true when the field is absent — keeps older / cached
    // responses behaving exactly as before. Only an explicit `false`
    // from the backend suppresses pills.
    swaCategoryEligible = json['swa_category_eligible'] != false;

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
    data['expiry_reason'] = expiryReason;
    data['completed_at'] = completedAt;
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

  // ── Phase 2 spam-lowball cooldown (2026-04-26) ───────────────────────
  // Cooldown duration is 48h, hard-coded in lockstep with the backend's
  // SPAM_LOWBALL_COOLDOWN_HOURS constant in pricing/counter.js.
  // Bumping one without the other will desync seller dashboard /
  // buyer banner — keep them aligned.
  static const int _spamLowballCooldownHours = 48;

  /// True when this conversation was closed by SPAM_LOWBALL_CLOSE
  /// AND the cooldown is still in effect. ChatScreen renders the
  /// "Chat paused" banner instead of the input composer when true.
  bool get isSpamLowballCooldown {
    if (conversationStatus != 'closed') return false;
    if (expiryReason != 'spam_lowball') return false;
    final ms = _spamLowballCooldownEndMs;
    return ms != null && ms > DateTime.now().millisecondsSinceEpoch;
  }

  /// Whole hours remaining until the cooldown elapses, ROUNDED UP so a
  /// buyer 5 minutes into the cooldown still sees "48 hours" instead
  /// of "47 hours". Returns 0 when the cooldown is not applicable or
  /// has already elapsed.
  int get spamLowballCooldownHoursRemaining {
    final endMs = _spamLowballCooldownEndMs;
    if (endMs == null) return 0;
    final remainingMs = endMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return 0;
    // Round UP — match the backend's Math.ceil so the two stay in sync.
    return ((remainingMs + 3599999) ~/ 3600000).clamp(1, 999);
  }

  int? get _spamLowballCooldownEndMs {
    if (completedAt == null || completedAt!.isEmpty) return null;
    final closedAt = DateTime.tryParse(completedAt!);
    if (closedAt == null) return null;
    return closedAt.millisecondsSinceEpoch +
        _spamLowballCooldownHours * 3600 * 1000;
  }

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
  // First listing image — used by the chat-screen listing context
  // strip above the message thread. Null when the listing has no
  // images (Flutter falls back to a placeholder icon). Set server-
  // side by chatApi.js getChatMessages.
  String? image;

  ChatListingSummary({this.id, this.title, this.price, this.sold, this.image});

  ChatListingSummary.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    title = json['title']?.toString();
    price = _parseInt(json['price']);
    sold = json['sold'] == true;
    image = json['image']?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'sold': sold,
        'image': image,
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

  // P2P pill-tap intent (non-SWA chats only). When a buyer or seller
  // taps a chip from `P2PPillCatalog`, the intent id rides along with
  // the message. Receiver uses it to render contextual answer chips.
  // Null on free-text and image messages, and on all SWA paths (those
  // carry intent semantics via `pillId` / `swaType`).
  String? intent;

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
        this.sender,
        this.intent});

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
    String? intent,
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
      intent: intent ?? this.intent,
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

    // P2P pill-tap intent id (round-tripped through ChatMessage.intent
    // on the server). Snake_case + camelCase both accepted for
    // forward-compat with future endpoints.
    intent = json['intent']?.toString();
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
    data['intent'] = this.intent;
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
