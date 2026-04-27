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

  void sendMessage(String message, {String type = 'text'}) {
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
    );

    emit(state.copyWith(messages: [...state.messages, local]));

    SocketService.send('sendMessage', {
      'listingId': listingId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
    });

    AppLogger.info('[ws] sendMessage -> $message');
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

      // Replace temp message with server-confirmed one
      final idx = state.messages.indexWhere(
        (m) => m.id?.toString().startsWith('-') == true && m.message == message,
      );

      if (idx != -1 && serverId != null) {
        final updated = [...state.messages];
        updated[idx] = updated[idx].copyWith(id: serverId);
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
