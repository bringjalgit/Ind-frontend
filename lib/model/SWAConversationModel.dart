/// Flutter model for the response of
///   GET /app/sell-with-ai/conversations/{conversation_id}
///
/// This is distinct from [ChatMessagesModel] (the unified inbox history)
/// because the dedicated SWA endpoint returns the richer per-conversation
/// state that the SWAChatScreen needs:
///
///   • status           — drives banners (pending / takeover / expired)
///   • chatModeSnapshot — drives composer mode (pills-only / AI / P2P)
///   • current/counter/agreed offer prices
///   • pendingAcceptanceExpiresAt — drives the cooling-off countdown
///   • messages[] with full SWA metadata (pill_id, follow_up_pills,
///     offer_amount) — same Messages class reused from ChatMessagesModel
///     so the bubble renderer stays uniform.
///
/// Backend shape reference:
///   handler/sellWithAI/conversation.js `getConversation` response.

import 'ChatMessagesModel.dart';

class SWAConversationModel {
  bool? success;
  String? message;
  SWAConversationData? data;

  SWAConversationModel({this.success, this.message, this.data});

  SWAConversationModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    data = json['data'] != null
        ? SWAConversationData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class SWAConversationData {
  // Identity
  String? id;

  // Populated nested documents
  SWAListingSummary? listing;
  SWAParticipant? buyer;
  SWAParticipant? seller;

  // State-machine fields
  String? status; // active | pending_acceptance | accepted | completed |
  //                declined | expired | seller_takeover | legal_hold
  String? chatModeSnapshot; // disabled (pills-only) | human (P2P) | keyword_chat (AI)
  String? interactionMode;

  // Seller-only scoring (stripped server-side for buyer callers)
  String? classification; // hot | good | maybe | low_priority
  Map<String, dynamic>? qualityScore; // raw — schema too rich to type strictly
  bool? needsSellerAttention;

  // Offer ladder state
  int? currentOffer;
  int? counterOffer;
  int? agreedPrice;

  // Timeline
  List<Messages>? messages;
  int? messageCount;
  List<String>? tappedPills;

  /// Opener pill rail served by the backend for fresh SWA conversations.
  /// Falls back for `lastFollowUpPills` when no message carries its
  /// own follow-ups. See /app/sell-with-ai/conversations/{id} response
  /// — the backend sends this unconditionally so client fallback logic
  /// stays simple.
  List<String>? initialPills;

  // Cooling-off / lifecycle timestamps
  String? pendingAcceptanceExpiresAt;
  String? acceptedAt;
  String? createdAt;
  String? updatedAt;

  SWAConversationData({
    this.id,
    this.listing,
    this.buyer,
    this.seller,
    this.status,
    this.chatModeSnapshot,
    this.interactionMode,
    this.classification,
    this.qualityScore,
    this.needsSellerAttention,
    this.currentOffer,
    this.counterOffer,
    this.agreedPrice,
    this.messages,
    this.messageCount,
    this.tappedPills,
    this.initialPills,
    this.pendingAcceptanceExpiresAt,
    this.acceptedAt,
    this.createdAt,
    this.updatedAt,
  });

  SWAConversationData.fromJson(Map<String, dynamic> json) {
    id = (json['_id'] ?? json['id'])?.toString();

    listing = json['listing'] != null
        ? SWAListingSummary.fromJson(
            Map<String, dynamic>.from(json['listing'] as Map))
        : null;
    buyer = json['buyer'] != null
        ? SWAParticipant.fromJson(
            Map<String, dynamic>.from(json['buyer'] as Map))
        : null;
    seller = json['seller'] != null
        ? SWAParticipant.fromJson(
            Map<String, dynamic>.from(json['seller'] as Map))
        : null;

    status = json['status']?.toString();
    chatModeSnapshot = json['chat_mode_snapshot']?.toString();
    interactionMode = json['interaction_mode']?.toString();

    classification = json['classification']?.toString();
    if (json['quality_score'] is Map) {
      qualityScore = Map<String, dynamic>.from(json['quality_score'] as Map);
    }
    needsSellerAttention = json['needs_seller_attention'] == true
        ? true
        : (json['needs_seller_attention'] == false ? false : null);

    currentOffer = _parseInt(json['current_offer']);
    counterOffer = _parseInt(json['counter_offer']);
    agreedPrice = _parseInt(json['agreed_price']);

    if (json['messages'] is List) {
      messages = (json['messages'] as List)
          .map((m) => Messages.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
    }
    messageCount = _parseInt(json['message_count']);
    if (json['tapped_pills'] is List) {
      tappedPills = (json['tapped_pills'] as List)
          .map((e) => e.toString())
          .toList();
    }
    if (json['initial_pills'] is List) {
      initialPills = (json['initial_pills'] as List)
          .map((e) => e.toString())
          .toList();
    }

    pendingAcceptanceExpiresAt =
        json['pending_acceptance_expires_at']?.toString();
    acceptedAt = json['accepted_at']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'listing': listing?.toJson(),
        'buyer': buyer?.toJson(),
        'seller': seller?.toJson(),
        'status': status,
        'chat_mode_snapshot': chatModeSnapshot,
        'interaction_mode': interactionMode,
        'classification': classification,
        'quality_score': qualityScore,
        'needs_seller_attention': needsSellerAttention,
        'current_offer': currentOffer,
        'counter_offer': counterOffer,
        'agreed_price': agreedPrice,
        'messages': messages?.map((m) => m.toJson()).toList(),
        'message_count': messageCount,
        'tapped_pills': tappedPills,
        'initial_pills': initialPills,
        'pending_acceptance_expires_at': pendingAcceptanceExpiresAt,
        'accepted_at': acceptedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  // ── Convenience getters ────────────────────────────────────────────
  // Chat-mode semantics — the backend's enum values are terse; these
  // getters give readable names. `disabled` is the "pills-only / quick
  // replies" mode (see SWAChatModeWizardScreen.dart labels), not
  // SWA-is-off. Actual SWA on/off is controlled by `is_active` on the
  // Listing, not on the Conversation.
  bool get isPillsOnly => chatModeSnapshot == 'disabled';
  bool get isAiChat => chatModeSnapshot == 'keyword_chat';
  bool get isP2PMode => chatModeSnapshot == 'human';

  // Status checks used by banner renderers.
  bool get isActive => status == 'active';
  bool get isPendingAcceptance => status == 'pending_acceptance';
  bool get isAccepted => status == 'accepted';
  bool get isSellerTakeover => status == 'seller_takeover';
  bool get isCompleted => status == 'completed';
  bool get isTerminal =>
      status == 'expired' || status == 'completed' || status == 'declined';

  /// Pill rail data source for the chat screen. Resolution order:
  ///   1. `follow_up_pills` on the most recent message that carries
  ///      any — reflects what the AI just proposed.
  ///   2. The backend-supplied `initial_pills` opener set for a fresh
  ///      conversation with no follow-ups on any message.
  ///
  /// Returns null when neither source yields anything.
  List<String>? get lastFollowUpPills {
    if (messages != null) {
      for (int i = messages!.length - 1; i >= 0; i--) {
        final pills = messages![i].followUpPills;
        if (pills != null && pills.isNotEmpty) return pills;
      }
    }
    if (initialPills != null && initialPills!.isNotEmpty) {
      return initialPills;
    }
    return null;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

/// Minimal listing view carried on the SWA conversation response.
/// Backend projects only `title price images sell_with_ai_config` (see
/// conversation.js `.populate('listing_id', ...)`), so we mirror that.
class SWAListingSummary {
  String? id;
  String? title;
  int? price;
  List<String>? images;
  Map<String, dynamic>? sellWithAIConfig;

  SWAListingSummary({
    this.id,
    this.title,
    this.price,
    this.images,
    this.sellWithAIConfig,
  });

  SWAListingSummary.fromJson(Map<String, dynamic> json) {
    id = (json['_id'] ?? json['id'])?.toString();
    title = json['title']?.toString();
    price = SWAConversationData._parseInt(json['price']);
    if (json['images'] is List) {
      images = (json['images'] as List).map((e) => e.toString()).toList();
    }
    if (json['sell_with_ai_config'] is Map) {
      sellWithAIConfig =
          Map<String, dynamic>.from(json['sell_with_ai_config'] as Map);
    }
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'price': price,
        'images': images,
        'sell_with_ai_config': sellWithAIConfig,
      };
}

/// Buyer or seller minimal view — matches the backend's
/// `.populate('buyer_id', 'name image')` projection.
class SWAParticipant {
  String? id;
  String? name;
  String? image;

  SWAParticipant({this.id, this.name, this.image});

  SWAParticipant.fromJson(Map<String, dynamic> json) {
    id = (json['_id'] ?? json['id'])?.toString();
    name = json['name']?.toString();
    image = json['image']?.toString();
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'image': image,
      };
}
