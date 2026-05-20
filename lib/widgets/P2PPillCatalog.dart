/// Quick-reply pill catalog for non-SWA P2P chats.
///
/// ── Why this exists ────────────────────────────────────────────────
/// Most marketplace chats follow the same script: hello → is this
/// available → best price → can I see it → deal. Forcing both sides to
/// type all of that out is friction. This catalog provides tappable
/// chips above the text composer so buyers and sellers can move through
/// the common path with one tap each. Free-text composer still works —
/// pills are accelerators, not replacements.
///
/// ── Scope ──────────────────────────────────────────────────────────
/// P2P (non-SWA) chats only. SWA conversations have their own engine-
/// driven pill catalog in `src/services/swa/pills/library.js` and that
/// path is intentionally untouched. The Dart layer here is the single
/// source of truth for P2P pills — there's no server-side mapping
/// table; the backend just round-trips the `intent` field.
///
/// ── Contract ───────────────────────────────────────────────────────
/// Every pill has:
///   • id     — the intent id stored on `ChatMessage.intent`
///   • label  — what the user sees on the chip
///   • text   — what gets sent as the message body when tapped
///
/// The seller's chip strip is contextual: it reads the most-recent
/// buyer ChatMessage's `intent` and renders the chips listed in
/// [sellerAnswersFor]. When the buyer hasn't tapped any pill yet (or
/// only sent free text / images), the strip falls back to
/// [sellerInitiatorPills] — generic prompts the seller can push to
/// re-engage a quiet buyer.
library;

/// Visual treatment for a pill chip.
///
///   • `neutral`  — the default. Light grey background, used for all
///                  question / clarification pills. Carries no emotional
///                  charge so the rail doesn't fight the conversation.
///   • `primary`  — brand-filled. Reserved for the single forward-action
///                  pill ("Deal ✓") so it visually leads the row.
///   • `danger`   — outlined red. Reserved for terminal/negative actions
///                  ("Not interested", "Reject") so the user sees a
///                  consequence cue before tapping.
enum PillStyle { neutral, primary, danger }

class P2PPill {
  final String id;
  final String label;
  final String text;
  final PillStyle style;
  const P2PPill({
    required this.id,
    required this.label,
    required this.text,
    this.style = PillStyle.neutral,
  });
}

class P2PPillCatalog {
  P2PPillCatalog._();

  /// All pills indexed by id, so the receiver-side can look up the
  /// labelled chip for any incoming intent without keeping a second
  /// list in sync.
  static const Map<String, P2PPill> _byId = {
    // ── BUYER PILLS ──────────────────────────────────────────────
    'greet':         P2PPill(id: 'greet',         label: 'Hello',                  text: 'Hello'),
    'ask_available': P2PPill(id: 'ask_available', label: 'Is this available?',     text: 'Is this still available?'),
    'ask_best_price':P2PPill(id: 'ask_best_price',label: 'Best price?',            text: "What's your best price?"),
    'make_offer':    P2PPill(id: 'make_offer',    label: 'Make an offer',          text: "I'd like to make an offer"),
    'ask_condition': P2PPill(id: 'ask_condition', label: 'Condition?',             text: "What's the condition?"),
    'ask_visit':     P2PPill(id: 'ask_visit',     label: 'Can I see it today?',    text: 'Can I see it today?'),
    'ask_location':  P2PPill(id: 'ask_location',  label: 'Where can I see it?',    text: 'Where can I see it?'),
    'ask_box_bill':  P2PPill(id: 'ask_box_bill',  label: 'Original box & bill?',   text: 'Do you have the original box and bill?'),
    'ack_ok':        P2PPill(id: 'ack_ok',        label: 'OK',                     text: 'OK'),
    'not_interested':P2PPill(id: 'not_interested',label: 'Not interested',         text: "I'm not interested", style: PillStyle.danger),
    'deal':          P2PPill(id: 'deal',          label: 'Deal ✓',                 text: "Deal — I'll take it", style: PillStyle.primary),
    'reject':        P2PPill(id: 'reject',        label: 'Reject',                 text: "I'll pass, thanks",   style: PillStyle.danger),

    // ── SELLER ANSWER PILLS (used per-intent below) ──────────────
    'greet_reply':          P2PPill(id: 'greet_reply',          label: 'Hi 👋',                     text: 'Hi 👋'),

    'avail_yes':            P2PPill(id: 'avail_yes',            label: 'Yes, available',            text: "Yes, it's still available"),
    'avail_sold':           P2PPill(id: 'avail_sold',           label: 'Sold',                      text: "Sorry, it's sold"),
    'avail_busy':           P2PPill(id: 'avail_busy',           label: 'Talking to another buyer', text: "I'm in talks with another buyer right now"),

    'price_final':          P2PPill(id: 'price_final',          label: 'This is the final price',   text: 'This is my final price'),
    'price_negotiable':     P2PPill(id: 'price_negotiable',     label: 'Negotiable',                text: 'Negotiable — send your offer'),
    'price_no_discount':    P2PPill(id: 'price_no_discount',    label: 'No further discount',       text: "I can't go any lower"),

    'offer_accept':         P2PPill(id: 'offer_accept',         label: 'Accept',                    text: 'Accepted',                              style: PillStyle.primary),
    'offer_counter_say':    P2PPill(id: 'offer_counter_say',    label: 'Send your number',          text: 'Tell me what you have in mind'),
    'offer_decline':        P2PPill(id: 'offer_decline',        label: 'Decline',                   text: "Sorry, that's too low",                style: PillStyle.danger),

    'cond_excellent':       P2PPill(id: 'cond_excellent',       label: 'Excellent',                 text: 'Excellent condition'),
    'cond_good':            P2PPill(id: 'cond_good',            label: 'Good',                      text: 'Good condition'),
    'cond_used':            P2PPill(id: 'cond_used',            label: 'Used a few times',          text: 'Used a few times, well maintained'),
    'cond_like_new':        P2PPill(id: 'cond_like_new',        label: 'Like new',                  text: 'Like new'),

    'visit_today':          P2PPill(id: 'visit_today',          label: 'Yes, today',                text: 'Yes, today works'),
    'visit_tomorrow':       P2PPill(id: 'visit_tomorrow',       label: 'Tomorrow works',            text: 'Tomorrow works for me'),
    'visit_send_loc':       P2PPill(id: 'visit_send_loc',       label: 'Send your location',       text: 'Send your location, I will come'),

    'loc_share':            P2PPill(id: 'loc_share',            label: 'Sharing location',         text: 'Sharing my location 📍'),
    'loc_in_desc':          P2PPill(id: 'loc_in_desc',          label: 'Address is in listing',    text: 'The address is in the listing description'),

    'box_bill_both':        P2PPill(id: 'box_bill_both',        label: 'Box & bill',               text: 'Yes, box and bill available'),
    'box_only':             P2PPill(id: 'box_only',             label: 'Only box',                  text: 'Only the box'),
    'bill_only':            P2PPill(id: 'bill_only',            label: 'Only bill',                 text: 'Only the bill'),
    'box_bill_neither':     P2PPill(id: 'box_bill_neither',     label: 'Neither',                   text: 'Neither — just the item'),

    'deal_great':           P2PPill(id: 'deal_great',           label: 'Great, deal!',              text: 'Great, deal! 🎉',                       style: PillStyle.primary),
    'deal_meet':            P2PPill(id: 'deal_meet',            label: 'Let\'s meet to finalize',  text: "Let's meet to finalize"),
    'deal_when':            P2PPill(id: 'deal_when',            label: 'When can you come?',        text: 'When can you come to collect it?'),

    'reject_ok':            P2PPill(id: 'reject_ok',            label: 'OK, thanks',                text: 'OK, thanks for letting me know'),
    'reject_bye':           P2PPill(id: 'reject_bye',           label: 'Best wishes',               text: 'Best wishes!'),
    'reject_changed_mind':  P2PPill(id: 'reject_changed_mind',  label: 'Change of mind? Let me know', text: 'Let me know if you change your mind'),

    // ── SELLER INITIATOR PILLS ───────────────────────────────────
    'still_interested':     P2PPill(id: 'still_interested',     label: 'Still interested?',         text: 'Are you still interested?'),
    'when_visit':           P2PPill(id: 'when_visit',           label: 'When can you visit?',       text: 'When can you come to see it?'),
    'final_reminder':       P2PPill(id: 'final_reminder',       label: 'Final price — let me know', text: 'Final price — let me know if interested'),
    'send_your_number':     P2PPill(id: 'send_your_number',     label: 'Bargain? Send your number', text: 'If you want to bargain, send me your number'),
  };

  /// Top row of the buyer's two-row coupled rail. Opening / asking
  /// intents — the user is starting or probing the conversation.
  ///
  /// NOTE (2026-05-17): `make_offer` was removed from this list when
  /// the dedicated hero "Make an Offer" pill landed above the rail.
  /// The pill catalog entry is still kept around in [_byId] because
  /// the seller's contextual answers (offer_accept / offer_counter_say
  /// / offer_decline) are keyed off `make_offer` as the buyer-intent.
  static const List<String> buyerPillIdsTop = [
    'greet',
    'ask_available',
    'ask_best_price',
    'ask_condition',
    'ask_visit',
  ];

  /// Bottom row of the buyer's two-row coupled rail. Logistics +
  /// closure intents — visiting, asking about box/bill, ack / deal /
  /// reject. Ordered so the destructive options sit at the far end
  /// (visually furthest from the safest taps).
  static const List<String> buyerPillIdsBottom = [
    'ask_location',
    'ask_box_bill',
    'ack_ok',
    'deal',
    'not_interested',
    'reject',
  ];

  /// Flat list, kept for callers (eg analytics) that want every buyer
  /// pill id regardless of row.
  static List<String> get buyerPillIds =>
      [...buyerPillIdsTop, ...buyerPillIdsBottom];

  /// Ordered list of pills shown to the seller when there's no recent
  /// buyer intent to respond to (fresh chat, or buyer's last message
  /// was free text / image / a pill without a contextual answer).
  static const List<String> sellerInitiatorPillIds = [
    'still_interested',
    'when_visit',
    'final_reminder',
    'send_your_number',
  ];

  /// Per-buyer-intent → seller answer pill ids. Empty list = fall back
  /// to [sellerInitiatorPillIds].
  static const Map<String, List<String>> _sellerAnswersByBuyerIntent = {
    'greet':          ['greet_reply'],
    'ask_available':  ['avail_yes', 'avail_sold', 'avail_busy'],
    'ask_best_price': ['price_final', 'price_negotiable', 'price_no_discount'],
    'make_offer':     ['offer_accept', 'offer_counter_say', 'offer_decline'],
    'ask_condition':  ['cond_excellent', 'cond_good', 'cond_used', 'cond_like_new'],
    'ask_visit':      ['visit_today', 'visit_tomorrow', 'visit_send_loc'],
    'ask_location':   ['loc_share', 'loc_in_desc'],
    'ask_box_bill':   ['box_bill_both', 'box_only', 'bill_only', 'box_bill_neither'],
    'ack_ok':         [],
    'not_interested': ['reject_ok', 'reject_changed_mind'],
    'deal':           ['deal_great', 'deal_meet', 'deal_when'],
    'reject':         ['reject_ok', 'reject_bye', 'reject_changed_mind'],
  };

  /// Resolve a pill by its intent id. Returns null for unknown ids
  /// (e.g. a message from an older client that doesn't know this id).
  static P2PPill? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    return _byId[id];
  }

  /// The buyer's always-visible chip strip — flat list, kept for any
  /// caller that prefers a single row (eg landscape).
  static List<P2PPill> get buyerPills =>
      buyerPillIds.map((id) => _byId[id]!).toList(growable: false);

  /// Top + bottom rows for the two-row coupled scroll. The ChatScreen
  /// renders them as two ListView.builders whose offsets are mirrored
  /// (top scrolls right → bottom scrolls left).
  static List<P2PPill> get buyerPillsTop =>
      buyerPillIdsTop.map((id) => _byId[id]!).toList(growable: false);
  static List<P2PPill> get buyerPillsBottom =>
      buyerPillIdsBottom.map((id) => _byId[id]!).toList(growable: false);

  /// The seller's chip strip, derived from the buyer's last intent.
  /// Falls back to seller-initiator pills when there's no useful
  /// context (null / unknown id / empty answer list).
  static List<P2PPill> sellerAnswersFor(String? lastBuyerIntent) {
    if (lastBuyerIntent == null || lastBuyerIntent.isEmpty) {
      return sellerInitiatorPills;
    }
    final answerIds = _sellerAnswersByBuyerIntent[lastBuyerIntent];
    if (answerIds == null || answerIds.isEmpty) return sellerInitiatorPills;
    return answerIds
        .map((id) => _byId[id])
        .whereType<P2PPill>()
        .toList(growable: false);
  }

  /// Seller's fallback chip strip when there's no buyer intent to
  /// respond to. Exposed separately so the seller-empty-chat case can
  /// render the same set directly.
  static List<P2PPill> get sellerInitiatorPills =>
      sellerInitiatorPillIds.map((id) => _byId[id]!).toList(growable: false);
}
