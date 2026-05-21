// notification_intent.dart
//
// Stores a deferred chat-open intent across app cold starts. Used when
// the user taps a chat-message notification but the UI isn't ready yet
// (e.g. splash hasn't routed to /dashboard yet) — we stash the target
// here, then Dashboard.initState consumes it and pushes /chat with the
// full param set.
//
// `listingId` is required: chats in this app are scoped to (listing,
// peer) pairs, so without it /chat falls back to listingId="0" and the
// PrivateChatCubit fails to load any messages — the symptom users see
// is "tap notification, land on a blank/erroring chat screen".
class NotificationIntent {
  static String? _pendingReceiverId;
  static String? _pendingListingId;
  static String? _pendingListingTitle;

  // Deferred dashboard-tab intent across cold start. Used when a
  // non-chat notification (e.g. listing approved/rejected → My Ads)
  // is tapped before the UI is ready. Dashboard.initState consumes it.
  static int? _pendingTab;

  /// Save a target dashboard tab (0=Home, 1=My Ads, ...) until UI is ready.
  static void setPendingTab(int tab) {
    _pendingTab = tab;
  }

  /// Read once and clear the pending tab.
  static int? consumePendingTab() {
    final t = _pendingTab;
    _pendingTab = null;
    return t;
  }

  /// Save the chat target until UI is ready (e.g., Dashboard shown).
  static void setPendingChat({
    required String receiverId,
    required String listingId,
    String? listingTitle,
  }) {
    _pendingReceiverId = receiverId;
    _pendingListingId = listingId;
    _pendingListingTitle = listingTitle;
  }

  /// Read once and clear. Returns null if no pending chat or if
  /// listingId is missing — without listingId the chat screen can't
  /// resolve a thread, so a half-set intent is treated as no intent.
  static PendingChat? consumePendingChat() {
    final r = _pendingReceiverId;
    final l = _pendingListingId;
    final t = _pendingListingTitle;
    _pendingReceiverId = null;
    _pendingListingId = null;
    _pendingListingTitle = null;
    if (r == null || r.isEmpty || l == null || l.isEmpty) return null;
    return PendingChat(receiverId: r, listingId: l, listingTitle: t);
  }

  static bool get hasPending =>
      (_pendingReceiverId?.isNotEmpty ?? false) &&
      (_pendingListingId?.isNotEmpty ?? false);
}

class PendingChat {
  final String receiverId;
  final String listingId;
  final String? listingTitle;
  const PendingChat({
    required this.receiverId,
    required this.listingId,
    this.listingTitle,
  });
}
