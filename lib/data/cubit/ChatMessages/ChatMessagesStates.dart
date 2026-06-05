import 'package:equatable/equatable.dart';
import '../../../model/ChatMessagesModel.dart';

abstract class ChatMessagesStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatMessagesInitial extends ChatMessagesStates {}

class ChatMessagesLoading extends ChatMessagesStates {}

class ChatMessagesLoaded extends ChatMessagesStates {
  final ChatMessagesModel chatMessages;
  final bool hasNextPage;

  ChatMessagesLoaded(this.chatMessages, this.hasNextPage);

  @override
  List<Object?> get props => [chatMessages, hasNextPage];
}

class ChatMessagesLoadingMore extends ChatMessagesStates {
  final ChatMessagesModel chatMessages;
  final bool hasNextPage;

  ChatMessagesLoadingMore(this.chatMessages, this.hasNextPage);

  @override
  List<Object?> get props => [chatMessages, hasNextPage];
}

class ChatMessagesFailure extends ChatMessagesStates {
  final String error;

  ChatMessagesFailure(this.error);

  @override
  List<Object?> get props => [error];
}

