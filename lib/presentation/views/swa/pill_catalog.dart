import 'package:flutter/material.dart';

/// Human-readable spec for a single Sell-with-AI pill.
///
/// A "pill" is one of the pre-canned quick-action buttons a buyer can tap
/// on an SWA conversation. The backend deals in semantic IDs (`is_available`,
/// `pickup_info`, `make_offer`, etc.) and leaves the presentation to the
/// client — this catalog maps each ID to a label + icon so the UI layer
/// stays free of magic strings.
///
/// Keep the catalog in sync with backend pill IDs surfaced via:
///   • `follow_up_pills` arrays on SWA messages
///   • `result.followUpPills` returned by pillTapHandler and keywordChat
///
/// Only the subset that the buyer can INITIATE appears here. System
/// response pill IDs (`agreement`, `counter_offer`, `below_floor_decline`,
/// `offer_disabled`, `holding_response`) are rendered via bubble styling,
/// not as tap targets — they're filtered out of the rail by
/// [PillCatalog.isInteractive].
class PillSpec {
  final String id;

  /// Terse chip text shown on the pill button. Optimised for visual
  /// economy on the horizontal rail.
  final String label;

  /// Natural-sentence text dispatched as a plain chat message when the
  /// pill is sent as text (either because the mode is human-facing or
  /// because the pill itself has no AI intent).
  ///
  /// Falls back to [label] for action pills like `make_offer` where
  /// no text send ever happens (opens the offer sheet instead).
  final String messageText;

  final IconData icon;

  /// Whether tapping this pill in an AI mode (Quick Replies / Smart
  /// Chat) should invoke the backend's pill_tap AI handler.
  ///
  ///   • `true`  — info intents (availability, condition, price, etc.)
  ///     and the `something_else` tier flow. Backend has a canned
  ///     response + a `follow_up_pills` return for these.
  ///
  ///   • `false` — conversational pills (hello, okay, please reply,
  ///     etc.). These don't map to AI intents; they're pre-written
  ///     shortcuts for common human chat messages. Always sent as
  ///     plain text and filtered out of pills_only mode (where free
  ///     text is rejected by the `pills_only_reject` guard).
  ///
  /// `make_offer` is `true` because its offer sheet in AI modes does
  /// invoke AI processing of the offer amount.
  final bool hasAiIntent;

  const PillSpec({
    required this.id,
    required this.label,
    required this.icon,
    String? messageText,
    this.hasAiIntent = true,
  }) : messageText = messageText ?? label;
}

class PillCatalog {
  const PillCatalog._();

  // Only the pills the backend actually emits in `follow_up_pills`
  // (see keywordChat.js + pillTapHandler.js) or in the opener set
  // (openerPills.js). Keeping the list tight avoids ghost chips and
  // keeps the rail predictable.
  static const Map<String, PillSpec> _byId = {
    // ── Availability / status ────────────────────────────────────────
    'availability_check': PillSpec(
      id: 'availability_check',
      label: 'Is it available?',
      messageText: 'Is it still available?',
      icon: Icons.check_circle_outline,
    ),

    // ── Pickup / logistics ───────────────────────────────────────────
    // Backend's `delivery_inquiry` response also covers pickup info —
    // the rendered reply includes pickup area + seller's slots. One
    // pill, two meanings.
    'delivery_inquiry': PillSpec(
      id: 'delivery_inquiry',
      label: 'Pickup / delivery?',
      messageText: 'Where is the pickup? Can you deliver?',
      icon: Icons.local_shipping_outlined,
    ),

    // ── Condition / details ──────────────────────────────────────────
    'condition_inquiry': PillSpec(
      id: 'condition_inquiry',
      label: 'Condition?',
      messageText: "What's the condition?",
      icon: Icons.info_outline,
    ),

    // ── Negotiation ──────────────────────────────────────────────────
    'best_price_inquiry': PillSpec(
      id: 'best_price_inquiry',
      label: 'Best price?',
      messageText: "What's your best price?",
      icon: Icons.price_change_outlined,
    ),
    // `make_offer` is intercepted client-side by ChatScreen._onPillTap
    // and opens the offer sheet — NEVER sent as a pill_tap OR as text.
    // No messageText needed; the sheet's own submit path handles both
    // AI mode (structured offer) and human mode (text "My offer: ₹X").
    'make_offer': PillSpec(
      id: 'make_offer',
      label: 'Make an offer',
      icon: Icons.local_offer_outlined,
    ),

    // ── Escape hatch (AI modes only) ─────────────────────────────────
    // Backend has tiered handling (something_else_tier1/2/3) that
    // escalates into keyword_chat or seller takeover when the buyer
    // keeps tapping it. In human-facing modes the text composer IS the
    // escape hatch, so ChatScreen filters this pill out of the rail.
    'something_else': PillSpec(
      id: 'something_else',
      label: 'Something else',
      icon: Icons.more_horiz,
    ),

    // ── Conversational pills (now AI-intent — backend renders polite
    //     canned responses from library.js, PILL_LIBRARY_VERSION=2). ──
    // Flipped to hasAiIntent: true on 2026-04-25 so the buyer sees an
    // AI-rendered reply in every mode (incl. Pills-Only). The previous
    // plain-text behaviour relied on the seller chat-mode being human
    // or keyword; in Pills-Only the pills_only_reject guard would have
    // bounced them. With AI intents the pills work uniformly.
    'hello': PillSpec(
      id: 'hello',
      label: 'Hello',
      messageText: 'Hello',
      icon: Icons.waving_hand_outlined,
    ),
    'okay': PillSpec(
      id: 'okay',
      label: 'Okay',
      messageText: 'Okay',
      icon: Icons.check_circle_outline,
    ),
    'no_problem': PillSpec(
      id: 'no_problem',
      label: 'No problem',
      messageText: 'No problem',
      icon: Icons.thumb_up_alt_outlined,
    ),
    'please_reply': PillSpec(
      id: 'please_reply',
      label: 'Please reply',
      messageText: 'Please reply',
      icon: Icons.notifications_active_outlined,
    ),
    'not_interested': PillSpec(
      id: 'not_interested',
      label: 'Not interested',
      messageText: 'Not interested, thanks',
      icon: Icons.cancel_outlined,
    ),

    // ── Closure pills — emitted by backend in follow_up_pills only
    //     when contextually valid (e.g. after a counter offer). The
    //     gateway intercepts deal/accepted before pillTapHandler:
    //     if a counter exists, the tap is re-routed through the
    //     offer engine with offer = highest_counter_shown so the
    //     same AcceptLock + AUTO_ACCEPT path runs as a normal offer.
    //     final sets needs_seller_attention; reject closes the
    //     conversation. All four hasAiIntent: true.
    'deal': PillSpec(
      id: 'deal',
      label: 'Deal',
      messageText: 'Deal',
      icon: Icons.handshake_outlined,
    ),
    'accepted': PillSpec(
      id: 'accepted',
      label: 'Accepted',
      messageText: 'Accepted',
      icon: Icons.check_circle,
    ),
    'final': PillSpec(
      id: 'final',
      label: 'This is final',
      messageText: 'This is my locked-in offer',
      icon: Icons.lock_outline,
    ),
    'reject': PillSpec(
      id: 'reject',
      label: 'Reject',
      messageText: 'Reject',
      icon: Icons.close_outlined,
    ),
  };

  /// Look up the presentation spec for a pill. Returns null for unknown
  /// IDs so callers can silently skip them rather than crash.
  static PillSpec? specFor(String pillId) => _byId[pillId];

  /// True when this pill should render as a tappable chip on the buyer's
  /// rail. Defensive: even if the backend includes a system-response pill
  /// ID (`agreement`, `counter_offer`, `below_floor_decline`, etc.) in a
  /// `follow_up_pills` array by mistake, it will be filtered out here
  /// instead of rendering as an un-labelled ghost chip.
  static bool isInteractive(String pillId) => _byId.containsKey(pillId);
}
