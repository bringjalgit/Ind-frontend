import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../model/ChatUsersModel.dart';
import '../../../services/SocketService.dart';
import '../../remote_data_source.dart';
import 'ChatUsersStates.dart';

class ChatUsersCubit extends Cubit<ChatUsersStates> {
  final RemoteDataSource remoteDataSource;
  ChatUsersCubit({required this.remoteDataSource}) : super(ChatUsersInitially());

  List<Data> _chatUsers = [];
  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;
  bool _initialized = false;
  Timer? _debounceTimer;

  bool get hasNextPage => _hasNextPage;

  // Debounced reload to avoid flooding REST API on rapid WebSocket events
  void _debouncedReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () => loadChatUsers());
  }

  // Store listener references so we can remove only our own callbacks
  late final Function(dynamic) _onUnreadCount = (_) => _debouncedReload();
  late final Function(dynamic) _onNewMessage = (_) => _debouncedReload();

  /// Initialize: connect WebSocket + load chat list via REST.
  /// Idempotent — safe to call from both Dashboard.getData() (so the chat-tab
  /// badge updates from any screen) and UserListScreen.initState() (legacy
  /// entry point). Subsequent calls only refresh the chat list.
  Future<void> initSocket(String userId) async {
    if (_initialized) {
      // Already wired up — just refresh the list (e.g. user re-entered chat tab)
      await loadChatUsers();
      return;
    }
    _initialized = true;
    emit(ChatUsersLoading());

    // Connect WebSocket for real-time updates
    await SocketService.connect(userId);

    // Listen for unread count updates from WebSocket
    SocketService.on('unreadCount', _onUnreadCount);

    // Listen for new messages to refresh chat list
    SocketService.on('newMessage', _onNewMessage);

    // Load chat list via REST API
    await loadChatUsers();
  }

  /// Load chat users list from REST API (page 1 resets)
  Future<void> loadChatUsers({String query = ''}) async {
    try {
      _currentPage = 1;
      final response = await remoteDataSource.getChatUsers(query, page: 1);
      if (response != null && response.success == true && response.data != null) {
        _chatUsers = response.data!;
        _hasNextPage = response.nextPage == true;
        emit(ChatUsersLoaded(ChatUsersModel(success: true, data: _chatUsers)));
      } else {
        _chatUsers = [];
        _hasNextPage = false;
        emit(ChatUsersLoaded(ChatUsersModel(success: true, data: [])));
      }
    } catch (e) {
      emit(ChatUsersFailure(e.toString()));
    }
  }

  /// Load next page of chat users (append to existing list)
  Future<void> loadMoreChatUsers({String query = ''}) async {
    if (_isLoadingMore || !_hasNextPage) return;
    _isLoadingMore = true;
    try {
      final nextPage = _currentPage + 1;
      final response = await remoteDataSource.getChatUsers(query, page: nextPage);
      if (response != null && response.success == true && response.data != null) {
        _currentPage = nextPage;
        _chatUsers.addAll(response.data!);
        _hasNextPage = response.nextPage == true;
        emit(ChatUsersLoaded(ChatUsersModel(success: true, data: _chatUsers)));
      }
    } catch (e) {
      // silently fail — existing data still valid
    } finally {
      _isLoadingMore = false;
    }
  }

  /// If single chat updates (like new message)
  void updateSingleChat(Map<String, dynamic> payload) {
    final updated = Data.fromJson(payload);

    final index = _chatUsers.indexWhere(
      (e) => e.userId == updated.userId && e.listingId == updated.listingId,
    );

    if (index != -1) {
      _chatUsers[index] = updated;
    } else {
      _chatUsers.insert(0, updated);
    }

    emit(ChatUsersLoaded(ChatUsersModel(success: true, data: _chatUsers)));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    SocketService.off('unreadCount', _onUnreadCount);
    SocketService.off('newMessage', _onNewMessage);
    return super.close();
  }
}
