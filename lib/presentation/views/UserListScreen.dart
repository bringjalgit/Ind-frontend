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
  String _lastFiredQuery = '';
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

    final userId = await AuthService.getId();
    SocketService.connect(userId ?? "");
    // only fetch if NOT guest
    if (!isGuest) {
      context.read<ChatUsersCubit>().fetchChatUsers("");
      getUserId();
    }
  }

  Future<void> getUserId() async {
    userId = await AuthService.getId();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    _search.clear();
    _searchDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    if (_isGuestUser ?? true) return; // block in guest mode
    setState(() => _query = v);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDelay, () {
      if (!mounted) return;
      final q = _query.trim();
      if (q == _lastFiredQuery) return;
      _lastFiredQuery = q;
      context.read<ChatUsersCubit>().fetchChatUsers(q);
    });
  }

  void _clearSearch() {
    if (_isGuestUser ?? true) return; // block in guest mode
    _searchDebounce?.cancel();
    setState(() => _query = '');
    _lastFiredQuery = '';
    context.read<ChatUsersCubit>().fetchChatUsers('');
  }

  @override
  Widget build(BuildContext context) {
    final bg = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final card = ThemeHelper.cardColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Messages',
          style: AppTextStyles.headlineMedium(
            textColor,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: (_isGuestUser == null)
          ? Center(child: DottedProgressWithLogo()) // determining guest status
          : (_isGuestUser == true)
          // ---------- Guest placeholder (no API calls, no search) ----------
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/nodata/no_data.png',
                    width: SizeConfig.screenWidth * 0.4,
                    height: SizeConfig.screenHeight * 0.12,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login to view your messages',
                    style: AppTextStyles.headlineSmall(textColor),
                  ),
                ],
              ),
            )
          // -------------------- Logged-in UI --------------------
          : Column(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        style: AppTextStyles.bodyMedium(textColor),
                        decoration: InputDecoration(
                          hintText: 'Search by name…',
                          hintStyle: AppTextStyles.bodyMedium(
                            textColor.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: textColor.withOpacity(0.8),
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ChatUsersCubit, ChatUsersStates>(
                    builder: (context, state) {
                      if (state is ChatUsersLoading) {
                        return _buildShimmerList(card, textColor);
                      } else if (state is ChatUsersFailure) {
                        return _buildErrorState(
                          context,
                          state.error,
                          textColor,
                        );
                      } else if (state is ChatUsersLoaded) {
                        final users = state.chatUsersModel.data ?? [];
                        final filtered = _query.trim().isEmpty
                            ? users
                            : users
                                  .where(
                                    (u) => (u.name ?? '')
                                        .toLowerCase()
                                        .contains(_query.toLowerCase()),
                                  )
                                  .toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/nodata/no_data.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  height:
                                      MediaQuery.of(context).size.height * 0.15,
                                ),
                                Text(
                                  'No Users Found!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: ThemeHelper.textColor(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async =>
                              context.read<ChatUsersCubit>().fetchChatUsers(""),
                          color: textColor,
                          backgroundColor: card,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final user = filtered[i];
                              final id = user.userId ?? 0;
                              final name = user.name ?? '';
                              final imageUrl = user.profileImage ?? '';
                              final isPinned =
                                  user.pinned ==
                                  true; // assuming backend returns this flag

                              return BlocListener<
                                ChatUserPinCubit,
                                ChatUserPinStates
                              >(
                                listener: (context, state) {
                                  if (state is ChatUserPinLoaded) {
                                    context
                                        .read<ChatUsersCubit>()
                                        .fetchChatUsers("");
                                  } else if (state is ChatUserPinFailure) {
                                    CustomSnackBar1.show(context, state.error);
                                  }
                                },
                                child: Slidable(
                                  key: ValueKey(id),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.3,
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) {
                                          final pinData = {
                                            "pinned_user_id": id,
                                          };
                                          context
                                              .read<ChatUserPinCubit>()
                                              .chatUserPin(pinData);
                                        },
                                        backgroundColor: isPinned
                                            ? Colors.orangeAccent
                                            : Colors.teal,
                                        foregroundColor: Colors.white,
                                        icon: isPinned
                                            ? Icons.push_pin_outlined
                                            : Icons.push_pin,
                                        label: isPinned ? 'Unpin' : 'Pin',
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ],
                                  ),
                                  child: _ChatCard(
                                    id: id,
                                    name: name,
                                    imageUrl: imageUrl,
                                    onTap: () {
                                      context.push('/chat?receiverId=$id');
                                    },
                                    card: isPinned
                                        ? Colors.teal.withOpacity(0.1)
                                        : card,
                                    textColor: textColor,
                                    animationDelay: i * 100,
                                    pinned: isPinned,
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

  // Shimmer effect for loading state
  Widget _buildShimmerList(Color card, Color textColor) {
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

  // Error state with retry button
  Widget _buildErrorState(BuildContext context, String error, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error,
            style: AppTextStyles.bodyLarge(textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<ChatUsersCubit>().fetchChatUsers(""),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Retry', style: AppTextStyles.bodyMedium(Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.id,
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

                // Name (and future: last message/time/unread)
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
