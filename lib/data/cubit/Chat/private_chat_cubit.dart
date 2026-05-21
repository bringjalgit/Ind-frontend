import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/utils/AppLogger.dart';

import '../../../model/ChatMessagesModel.dart';
import '../../../services/SocketService.dart';

class PrivateChatState {
  final List<Messages> messages;
  final bool isPeerTyping;

  const PrivateChatState({this.messages = const [], this.isPeerTyping = false});

  PrivateChatState copyWith({List<Messages>? messages, bool? isPeerTyping}) =>
      PrivateChatState(
        messages: messages ?? this.messages,
        isPeerTyping: isPeerTyping ?? this.isPeerTyping,
      );
}

class PrivateChatCubit extends Cubit<PrivateChatState> {
  final String currentUserId;
  final String receiverId;
  final String listingId;

  Timer? _peerTypingClearTimer;
  Timer? _myTypingThrottle;

  /// Broadcast stream of `conversationUpdated` WS events that match the
  /// current (listing, receiver) pair. ChatScreen subscribes so it can
  /// re-fetch the full Conversation state (banner, offer, pills) when
  /// the backend reports a seller-driven or cron-driven state change.
  /// Broadcast-scoped because ChatScreen is the sole consumer but may
  /// rebuild on hot-reload; broadcast allows multiple subscribers
  /// without exceptions.
  final _conversationUpdates =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get conversationUpdates =>
      _conversationUpdates.stream;

  PrivateChatCubit(
    this.currentUserId,
    this.receiverId,
    this.listingId,
  ) : super(const PrivateChatState()) {
    _init();
  }

  // ================= INIT =================

  void _init() {
    // Connect WebSocket (no-op if already connected)
    SocketService.connect(currentUserId);

    // Register listeners
    SocketService.on('newMessage', _onReceiveMessage);
    SocketService.on('messageSent', _onMessageSent);
    SocketService.on('typing', _onUserTyping);
    SocketService.on('messagesRead', _onMessagesRead);
    // New: backend pushes `conversationUpdated` whenever a seller
    // action or cron flip changes the SWA conversation's state.
    // We fan it out through the stream so ChatScreen can refetch.
    SocketService.on('conversationUpdated', _onConversationUpdated);

    // Join the listing room + auto-mark as read
    _joinRoom();
  }

  // ================= CONVERSATION UPDATED (SWA state change) =================

  void _onConversationUpdated(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      // Scope filter: only fan out events for THIS (listing, receiver)
      // pair. Prevents a refetch when another conversation on another
      // listing updates while the current ChatScreen is open.
      final eventListingId = map['listing_id']?.toString();
      if (eventListingId != null && eventListingId != listingId) return;
      _conversationUpdates.add(map);
      AppLogger.info('[ws] conversationUpdated: ${map['event_type']}');
    } catch (e) {
      AppLogger.error('conversationUpdated parse error: $e');
    }
  }

  // ================= JOIN ROOM =================

  void _joinRoom() {
    SocketService.send('joinRoom', {
      'listingId': listingId,
      'receiverId': receiverId,
    });

    AppLogger.info('[ws] joinRoom -> listing=$listingId receiver=$receiverId');
  }

  // ================= SEND MESSAGE =================
  //
  // `intent` is the optional P2P pill id (see widgets/P2PPillCatalog.dart)
  // when the message was produced by a quick-reply chip tap. Null on
  // free-typed messages. The receiver uses it to render contextual
  // answer chips. NOT used by SWA paths — those have their own pill
  // semantics on the Conversation doc and a different WS contract
  // (sendPillTap below).

  void sendMessage(String message, {String type = 'text', String? intent}) {
    if (message.trim().isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final tempId = -DateTime.now().microsecondsSinceEpoch;

    // Optimistic local message
    final local = Messages(
      id: tempId.toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      type: type,
      message: message,
      createdAt: now,
      updatedAt: now,
      intent: intent,
    );

    emit(state.copyWith(messages: [...state.messages, local]));

    final payload = <String, dynamic>{
      'listingId': listingId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
    };
    if (intent != null && intent.isNotEmpty) {
      payload['intent'] = intent;
    }
    SocketService.send('sendMessage', payload);

    AppLogger.info('[ws] sendMessage -> $message${intent != null ? ' (intent=$intent)' : ''}');
  }

  // ================= SEND PILL TAP =================
  // SWA-specific: buyer tapped a quick-action pill on the rail. Fires a
  // WebSocket `sendMessage` with `type: 'pill_tap'`. The backend reads
  // the pill ID from the `message` field (see handler/chat/messaging.js
  // handleSWAMessage — `pillId: pillId || message`). We also send
  // `pillId` as a sibling so the backend can migrate to the explicit
  // field without breaking older clients.
  void sendPillTap(String pillId) {
    if (pillId.trim().isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final tempId = -DateTime.now().microsecondsSinceEpoch;

    // Optimistic local message so the tap feels instant. The AI response
    // arrives as a separate WS `newMessage` action handled by
    // _onReceiveMessage below.
    final local = Messages(
      id: tempId.toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      type: 'pill_tap',
      message: pillId,
      pillId: pillId,
      sender: 'buyer',
      createdAt: now,
      updatedAt: now,
    );

    emit(state.copyWith(messages: [...state.messages, local]));

    SocketService.send('sendMessage', {
      'listingId': listingId,
      'receiverId': receiverId,
      'message': pillId,
      'type': 'pill_tap',
      'pillId': pillId,
    });

    AppLogger.info('[ws] pill_tap -> $pillId');
  }

  // ================= P2P OFFER / COUNTER =================
  // P2P-specific: buyer or seller submits a numeric offer/counter via
  // the P2P offer sheet. Sends as a plain `type: 'text'` message so
  // every existing renderer keeps working — the offer amount lives in
  // the message body ("My offer: ₹1,34,850") and the `intent` field
  // marks it as either `make_offer` (buyer) or `counter_offer`
  // (seller). The receiver-side seller card parses the amount from
  // the text using a simple regex. No ChatMessage schema changes.
  //
  // Distinct from [sendOffer] below — that one is SWA-only and fires
  // a structured `type: 'offer'` WebSocket message that the SWA
  // pipeline scores against the seller's floor.
  void sendP2POffer(int amount) {
    if (amount <= 0) return;
    final text = 'My offer: ₹${_formatInr(amount)}';
    sendMessage(text, intent: 'make_offer');
  }

  void sendP2PCounter(int amount) {
    if (amount <= 0) return;
    final text = 'My counter: ₹${_formatInr(amount)}';
    sendMessage(text, intent: 'counter_offer');
  }

  /// Indian-locale grouping. Kept inline to avoid pulling in intl just
  /// for this one helper.
  String _formatInr(int n) {
    final s = n.abs().toString();
    if (s.length <= 3) return n < 0 ? '-$s' : s;
    final last3 = s.substring(s.length - 3);
    final head = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    int cursor = head.length;
    while (cursor > 2) {
      buf.write(',');
      buf.write(head.substring(cursor - 2, cursor));
      cursor -= 2;
    }
    final prefix = head.substring(0, cursor) + buf.toString();
    return (n < 0 ? '-' : '') + prefix + ',' + last3;
  }

  // ================= SEND OFFER =================
  // SWA-specific: buyer submits a numeric offer via the offer sheet.
  // Fires `sendMessage` with `type: 'offer'`. Backend reads the amount
  // from the `message` field (see messaging.js handleSWAMessage —
  // `offerAmount = parseOfferAmount(message, listing.price)`). We also
  // send `offerAmount` as an explicit sibling so the backend can start
  // trusting it directly in a future revision.
  void sendOffer(int amount) {
    if (amount <= 0) return;

    final now = DateTime.now().toIso8601String();
    final tempId = -DateTime.now().microsecondsSinceEpoch;

    // Optimistic local offer bubble so the buyer sees it immediately;
    // the AI's response (accept / counter / decline) arrives as a
    // separate WS `newMessage` handled by _onReceiveMessage below.
    final local = Messages(
      id: tempId.toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      type: 'offer',
      message: amount.toString(),
      offerAmount: amount,
      sender: 'buyer',
      createdAt: now,
      updatedAt: now,
    );

    emit(state.copyWith(messages: [...state.messages, local]));

    SocketService.send('sendMessage', {
      'listingId': listingId,
      'receiverId': receiverId,
      'message': amount.toString(),
      'type': 'offer',
      'offerAmount': amount,
    });

    AppLogger.info('[ws] offer -> $amount');
  }

  // ================= RECEIVE MESSAGE =================

  void _onReceiveMessage(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data);

      // Only handle if same listing
      if (map['listingId']?.toString() != listingId) return;

      // Delegate to Messages.fromJson so every SWA field the backend
      // sends (swaType, decision, counterPrice, acceptPrice, pillId,
      // followUpPills, offerAmount, sender, source) is picked up. fromJson
      // accepts both camelCase (WS payload) and snake_case, so the same
      // model serves REST history and live WebSocket pushes.
      final msg = Messages.fromJson(map);

      // Don't add our own messages (already added optimistically)
      if (msg.senderId == currentUserId) return;

      emit(state.copyWith(messages: [...state.messages, msg]));

      // Conversation-status piggyback: the backend stamps the current
      // SWA status on every newMessage payload (e.g. when seller types
      // and the conversation flips to `seller_takeover`). Fan that out
      // via the conversationUpdates stream so ChatScreen refetches
      // ChatMessagesCubit and the composer can flip from pills-only
      // → text-input. Without this, the buyer would stay stuck on
      // pills if the separate `conversationUpdated` event failed to
      // deliver (e.g. WS push misses, stale connection).
      //
      // 2026-05-15 — skip firing when status is `'active'`. The
      // piggyback only matters for *state changes* (seller_takeover,
      // accepted, declined, expired). For an active conversation
      // there's no UI change to make, so triggering a REST refetch is
      // wasted work — AND on the seller side it caused a duplicate
      // bubble: the buyer's message arrived via WS with a fresh
      // ObjectId, the piggyback forced a REST refetch that pulled the
      // same message under the real DB ObjectId, and ChatScreen's
      // merge-dedup (keyed on m.id) treated them as two distinct
      // messages.
      final convStatus = map['conversation_status']?.toString();
      if (convStatus != null &&
          convStatus.isNotEmpty &&
          convStatus != 'active') {
        _conversationUpdates.add({
          'listing_id': listingId,
          'event_type': 'status_piggyback',
          'conversation_status': convStatus,
        });
      }

      // Self-heal for stale "buyer's app didn't get the SWA reactivate
      // push" state (2026-05-20). When the seller reactivates SWA the
      // backend fires a `conversationUpdated` WS push, but if it doesn't
      // arrive — buyer's app was backgrounded, WebSocket reconnect was
      // in flight, etc — Flutter still thinks the conversation is in
      // `seller_takeover` and renders the free-text composer. Buyer
      // types, backend's pills-only guard fires, and this canned reply
      // comes back: "This seller is responding only via quick replies.
      // Please tap one of the buttons above to continue." Without
      // self-heal the buttons aren't visible (we're still in P2P mode)
      // → dead-end.
      //
      // The reply itself is definitive proof from the server that
      // we're in pills-only mode, so we fire a chat refetch off the
      // back of receiving it. The same `_conversationUpdates` stream
      // that drives the takeover refresh re-uses cleanly here. After
      // refetch the conversation status comes back as `active` and the
      // pill rail re-appears — the buyer sees the buttons their next
      // tap was meant for.
      final pillId = (map['pill_id'] ?? map['pillId'])?.toString();
      final swaType = (map['swaType'] ?? map['swa_type'])?.toString();
      if (pillId == 'pills_only_reminder' ||
          swaType == 'pills_only_reject') {
        _conversationUpdates.add({
          'listing_id': listingId,
          'event_type': 'self_heal_pills_only',
        });
      }

      // Auto-mark as read
      markAsRead();
    } catch (e) {
      AppLogger.error('newMessage error: $e');
    }
  }

  // ================= MESSAGE SENT CONFIRMATION =================

  void _onMessageSent(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data);
      if (map['listingId']?.toString() != listingId) return;

      final serverId = map['id']?.toString();
      final message = map['message']?.toString();
      // Server's view of WHEN the message was stored. Used to overwrite
      // the optimistic message's createdAt so the local sort matches
      // the server's timeline. Without this, a buyer whose phone clock
      // is even a few seconds ahead of the backend would see the AI
      // reply float above their own pill tap / offer — the optimistic
      // message's client-side `DateTime.now()` ends up newer than the
      // server's `new Date()` stamped on the AI response.
      final serverCreatedAt = map['createdAt']?.toString();

      // Replace temp message with server-confirmed one
      final idx = state.messages.indexWhere(
        (m) => m.id?.toString().startsWith('-') == true && m.message == message,
      );

      if (idx != -1 && serverId != null) {
        final updated = [...state.messages];
        updated[idx] = updated[idx].copyWith(
          id: serverId,
          // Keep the original client createdAt as a fallback if the
          // server somehow didn't send one — better stale-than-broken.
          createdAt: (serverCreatedAt != null && serverCreatedAt.isNotEmpty)
              ? serverCreatedAt
              : updated[idx].createdAt,
        );
        emit(state.copyWith(messages: updated));
      }
    } catch (e) {
      AppLogger.error('messageSent error: $e');
    }
  }

  // ================= MARK AS READ =================

  void markAsRead() {
    SocketService.send('markRead', {
      'listingId': listingId,
      'senderId': receiverId,
    });
  }

  void _onMessagesRead(dynamic data) {
    // Read receipt from the other user — could update UI tick marks
    try {
      final map = Map<String, dynamic>.from(data);
      AppLogger.info('[ws] messagesRead: ${map['count']} messages');
    } catch (_) {}
  }

  // ================= TYPING =================

  void startTyping() {
    if (_myTypingThrottle?.isActive == true) return;

    SocketService.send('typing', {
      'receiverId': receiverId,
      'listingId': listingId,
      'isTyping': true,
    });

    _myTypingThrottle = Timer(const Duration(seconds: 2), () {});
  }

  void _onUserTyping(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data);

      final senderId = map['senderId']?.toString();
      if (senderId == currentUserId) return;
      if (map['listingId']?.toString() != listingId) return;

      final isTyping = map['isTyping'] == true;
      emit(state.copyWith(isPeerTyping: isTyping));

      _peerTypingClearTimer?.cancel();
      if (isTyping) {
        _peerTypingClearTimer = Timer(const Duration(seconds: 3), () {
          if (!isClosed) {
            emit(state.copyWith(isPeerTyping: false));
          }
        });
      }
    } catch (_) {}
  }

  // ================= CHAT OPEN / CLOSE =================

  void chatOpened() {
    _joinRoom();
  }

  void chatClosed() {
    // Clear typing indicator for the peer
    SocketService.send('typing', {
      'receiverId': receiverId,
      'listingId': listingId,
      'isTyping': false,
    });
  }

  // ================= CLOSE =================

  @override
  Future<void> close() {
    SocketService.off('newMessage', _onReceiveMessage);
    SocketService.off('messageSent', _onMessageSent);
    SocketService.off('typing', _onUserTyping);
    SocketService.off('messagesRead', _onMessagesRead);
    SocketService.off('conversationUpdated', _onConversationUpdated);

    _peerTypingClearTimer?.cancel();
    _myTypingThrottle?.cancel();
    _conversationUpdates.close();

    return super.close();
  }
}
