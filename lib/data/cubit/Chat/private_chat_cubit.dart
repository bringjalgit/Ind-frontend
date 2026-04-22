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

    // Join the listing room + auto-mark as read
    _joinRoom();
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

  // ================= RECEIVE MESSAGE =================

  void _onReceiveMessage(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data);

      // Only handle if same listing
      if (map['listingId']?.toString() != listingId) return;

      final msg = Messages(
        id: map['id']?.toString(),
        senderId: map['senderId']?.toString(),
        receiverId: map['receiverId']?.toString(),
        type: map['type'],
        message: map['message'],
        imageUrl: map['imageUrl'],
        createdAt: map['createdAt']?.toString(),
        updatedAt: map['createdAt']?.toString(),
        isSystemMessage: map['isSystemMessage'] == true,
        swaType: map['swaType']?.toString(),
        decision: map['decision']?.toString(),
        counterPrice: int.tryParse(map['counterPrice']?.toString() ?? ''),
        acceptPrice: int.tryParse(map['acceptPrice']?.toString() ?? ''),
      );

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

    _peerTypingClearTimer?.cancel();
    _myTypingThrottle?.cancel();

    return super.close();
  }
}
