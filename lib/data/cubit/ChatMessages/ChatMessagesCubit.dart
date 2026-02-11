import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:classifieds/presentation/views/ChatScreen.dart';
import '../../../model/ChatMessagesModel.dart';
import 'ChatMessagesRepository.dart';
import 'ChatMessagesStates.dart';

class ChatMessagesCubit extends Cubit<ChatMessagesStates> {
  final ChatMessagesRepository chatMessagesRepository;

  ChatMessagesCubit(this.chatMessagesRepository) : super(ChatMessagesInitial());

  ChatMessagesModel chatMessagesModel = ChatMessagesModel();
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  // Fetch initial chat messages (make newest-first for reverse:true lists)
  Future<void> fetchMessages(String userId, String listingId) async {
    emit(ChatMessagesLoading());
    _currentPage = 1;
    try {
      final res = await chatMessagesRepository.getChatMessages(
        userId,
        listingId,
        _currentPage,
      );
      if (res != null && res.success == true) {
        final pageAsc = res.data?.messages ?? const <Messages>[];
        final newestFirst = List<Messages>.from(
          pageAsc.reversed,
        ); // ← flip page

        chatMessagesModel = ChatMessagesModel(
          success: res.success,
          message: res.message,
          data: Data(friend: res.data?.friend, messages: newestFirst),
          settings: res.settings,
        );

        _hasNextPage = res.settings?.nextPage ?? false;
        emit(ChatMessagesLoaded(chatMessagesModel, _hasNextPage));
      } else {
        emit(
          ChatMessagesFailure(res?.message ?? "Failed to load chat messages"),
        );
      }
    } catch (e) {
      emit(ChatMessagesFailure(e.toString()));
    }
  }

  // Load older messages: APPEND (at end) because list is newest-first
  Future<void> getMoreMessages(String userId, String listingId) async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    _currentPage++;
    emit(ChatMessagesLoadingMore(chatMessagesModel, _hasNextPage));

    try {
      final newData = await chatMessagesRepository.getChatMessages(
        userId,
        listingId,
        _currentPage,
      );
      final pageAsc = newData?.data?.messages ?? const <Messages>[];

      if (newData != null && pageAsc.isNotEmpty) {
        final existing = List<Messages>.from(
          chatMessagesModel.data?.messages ?? const <Messages>[],
        );
        final olderDesc = List<Messages>.from(pageAsc.reversed); // ← flip page
        existing.addAll(olderDesc); // ← append to end (top visually)

        // simple de-dupe by (id or timestamp)
        final seen = <String>{};
        final deduped = <Messages>[];
        for (final m in existing) {
          final key =
              '${m.id ?? 'null'}-${m.createdAtDate.millisecondsSinceEpoch}';
          if (seen.add(key)) deduped.add(m);
        }

        chatMessagesModel = ChatMessagesModel(
          success: newData.success,
          message: newData.message,
          data: Data(
            friend: chatMessagesModel.data?.friend ?? newData.data?.friend,
            messages: deduped,
          ),
          settings: newData.settings,
        );

        _hasNextPage = newData.settings?.nextPage ?? false;
        emit(ChatMessagesLoaded(chatMessagesModel, _hasNextPage));
      } else {
        _hasNextPage = false;
        emit(ChatMessagesLoaded(chatMessagesModel, _hasNextPage));
      }
    } catch (e) {
      emit(ChatMessagesFailure(e.toString()));
    } finally {
      _isLoadingMore = false;
    }
  }
}
