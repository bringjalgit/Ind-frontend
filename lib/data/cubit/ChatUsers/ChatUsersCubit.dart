import 'package:bloc/bloc.dart';
import '../../../model/ChatUsersModel.dart';
import '../../../services/SocketService.dart';
import 'ChatUsersStates.dart';

class ChatUsersCubit extends Cubit<ChatUsersStates> {
  ChatUsersCubit() : super(ChatUsersInitially());

  List<Data> _chatUsers = [];

  void initSocket(String userId) {
    emit(ChatUsersLoading());

    // 1️⃣ Connect socket
    SocketService.connect(userId);

    // 2️⃣ Listen for chat list update
    SocketService.on("chat_list_update", (payload) {
      try {
        if (payload == null) return;

        if (payload is List) {
          _chatUsers =
              payload.map((e) => Data.fromJson(e)).toList();
        } else if (payload is Map<String, dynamic>) {
          _chatUsers = [Data.fromJson(payload)];
        }

        emit(ChatUsersLoaded(
          ChatUsersModel(
            success: true,
            data: _chatUsers,
          ),
        ));
      } catch (e) {
        emit(ChatUsersFailure(e.toString()));
      }
    });

    // 3️⃣ Emit request to get chat list
    SocketService.emit("get_chat_list", {
      "userId": userId,
    });
  }

  /// If single chat updates (like new message)
  void updateSingleChat(Map<String, dynamic> payload) {
    final updated = Data.fromJson(payload);

    final index = _chatUsers.indexWhere(
          (e) => e.userId == updated.userId &&
          e.listingId == updated.listingId,
    );

    if (index != -1) {
      _chatUsers[index] = updated;
    } else {
      _chatUsers.insert(0, updated);
    }

    emit(ChatUsersLoaded(
      ChatUsersModel(
        success: true,
        data: _chatUsers,
      ),
    ));
  }

  @override
  Future<void> close() {
    SocketService.off("chat_list_update");
    return super.close();
  }
}

