import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/utils/AppLogger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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

  late final IO.Socket _socket;
  late final String _room;

  Timer? _peerTypingClearTimer;
  Timer? _myTypingThrottle;

  PrivateChatCubit(
      this.currentUserId,
      this.receiverId,
      this.listingId,
      ) : super(const PrivateChatState()) {
    _socket = SocketService.connect(currentUserId);
    _room = _getPrivateRoomName(currentUserId, receiverId);
    _init();
  }

  // ================= INIT =================

  void _init() {
    _socket.off('receive_private_message', _onReceiveMessage);
    _socket.off('user_typing', _onUserTyping);
    _socket.off('connect');

    _socket.on('receive_private_message', _onReceiveMessage);
    _socket.on('user_typing', _onUserTyping);

    _socket.onConnect((_) {
      _joinRoom();
    });

    if (_socket.connected) {
      _joinRoom();
    }
  }

  // ================= JOIN PRIVATE =================

  void _joinRoom() {
    final payload = {
      "listingId": listingId,
      "userId1": currentUserId,
      "userId2": receiverId,
    };

    _socket.emit("join_private", payload);

    // Notify server chat opened
    _socket.emit("chat_opened", {
      "listingId": listingId,
    });

    // Mark messages as read
    _socket.emit("mark_as_read", {
      "listingId": listingId,
      "otherUserId": receiverId,
    });

    AppLogger.info("[socket] join_private -> $payload");
  }

  // ================= SEND MESSAGE =================

  void sendMessage(String message, {String type = "text"}) {
    if (message.trim().isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final tempId = -DateTime.now().microsecondsSinceEpoch;

    final local = Messages(
      id: tempId,
      senderId: int.tryParse(currentUserId),
      receiverId: int.tryParse(receiverId),
      type: type,
      message: message,
      createdAt: now,
      updatedAt: now,
    );

    emit(state.copyWith(messages: [...state.messages, local]));

    final payload = {
      "listingId": listingId,
      "senderId": currentUserId,
      "receiverId": receiverId,
      "message": message,
      "type": type,
    };

    _socket.emit("send_private_message", payload);

    AppLogger.info("[socket] send_private_message -> $payload");
  }

  // ================= RECEIVE MESSAGE =================

  void _onReceiveMessage(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data);

      // Only handle if same listing
      if (map['listingId'].toString() != listingId) return;

      final msg = Messages(
        id: _safeInt(map['id']),
        senderId: _safeInt(map['senderId']),
        receiverId: _safeInt(map['receiverId']),
        type: map['type'],
        message: map['message'],
        createdAt: map['created_at'],
        updatedAt: map['created_at'],
      );

      _replaceTempWithServer(msg);

      // Auto mark as read if message from peer
      if (msg.senderId.toString() == receiverId) {
        _socket.emit("mark_as_read", {
          "listingId": listingId,
          "otherUserId": receiverId,
        });
      }
    } catch (e) {
      AppLogger.info("receive_private_message error: $e");
    }
  }

  // ================= MARK AS READ =================

  void markAsRead() {
    _socket.emit("mark_as_read", {
      "listingId": listingId,
      "otherUserId": receiverId,
    });
  }

  // ================= CHAT OPEN / CLOSE =================

  void chatOpened() {
    _socket.emit("chat_opened", {
      "listingId": listingId,
    });
  }

  void chatClosed() {
    _socket.emit("chat_closed", {
      "listingId": listingId,
    });
  }

  // ================= TYPING =================

  void startTyping() {
    if (_myTypingThrottle?.isActive == true) return;

    _socket.emit("typing", {
      "room": _room,
      "senderId": currentUserId,
      "receiverId": receiverId,
    });

    _myTypingThrottle =
        Timer(const Duration(seconds: 2), () {});
  }

  void _onUserTyping(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data);

      final senderId = map['senderId']?.toString();
      final room = map['room']?.toString();

      if (room != _room) return;
      if (senderId == currentUserId) return;

      emit(state.copyWith(isPeerTyping: true));

      _peerTypingClearTimer?.cancel();
      _peerTypingClearTimer =
          Timer(const Duration(seconds: 3), () {
            if (!isClosed) {
              emit(state.copyWith(isPeerTyping: false));
            }
          });
    } catch (_) {}
  }

  // ================= HELPERS =================

  String _getPrivateRoomName(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return ids.join('_');
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  void _replaceTempWithServer(Messages serverMsg) {
    final idx = state.messages.indexWhere(
          (m) => (m.id ?? 0) < 0 &&
          m.message == serverMsg.message &&
          m.senderId == serverMsg.senderId,
    );

    if (idx != -1) {
      final updated = [...state.messages];
      updated[idx] = serverMsg;
      emit(state.copyWith(messages: updated));
    } else {
      emit(state.copyWith(
          messages: [...state.messages, serverMsg]));
    }
  }

  // ================= CLOSE =================

  @override
  Future<void> close() {
    chatClosed(); // 🔥 important

    _socket.off('receive_private_message', _onReceiveMessage);
    _socket.off('user_typing', _onUserTyping);

    return super.close();
  }
}

