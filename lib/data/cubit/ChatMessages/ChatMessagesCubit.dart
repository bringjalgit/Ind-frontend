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
    // Only show the shimmer placeholder on the very first fetch when we
    // have no data to render. On subsequent re-fetches (e.g. WS-triggered
    // refresh after seller_takeover), keep the existing Loaded state on
    // screen so the message list doesn't blank-out for the duration of
    // the network round-trip — the user sees a seamless update once the
    // new Loaded state lands.
    final hasPriorData = chatMessagesModel.data?.messages != null;
    if (!hasPriorData) {
      emit(ChatMessagesLoading());
    }
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

        // Preserve all SWA bleed-through fields from the network response
        // (conversationId, conversationStatus, chatModeSnapshot,
        // pendingAcceptanceExpiresAt, currentOffer, counterOffer,
        // agreedPrice). Constructing Data() with only friend + messages
        // — as the old code did — silently dropped the entire SWA state
        // block the backend had already populated.
        chatMessagesModel = ChatMessagesModel(
          success: res.success,
          message: res.message,
          data: Data(
            friend: res.data?.friend,
            listing: res.data?.listing,
            messages: newestFirst,
            conversationId: res.data?.conversationId,
            conversationStatus: res.data?.conversationStatus,
            chatModeSnapshot: res.data?.chatModeSnapshot,
            pendingAcceptanceExpiresAt:
                res.data?.pendingAcceptanceExpiresAt,
            currentOffer: res.data?.currentOffer,
            counterOffer: res.data?.counterOffer,
            agreedPrice: res.data?.agreedPrice,
            expiryReason: res.data?.expiryReason,
            completedAt: res.data?.completedAt,
            initialPills: res.data?.initialPills,
            viewerIsSeller: res.data?.viewerIsSeller ?? false,
            swaCategoryEligible: res.data?.swaCategoryEligible ?? true,
          ),
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

        // On "load older", the conversation-level SWA state is more
        // reliable on the NEW (later) page's response — status and offer
        // prices could have changed since the first fetch. Prefer the
        // fresh values; fall back to the existing ones if the new page
        // response omits them (older backend revisions did).
        chatMessagesModel = ChatMessagesModel(
          success: newData.success,
          message: newData.message,
          data: Data(
            friend: chatMessagesModel.data?.friend ?? newData.data?.friend,
            listing: chatMessagesModel.data?.listing ?? newData.data?.listing,
            messages: deduped,
            conversationId: newData.data?.conversationId ??
                chatMessagesModel.data?.conversationId,
            conversationStatus: newData.data?.conversationStatus ??
                chatMessagesModel.data?.conversationStatus,
            chatModeSnapshot: newData.data?.chatModeSnapshot ??
                chatMessagesModel.data?.chatModeSnapshot,
            pendingAcceptanceExpiresAt:
                newData.data?.pendingAcceptanceExpiresAt ??
                    chatMessagesModel.data?.pendingAcceptanceExpiresAt,
            currentOffer: newData.data?.currentOffer ??
                chatMessagesModel.data?.currentOffer,
            counterOffer: newData.data?.counterOffer ??
                chatMessagesModel.data?.counterOffer,
            agreedPrice: newData.data?.agreedPrice ??
                chatMessagesModel.data?.agreedPrice,
            expiryReason: newData.data?.expiryReason ??
                chatMessagesModel.data?.expiryReason,
            completedAt: newData.data?.completedAt ??
                chatMessagesModel.data?.completedAt,
            initialPills: newData.data?.initialPills ??
                chatMessagesModel.data?.initialPills,
            viewerIsSeller: newData.data?.viewerIsSeller ??
                chatMessagesModel.data?.viewerIsSeller ??
                false,
            swaCategoryEligible: newData.data?.swaCategoryEligible ??
                chatMessagesModel.data?.swaCategoryEligible ??
                true,
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
