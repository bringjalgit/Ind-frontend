import '../../../model/ChatUsersModel.dart';

abstract class ChatUsersStates {}

class ChatUsersInitially extends ChatUsersStates {}

class ChatUsersLoading extends ChatUsersStates {}

class ChatUsersLoaded extends ChatUsersStates {
  final ChatUsersModel chatUsersModel;

  ChatUsersLoaded(this.chatUsersModel);
}

class ChatUsersFailure extends ChatUsersStates {
  final String error;

  ChatUsersFailure(this.error);
}
