import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomSnackBar.dart';
import 'package:classifieds/services/AuthService.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/cubit/Chat/private_chat_cubit.dart';
import '../../data/cubit/ChatUserPin/ChatUserPinCubit.dart';
import '../../data/cubit/ChatUserPin/ChatUserPinStates.dart';
import '../../data/cubit/ChatUsers/ChatUsersCubit.dart';
import '../../data/cubit/ChatUsers/ChatUsersStates.dart';
import '../../services/SocketService.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/media_query_helper.dart';
import '../../widgets/CommonLoader.dart';
import 'ChatScreen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../Components/CustomSnackBar.dart';
import '../../services/AuthService.dart';
import '../../services/SocketService.dart';

import '../../data/cubit/ChatUsers/ChatUsersCubit.dart';
import '../../data/cubit/ChatUsers/ChatUsersStates.dart';
import '../../data/cubit/ChatUserPin/ChatUserPinCubit.dart';
import '../../data/cubit/ChatUserPin/ChatUserPinStates.dart';

import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../widgets/CommonLoader.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with SingleTickerProviderStateMixin {
  String? userId;
  final TextEditingController _search = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Timer? _searchDebounce;
  static const _searchDelay = Duration(milliseconds: 350);

  String _query = '';
  String _lastFiredQuery = '';
  bool? _isGuestUser;

  @override
  void initState() {
    super.initState();
    _init();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  Future<void> _init() async {
    final isGuest = await AuthService.isGuest;
    setState(() => _isGuestUser = isGuest);

    final id = await AuthService.getId();
    userId = id;

    if (!isGuest && id != null) {
      SocketService.connect(id);
      context.read<ChatUsersCubit>().initSocket(id);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_isGuestUser ?? true) return;

    setState(() => _query = value);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDelay, () {
      final q = _query.trim();
      if (q == _lastFiredQuery) return;
      _lastFiredQuery = q;

      // context.read<ChatUsersCubit>().fetchChatUsers(q);
    });
  }

  void _clearSearch() {
    if (_isGuestUser ?? true) return;

    _searchDebounce?.cancel();
    _search.clear();

    setState(() => _query = '');
    _lastFiredQuery = '';

    // context.read<ChatUsersCubit>().fetchChatUsers('');
  }

  @override
  Widget build(BuildContext context) {
    final bg = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final card = ThemeHelper.cardColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Messages",
          style: AppTextStyles.headlineMedium(
            textColor,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: (_isGuestUser == null)
          ? const Center(child: DottedProgressWithLogo())
          : (_isGuestUser == true)
          ? _buildGuestUI(textColor)
          : Column(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSearchBar(textColor),
                ),
                Expanded(
                  child: BlocBuilder<ChatUsersCubit, ChatUsersStates>(
                    builder: (context, state) {
                      if (state is ChatUsersLoading) {
                        return _buildShimmer(card);
                      }

                      if (state is ChatUsersFailure) {
                        return _buildError(state.error, textColor);
                      }

                      if (state is ChatUsersLoaded) {
                        final users = state.chatUsersModel.data ?? [];

                        if (users.isEmpty) {
                          return _buildEmpty(textColor);
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            if (userId != null) {
                              SocketService.emit("get_chat_list", {
                                "userId": userId,
                              });
                            }
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final id = user.userId ?? 0;
                              final isPinned = user.pinned == true;

                              return BlocListener<
                                ChatUserPinCubit,
                                ChatUserPinStates
                              >(
                                listener: (context, pinState) {
                                  if (pinState is ChatUserPinLoaded) {
                                    SocketService.emit("get_chat_list", {
                                      "userId": userId,
                                    });
                                  } else if (pinState is ChatUserPinFailure) {
                                    CustomSnackBar1.show(
                                      context,
                                      pinState.error,
                                    );
                                  }
                                },
                                child: Slidable(
                                  key: ValueKey(id),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.30,
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) {
                                          context
                                              .read<ChatUserPinCubit>()
                                              .chatUserPin({
                                                "pinned_user_id": id,
                                              });
                                        },
                                        backgroundColor: isPinned
                                            ? Colors.orangeAccent
                                            : Colors.teal,
                                        foregroundColor: Colors.white,
                                        icon: isPinned
                                            ? Icons.push_pin_outlined
                                            : Icons.push_pin,
                                        label: isPinned ? "Unpin" : "Pin",
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ],
                                  ),
                                  child: _ChatCard(
                                    id: id,
                                    listingId: user.listingId ?? 0,
                                    listingTitle: user.listingTitle ?? "",
                                    name: user.name ?? "",
                                    imageUrl: user.profileImage ?? "",
                                    pinned: isPinned,
                                    card: isPinned
                                        ? Colors.teal.withOpacity(0.1)
                                        : card,
                                    textColor: textColor,
                                    animationDelay: index * 100,
                                    onTap: () {
                                      context.push(
                                        '/chat'
                                        '?receiverId=$id'
                                        '&listingId=${user.listingId ?? 0}'
                                        '&listingTitle=${Uri.encodeComponent(user.listingTitle ?? "")}',
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGuestUI(Color textColor) {
    return Center(
      child: Text(
        "Login to view your messages",
        style: AppTextStyles.headlineSmall(textColor),
      ),
    );
  }

  Widget _buildSearchBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _search,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Search by name...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildEmpty(Color textColor) {
    return Center(
      child: Text("No Users Found!", style: AppTextStyles.bodyLarge(textColor)),
    );
  }

  Widget _buildError(String error, Color textColor) {
    return Center(
      child: Text(error, style: AppTextStyles.bodyLarge(textColor)),
    );
  }

  Widget _buildShimmer(Color card) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: card.withOpacity(0.5),
        highlightColor: card.withOpacity(0.8),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.name,
    required this.imageUrl,
    required this.onTap,
    required this.card,
    required this.textColor,
    required this.animationDelay,
    required this.pinned,
  });

  final int id;
  final String name;
  final int listingId;
  final String listingTitle;
  final String imageUrl; // ← new
  final VoidCallback onTap;
  final Color card;
  final Color textColor;
  final int animationDelay;
  final bool pinned;

  bool get _hasImage =>
      imageUrl.trim().isNotEmpty &&
      Uri.tryParse(imageUrl)?.hasAbsolutePath == true;

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    final a = parts[0].characters.first.toUpperCase();
    final b = parts[1].characters.first.toUpperCase();
    return '$a$b';
  }

  Widget _initialsAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: AppTextStyles.titleLarge(
          Colors.white,
        ).copyWith(fontWeight: FontWeight.bold, fontSize: 22),
      ),
    );
  }

  Widget _avatar({double size = 48}) {
    if (_hasImage) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(size),
          // (optional) tiny placeholder while loading
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _initialsAvatar(size);
          },
        ),
      );
    }
    return _initialsAvatar(size);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 300 + animationDelay),
      child: Material(
        color: card,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _avatar(size: 48), // ← image or initials
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium(
                                textColor,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (pinned) Icon(Icons.push_pin, color: textColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // You can add last message preview/time here later
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
