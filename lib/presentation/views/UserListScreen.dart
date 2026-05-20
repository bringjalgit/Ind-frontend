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

  String _query = '';
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
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_isGuestUser ?? true) return;

    setState(() {
      _query = value;
    });
  }

  void _clearSearch() {
    if (_isGuestUser ?? true) return;

    _search.clear();

    setState(() {
      _query = '';
    });
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
          ? _buildShimmer(card)
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
                        final filteredUsers = _query.trim().isEmpty
                            ? users
                            : users.where((user) {
                                final name = (user.name ?? '').toLowerCase();
                                return name.contains(_query.toLowerCase());
                              }).toList();

                        if (filteredUsers.isEmpty) {
                          return _buildEmpty(textColor);
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<ChatUsersCubit>().loadChatUsers();
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final id = user.userId ?? '';
                              final isPinned = user.pinned == true;

                              return BlocListener<
                                ChatUserPinCubit,
                                ChatUserPinStates
                              >(
                                listener: (context, pinState) {
                                  if (pinState is ChatUserPinLoaded) {
                                    context.read<ChatUsersCubit>().loadChatUsers();
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
                                                "listing_id": user.listingId,
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
                                    listingId: user.listingId ?? '',
                                    listingTitle: user.listingTitle ?? "",
                                    name: user.name ?? "",
                                    imageUrl: user.profileImage ?? "",
                                    pinned: isPinned,
                                    unreadCount: user.unreadCount ?? 0,
                                    listingSold: user.listingSold,
                                    card: isPinned
                                        ? Colors.teal.withOpacity(0.1)
                                        : card,
                                    textColor: textColor,
                                    animationDelay: index * 100,
                                    onTap: () {
                                      // Guard: the backend sometimes
                                      // returns chat list entries with
                                      // missing user_id or listing_id
                                      // (orphaned chats). Don't navigate
                                      // with empty params — show an error
                                      // and stay on the list instead of
                                      // opening a broken chat room.
                                      final listingIdStr = user.listingId ?? '';
                                      if (id.isEmpty || listingIdStr.isEmpty) {
                                        CustomSnackBar1.show(
                                          context,
                                          'This chat is unavailable. Please refresh the list.',
                                        );
                                        return;
                                      }
                                      // Pre-populate the chat header with
                                      // the name and image we already have
                                      // from the list card so the user sees
                                      // the correct identity immediately,
                                      // even if the messages fetch fails or
                                      // is slow. No more "IND User" stuck
                                      // header on network blips.
                                      final nameParam = Uri.encodeComponent(
                                        user.name ?? '',
                                      );
                                      final imageParam = Uri.encodeComponent(
                                        user.profileImage ?? '',
                                      );
                                      context.push(
                                        '/chat'
                                        '?receiverId=$id'
                                        '&listingId=$listingIdStr'
                                        '&listingTitle=${Uri.encodeComponent(user.listingTitle ?? "")}'
                                        '&receiverName=$nameParam'
                                        '&receiverImage=$imageParam',
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
        style: AppTextStyles.bodyMedium(textColor),
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
    final isDark = card.computeLuminance() < 0.5;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                /// Avatar Circle (48)
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                /// Text Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Name
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// Listing title
                      Container(
                        height: 12,
                        width: MediaQuery.of(context).size.width * 0.5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    this.unreadCount = 0,
    this.listingSold = false,
  });

  final dynamic id;
  final String name;
  final dynamic listingId;
  final String listingTitle;
  final String imageUrl; // ← new
  final VoidCallback onTap;
  final Color card;
  final Color textColor;
  final int animationDelay;
  final bool pinned;
  final int unreadCount;
  // When true the row is rendered at 0.55 opacity + slight desaturation,
  // so seller and buyer see at a glance that this chat is on a sold
  // listing. Tap stays enabled — the user can still open the chat to
  // read the negotiation history; we just signal that no further deal
  // is possible.
  final bool listingSold;

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
    Widget cardBody = Material(
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
                        const SizedBox(width: 4),
                        if (listingSold) ...[
                          // Compact "Sold" pill — stays sharp on top of
                          // the dimmed body so the cause of the visual
                          // muting is unambiguous. Crimson tone shared
                          // with the Sold Out badge on the listing card.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFDC2626).withOpacity(0.35),
                              ),
                            ),
                            child: const Text(
                              'Sold',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (pinned) Icon(Icons.push_pin, color: textColor),
                      ],
                    ),
                    Text(
                      listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall(
                        textColor,
                      ).copyWith(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 4),
                    // You can add last message preview/time here later
                  ],
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Sold listings get a muted treatment so the seller / buyer can
    // tell at a glance the chat is on a closed deal. Tap stays enabled
    // (the user can still open the chat to read history) — we just
    // visually demote it relative to active chats.
    if (listingSold) {
      cardBody = Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          // Light desaturation — keeps colours recognisable while
          // pulling the row visually behind active rows. The 5x4
          // matrix below is the standard "30% grayscale" mix.
          colorFilter: const ColorFilter.matrix(<double>[
            0.65, 0.27, 0.08, 0, 0,
            0.21, 0.79, 0.00, 0, 0,
            0.21, 0.27, 0.52, 0, 0,
            0,    0,    0,    1, 0,
          ]),
          child: cardBody,
        ),
      );
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 300 + animationDelay),
      child: cardBody,
    );
  }
}
