import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/ChatUserPin/ChatUserPinStates.dart';
import 'package:classifieds/data/cubit/ChatUsers/ChatUsersRepo.dart';

class ChatUserPinCubit extends Cubit<ChatUserPinStates> {
  ChatUsersRepo chatUsersRepo;
  ChatUserPinCubit(this.chatUsersRepo) : super(ChatUserPinInitially());

  Future<void> chatUserPin(Map<String, dynamic> data) async {
    emit(ChatUserPinLoading());
    try {
      final response = await chatUsersRepo.chatUserPin(data);
      if (response != null && response.success == true) {
        emit(ChatUserPinLoaded(response));
      } else {
        emit(ChatUserPinFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(ChatUserPinFailure(e.toString()));
    }
  }
}
