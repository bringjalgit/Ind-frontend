import 'dart:async';

import 'package:classifieds/Components/debugPrint.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:classifieds/data/cubit/ChatMessages/ChatMessagesCubit.dart';
import '../../Components/CustomSnackBar.dart';
import '../../data/cubit/Chat/private_chat_cubit.dart';
import '../../data/cubit/ChatMessages/ChatMessagesStates.dart';
import '../../model/ChatMessagesModel.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/AppLauncher.dart';
import '../../widgets/SafeDealDialog.dart';
import 'ReportBottomSheet.dart';
import 'swa/SwaPillRail.dart';
import 'swa/SwaOfferSheet.dart';
import 'swa/pill_catalog.dart';

extension ChatScreenMessagesX on Messages {
  DateTime get createdAtDate {
    final raw = createdAt?.toString() ?? '';
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  String get formattedTime {
    return DateFormat('hh:mm a').format(createdAtDate);
  }

  bool get isImage => (type ?? '') == 'image';
  bool get isText => (type ?? '') == 'text';
}

class _ListItem {
  final Messages? message;
  final DateTime? day;
  final bool isHeader;
  const _ListItem.message(this.message) : day = null, isHeader = false;
  const _ListItem.header(this.day) : message = null, isHeader = true;
}

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String listingId;
  final String listingTitle;
  // Optional pre-populated name/image from the chat list card. Used to
  // initialize the AppBar ValueNotifiers so the header shows the correct
  // user identity IMMEDIATELY on screen open, even before the messages
  // fetch resolves (and even if it fails). If null/empty, falls back to
  // the listing title as a neutral placeholder — never "IND User".
  final String? initialReceiverName;
  final String? initialReceiverImage;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.listingId,
    required this.listingTitle,
    this.initialReceiverName,
    this.initialReceiverImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

enum _MenuAction { report, safetyTips }

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  // Tracks an in-flight SWA pill tap. The pill rail dims + ignores taps
  // while this is true, preventing double-submission when the buyer
  // double-taps before the AI response arrives.
  bool _isPillSending = false;

  bool _showSafetyBanner = true; // always true when screen opens
  bool _animSafetyBannerIn = false;

  Timer? _safetyAutoHide; // <-- auto-hide timer

  // ScrollablePositionedList controls
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  // Sticky header state
  bool _showStickyHeader = true;
  String _stickyDateLabel = '';
  List<_ListItem> _lastItems = const [];

  final ValueNotifier<String?> mobileNotifier = ValueNotifier<String?>(null);
  // Initialized in initState from widget.initialReceiverName/Image so the
  // AppBar shows the correct name immediately on first frame (before the
  // messages fetch resolves). No more "IND User" placeholder that lingers
  // forever when a network blip makes fetchMessages emit Failure.
  late final ValueNotifier<String?> receiverName;
  late final ValueNotifier<String?> receiverImage;

  // "show while scrolling" state
  Timer? _scrollIdleTimer;
  bool _isScrolling = false;

  // Subscription to PrivateChatCubit.conversationUpdates. Fires on every
  // backend-pushed SWA state change (deal confirmed, cancelled, seller
  // counter, takeover, etc.); triggers a ChatMessagesCubit refetch so
  // the banner + offer state update live. Cancelled in dispose().
  StreamSubscription<Map<String, dynamic>>? _conversationUpdateSub;

  void _onScrollActivity() {
    if (!_isScrolling) setState(() => _isScrolling = true);
    _scrollIdleTimer?.cancel();
    _scrollIdleTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isScrolling = false);
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize the receiver name / image from the params the caller
    // passed in. The chat list card already has this info, so we use it
    // here as the "source of truth" until the messages fetch resolves.
    // Fall back to the listing title as a neutral placeholder if the
    // caller didn't pass a name — never "IND User".
    final initialName =
        (widget.initialReceiverName != null && widget.initialReceiverName!.trim().isNotEmpty)
            ? widget.initialReceiverName!.trim()
            : (widget.listingTitle.isNotEmpty ? widget.listingTitle : "");
    receiverName = ValueNotifier<String?>(initialName);
    receiverImage = ValueNotifier<String?>(widget.initialReceiverImage);

    // 🔥 Notify cubit that chat opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<PrivateChatCubit>().chatOpened();
        context.read<PrivateChatCubit>().markAsRead();
      } catch (_) {}
    });

    try {
      context.read<ChatMessagesCubit>().fetchMessages(widget.receiverId,widget.listingId);
    } catch (_) {}

    // Subscribe to SWA conversation-update events pushed over the
    // WebSocket. Fired by seller actions (confirm / cancel / override /
    // implicit takeover) and by crons (auto-promote, counter expiry,
    // listing unavailable, deal expired).
    //
    // Each event triggers a fresh getChatMessages fetch so the status
    // banner, offer prices, pending-acceptance countdown and messages
    // timeline all refresh together. Cheap — REST fetch is ~200ms.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _conversationUpdateSub = context
            .read<PrivateChatCubit>()
            .conversationUpdates
            .listen((update) {
          if (!mounted) return;
          try {
            context
                .read<ChatMessagesCubit>()
                .fetchMessages(widget.receiverId, widget.listingId);
          } catch (_) {}
        });
      } catch (_) {}
    });

    _positionsListener.itemPositions.addListener(() {
      final positions = _positionsListener.itemPositions.value;
      if (positions.isEmpty || _lastItems.isEmpty) return;

      // First visible item (lowest index)
      final first = positions
          .where((p) => p.itemTrailingEdge > 0) // visible
          .reduce((a, b) => a.index < b.index ? a : b);

      String _labelForIndex(int idx) {
        if (idx < 0 || idx >= _lastItems.length) return '';
        final it = _lastItems[idx];
        if (it.isHeader) return _dateLabel(it.day!);
        final d = it.message!.createdAtDate;
        return _dateLabel(d);
      }

      final newLabel = _labelForIndex(first.index);

      // hide sticky if the inline header with same label is already at/near top
      bool topHasSameInlineHeader = false;
      for (final p in positions) {
        final idx = p.index;
        if (idx < 0 || idx >= _lastItems.length) continue;
        final it = _lastItems[idx];
        if (it.isHeader) {
          final lbl = _dateLabel(it.day!);
          if (lbl == newLabel && p.itemLeadingEdge <= 0.18) {
            topHasSameInlineHeader = true;
            break;
          }
        }
      }

      final nextShowSticky = !topHasSameInlineHeader;
      if (nextShowSticky != _showStickyHeader || newLabel != _stickyDateLabel) {
        setState(() {
          _showStickyHeader = nextShowSticky;
          _stickyDateLabel = newLabel;
        });
      }

      // Load more when scrolled near the top (older side) with reverse:true
      final nearTop = positions.any((p) => p.index >= _lastItems.length - 3);
      if (nearTop && !_isLoadingMore && _hasMoreMessages) {
        setState(() => _isLoadingMore = true);
        context.read<ChatMessagesCubit>().getMoreMessages(widget.receiverId,widget.listingId);
      }

      // Important: do NOT call _onScrollActivity() here,
      // we only want the sticky to appear on *user* scroll via NotificationListener.
    });

    // Animate in after first frame
    // Show + animate in, then start 1-min auto-hide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const SafeDealBottomSheet(),
      );
      if (!mounted) return;
      setState(() => _animSafetyBannerIn = true);
      _startSafetyAutoHide();
    });
  }

  void _startSafetyAutoHide() {
    _safetyAutoHide?.cancel();
    _safetyAutoHide = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_showSafetyBanner) _dismissSafetyBanner();
    });
  }

  void _dismissSafetyBanner() {
    setState(() => _animSafetyBannerIn = false);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _showSafetyBanner = false);
    });
  }

  @override
  void dispose() {
    _scrollIdleTimer?.cancel();
    _controller.dispose();
    _conversationUpdateSub?.cancel();

    try {
      context.read<PrivateChatCubit>().chatClosed();
    } catch (_) {}

    super.dispose();
  }


  void _scrollToBottom() {
    if (_lastItems.isEmpty) return;
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: 0, // index 0 is newest (bottom) when reverse:true
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0, // stick to bottom
      );
    }
  }

  Color _meBubble(BuildContext context) {
    final dark = ThemeHelper.isDarkMode(context);
    return dark ? const Color(0xFF234476) : Colors.blue[100]!;
  }

  Color _otherBubble(BuildContext context) {
    final dark = ThemeHelper.isDarkMode(context);
    return dark ? const Color(0xFF2A2A2A) : Colors.grey[200]!;
  }

  Color _inputFill(BuildContext context) {
    final dark = ThemeHelper.isDarkMode(context);
    return dark ? const Color(0xFF222222) : Colors.grey[100]!;
  }

  Color _hintColor(BuildContext context) =>
      ThemeHelper.textColor(context).withOpacity(.6);

  bool get _hasReceiverImage =>
      (receiverImage.value ?? "").trim().isNotEmpty &&
      Uri.tryParse(receiverImage.value ?? "")?.hasAbsolutePath == true;

  String _initials1(String? name) {
    if (name == null || name.trim().isEmpty) {
      return "";
    }

    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    final first = parts[0].characters.first.toUpperCase();
    final second = parts[1].characters.first.toUpperCase();
    return '$first$second';
  }

  Widget _fallbackAvatar(double size, String initials) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade300,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext newContext) {
        final bg = ThemeHelper.backgroundColor(newContext);
        final textColor = ThemeHelper.textColor(newContext);
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child:
                          (_hasReceiverImage &&
                              receiverImage.value != null &&
                              receiverImage.value!.isNotEmpty)
                          ? Image.network(
                              receiverImage.value!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                final initials = _initials1(
                                  capitalize(receiverName.value ?? ""),
                                );
                                return _fallbackAvatar(36, initials);
                              },
                            )
                          : _fallbackAvatar(
                              36,
                              _initials1(capitalize(receiverName.value ?? "")),
                            ),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            capitalize(receiverName.value ?? ""),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLarge(
                              textColor,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            capitalize(widget.listingTitle ?? ""),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall(
                              textColor,
                            ).copyWith(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                BlocBuilder<PrivateChatCubit, PrivateChatState>(
                  buildWhen: (p, c) => p.isPeerTyping != c.isPeerTyping,
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: state.isPeerTyping
                          ? _buildTypingIndicator(context)
                          : const SizedBox(height: 16),
                    );
                  },
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: mobileNotifier,
                builder: (context, value, child) {
                  return IconButton(
                    icon: const Icon(Icons.call),
                    color: textColor,
                    onPressed: () async {
                      final mobile = mobileNotifier.value;
                      if (mobile != null && mobile.isNotEmpty) {
                        AppLauncher.call(mobile);
                      } else {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        await Future.delayed(const Duration(seconds: 2));

                        if (context.mounted) Navigator.of(context).pop();

                        final updatedMobile = mobileNotifier.value;
                        if (updatedMobile != null && updatedMobile.isNotEmpty) {
                          AppLauncher.call(updatedMobile);
                        } else {
                          CustomSnackBar1.show(
                            context,
                            "Mobile number not available",
                          );
                        }
                      }
                    },
                  );
                },
              ),
              PopupMenuButton<_MenuAction>(
                icon: Icon(
                  Icons.more_vert,
                  color: ThemeHelper.textColor(context), // theme-aware
                  size: 28,
                ),
                onSelected: (value) {
                  switch (value) {
                    case _MenuAction.report:
                      openReportSheetForChat(
                        context,
                        userId: widget.receiverId,
                      );
                      break;
                    case _MenuAction.safetyTips:
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const SafeDealBottomSheet(),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_MenuAction>(
                    value: _MenuAction.report,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.error, // error color from theme
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Report user',
                          style: AppTextStyles.bodyMedium(
                            ThemeHelper.textColor(context),
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<_MenuAction>(
                    value: _MenuAction.safetyTips,
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary, // primary color
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Safety tips',
                          style: AppTextStyles.bodyMedium(
                            ThemeHelper.textColor(context),
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                color: ThemeHelper.cardColor(
                  context,
                ), // card color based on theme
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                tooltip: 'More options',
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ],
            iconTheme: IconThemeData(color: textColor),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                // SWA status banner. Backend surfaces
                // `data.conversation_status` on every getChatMessages
                // response (null when the thread is pure P2P). Banner
                // informs the user which mode the thread is in — AI
                // active, seller has taken over, deal accepted, etc.
                // Renders nothing when status is null or 'active'
                // (the default happy path shouldn't shout about itself).
                BlocBuilder<ChatMessagesCubit, ChatMessagesStates>(
                  buildWhen: (p, c) => c is ChatMessagesLoaded || c is ChatMessagesLoadingMore,
                  builder: (context, state) {
                    Data? data;
                    if (state is ChatMessagesLoaded) {
                      data = state.chatMessages.data;
                    } else if (state is ChatMessagesLoadingMore) {
                      data = state.chatMessages.data;
                    }
                    return _SwaStatusBanner(
                      status: data?.conversationStatus,
                      expiresAt: data?.pendingAcceptanceExpiresAtDate,
                      agreedPrice: data?.agreedPrice,
                    );
                  },
                ),
                Expanded(
                  child: MultiBlocListener(
                    listeners: [
                      BlocListener<PrivateChatCubit, PrivateChatState>(
                        listenWhen: (p, c) =>
                            p.messages.length != c.messages.length ||
                            p.isPeerTyping != c.isPeerTyping,
                        listener: (ctx, state) => _scrollToBottom(),
                      ),
                      BlocListener<ChatMessagesCubit, ChatMessagesStates>(
                        listener: (ctx, state) {
                          if (state is ChatMessagesLoaded) {
                            _hasMoreMessages = state.hasNextPage;
                            setState(() {
                              _isLoadingMore = false;
                            });
                            // Scroll to latest message after initial load
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom();
                            });
                          } else if (state is ChatMessagesLoadingMore) {
                            _hasMoreMessages = state.hasNextPage;
                          } else if (state is ChatMessagesFailure) {
                            setState(() {
                              _isLoadingMore = false;
                            });
                            // Surface the failure as a snackbar so the user
                            // knows something went wrong instead of staring
                            // at a silent frozen screen. The inline error
                            // branch in the BlocBuilder below gives them a
                            // Retry button as well.
                            if (mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    state.error.isNotEmpty
                                        ? 'Couldn\'t load messages: ${state.error}'
                                        : 'Couldn\'t load messages. Please retry.',
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                    child: BlocBuilder<ChatMessagesCubit, ChatMessagesStates>(
                      builder: (context, historyState) {
                        // Show shimmer skeleton while loading (initial + loading states)
                        if (historyState is ChatMessagesLoading || historyState is ChatMessagesInitial) {
                          return _buildChatShimmer(context);
                        }

                        // Failure branch — render a proper inline error with
                        // a Retry button. Without this, a network blip leaves
                        // the screen frozen with no feedback (the original
                        // "IND User" stuck-header bug).
                        if (historyState is ChatMessagesFailure) {
                          final textColor = ThemeHelper.textColor(context);
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    size: 56,
                                    color: textColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Couldn't load messages",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.titleMedium(textColor),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    historyState.error.isNotEmpty
                                        ? historyState.error
                                        : 'Check your connection and try again.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySmall(
                                      textColor.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context
                                          .read<ChatMessagesCubit>()
                                          .fetchMessages(
                                            widget.receiverId,
                                            widget.listingId,
                                          );
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final history = <Messages>[];

                        if (historyState is ChatMessagesLoaded) {
                          history.addAll(
                            historyState.chatMessages.data?.messages ??
                                const [],
                          );
                          mobileNotifier.value =
                              historyState.chatMessages.data?.friend?.mobile ??
                              "";
                          // Only overwrite the receiver name if the server
                          // actually returned one. If the backend response
                          // is missing the friend field (edge case for
                          // orphaned chats), the URL-supplied initial name
                          // stays intact instead of being clobbered to "".
                          final serverName =
                              historyState.chatMessages.data?.friend?.name;
                          if (serverName != null && serverName.trim().isNotEmpty) {
                            receiverName.value = serverName;
                          }
                          final serverImage =
                              historyState.chatMessages.data?.friend?.image;
                          if (serverImage != null && serverImage.isNotEmpty) {
                            receiverImage.value = serverImage;
                          }
                        } else if (historyState is ChatMessagesLoadingMore) {
                          history.addAll(
                            historyState.chatMessages.data?.messages ??
                                const [],
                          );
                        }

                        return BlocBuilder<PrivateChatCubit, PrivateChatState>(
                          builder: (context, liveState) {
                            // Merge + dedupe
                            final all = <Messages>[];
                            final seen = <String>{};

                            void addMsg(Messages m) {
                              final key =
                                  (m.id?.toString() ?? m.createdAt.toString());
                              if (seen.add(key)) all.add(m);
                            }

                            for (final m in history) addMsg(m);
                            for (final m in liveState.messages) addMsg(m);

                            // NEWEST → OLDEST (DESC) for reverse:true
                            all.sort(
                              (a, b) =>
                                  b.createdAtDate.compareTo(a.createdAtDate),
                            );

                            // Build flat items and cache for sticky logic
                            final items = _buildItems(all);
                            _lastItems = items;

                            final overlayVisible =
                                _isScrolling &&
                                _showStickyHeader &&
                                _stickyDateLabel.isNotEmpty;

                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                // Add top padding so inline chips don't sit under the floating chip.
                                Padding(
                                  padding: const EdgeInsets.only(top: 44),
                                  child: NotificationListener<ScrollNotification>(
                                    onNotification: (n) {
                                      if (n is ScrollStartNotification ||
                                          n is ScrollUpdateNotification ||
                                          n is OverscrollNotification) {
                                        _onScrollActivity(); // sets _isScrolling=true, hides after 300ms idle
                                      }
                                      return false;
                                    },
                                    child: ScrollablePositionedList.builder(
                                      itemScrollController:
                                          _itemScrollController,
                                      itemPositionsListener: _positionsListener,
                                      reverse: true,
                                      itemCount:
                                          items.length +
                                          (_hasMoreMessages && _isLoadingMore
                                              ? 1
                                              : 0),
                                      itemBuilder: (context, index) {
                                        // Loader at "top" (end) with reverse:true
                                        if (_hasMoreMessages &&
                                            _isLoadingMore &&
                                            index == items.length) {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }

                                        final it = items[index];
                                        if (it.isHeader) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: _dateChip(
                                              _dateLabel(it.day!),
                                              ThemeHelper.textColor(context),
                                            ),
                                          );
                                        } else {
                                          final msg = it.message!;
                                          final isMe =
                                              (msg.senderId?.toString() ??
                                                  '') ==
                                              widget.currentUserId;
                                          return _buildMessageBubble(
                                            context,
                                            msg,
                                            isMe,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                // Sticky date chip — visible ONLY while scrolling
                                if (overlayVisible)
                                  Positioned(
                                    top: 6,
                                    child: _dateChip(
                                      _stickyDateLabel,
                                      ThemeHelper.textColor(context),
                                    ),
                                  ),

                                if (_showSafetyBanner)
                                  Positioned(
                                    top: 10, // just under AppBar
                                    left: 12,
                                    right: 12,
                                    child: AnimatedSlide(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOut,
                                      offset: _animSafetyBannerIn
                                          ? Offset.zero
                                          : const Offset(0, -0.15),
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        opacity: _animSafetyBannerIn ? 1 : 0,
                                        child: _SafetyBanner(
                                          textColor: ThemeHelper.textColor(
                                            context,
                                          ),
                                          onClose: _dismissSafetyBanner,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                // SWA pill rail — sits above the composer. Returns
                // SizedBox.shrink() on pure-P2P threads and on SWA
                // threads where the seller picked p2p mode, the
                // conversation is terminal / accepted / seller_takeover,
                // or there are no follow-up pills to show.
                _buildPillRail(context),
                // Mode-aware composer. Regular text input on P2P threads
                // and on SWA threads in ai_chat / p2p / seller_takeover
                // modes. Hidden (replaced by a "tap a quick reply" hint)
                // when the seller picked pills_only so buyers can't
                // type free text the AI would reject server-side.
                _buildComposerArea(context),
              ],
            ),
          ),
        );
      },
    );
  }

  void openReportSheetForChat(BuildContext context, {required dynamic userId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return Material(
            color: ThemeHelper.backgroundColor(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SingleChildScrollView(
              controller: scrollController,
              child: ReportBottomSheet.chat(userId: userId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    return Semantics(
      liveRegion: true, // a11y: announce updates
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'Typing…',
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime day) {
    final now = DateTime.now();
    final d0 = DateTime(day.year, day.month, day.day);
    final n0 = DateTime(now.year, now.month, now.day);
    final diff = n0.difference(d0).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(day);
  }

  /// Build flat list with headers that appear ABOVE their day (works with reverse:true)
  Widget _buildChatShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 8,
        itemBuilder: (context, index) {
          final isMe = index % 3 != 0; // alternate sender/receiver
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: isMe ? 120 : 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (!isMe) ...[
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<_ListItem> _buildItems(List<Messages> allDesc) {
    // allDesc is NEWEST → OLDEST
    final items = <_ListItem>[];
    final buffer = <Messages>[];
    DateTime? bucketDay;

    void flush() {
      if (buffer.isEmpty || bucketDay == null) return;
      for (final m in buffer) items.add(_ListItem.message(m));
      // header after its messages so it appears above with reverse:true
      items.add(_ListItem.header(bucketDay));
      buffer.clear();
      bucketDay = null;
    }

    for (final m in allDesc) {
      if ((m.type ?? 'text') == 'typing')
        continue; // skip ephemeral typing here
      final d = m.createdAtDate.toLocal();
      final key = DateTime(d.year, d.month, d.day);
      if (bucketDay == null || bucketDay == key) {
        bucketDay = key;
        buffer.add(m);
      } else {
        flush();
        bucketDay = key;
        buffer.add(m);
      }
    }
    flush();
    return items;
  }

  Widget _dateChip(String label, Color textColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: AppTextStyles.labelMedium(textColor)),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Messages msg, bool isMe) {
    // ── SWA system / AI side ─────────────────────────────────────────
    // Any message not from the current user that originates on the
    // system/AI track. Detected via either the WS-set isSystemMessage
    // flag (live pushes) or the REST-parsed `sender` field (history
    // fetch). keyword_bot is treated as system-side because it's the
    // pill-driven AI persona. The SWA bubble handles pill_response,
    // counter_offer, agreement, decline, offer_disabled — all of which
    // need distinctive chrome vs a plain seller message.
    final isSystemSide = msg.isSystemMessage ||
        msg.sender == 'system' ||
        msg.sender == 'keyword_bot';
    if (isSystemSide) {
      return _buildSwaBubble(context, msg);
    }

    // ── Buyer-side SWA actions ───────────────────────────────────────
    // The buyer's own pill tap and offer messages get richer chrome
    // than plain text — the raw pill ID ("is_available") is replaced
    // by its human label, and offers show the ₹ amount prominently.
    // Only applies to messages FROM the current user on SWA threads.
    if (isMe && msg.type == 'pill_tap' && msg.pillId != null) {
      return _buildBuyerPillBubble(context, msg);
    }
    if (isMe && msg.type == 'offer' && msg.offerAmount != null) {
      return _buildBuyerOfferBubble(context, msg);
    }

    final bubbleColor = isMe ? _meBubble(context) : _otherBubble(context);
    final bodyText = AppTextStyles.bodyMedium(ThemeHelper.textColor(context));
    final timeText = AppTextStyles.labelSmall(
      ThemeHelper.textColor(context).withOpacity(.6),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if ((msg.type ?? 'text') == 'text')
                Text(
                  (msg.message ?? ''),
                  style: bodyText.copyWith(fontSize: 16),
                ),
              if ((msg.type ?? '') == 'image' &&
                  (msg.imageUrl ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    msg.imageUrl!,
                    height: 220,
                    width: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 4),
              Text(msg.formattedTime, style: timeText),
            ],
          ),
        ),
      ),
    );
  }

  // ── SWA bubble — AI / system-side responses shown to the buyer ─────
  // Handles both wire shapes:
  //   • WS live push: `swaType` + `decision` fields populated.
  //   • REST history: neither set; classify by `pill_id` instead.
  // Classification drives palette (green=agreement, yellow=counter,
  // red=decline, blue=generic AI reply) plus the presence of the big-₹
  // amount header on counter / agreement.
  Widget _buildSwaBubble(BuildContext context, Messages msg) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final timeText = AppTextStyles.labelSmall(textColor.withOpacity(.6));
    final swaType = msg.swaType ?? '';
    final pillId = msg.pillId ?? '';

    // Discriminator: WS route (swaType/decision) wins when present;
    // otherwise fall back to REST route (pill_id).
    bool isAgreement = swaType == 'offer_accepted' || pillId == 'agreement';
    bool isCounter = (swaType == 'offer_response' && msg.decision == 'AUTO_COUNTER') ||
        pillId == 'counter_offer';
    bool isDecline = (swaType == 'offer_response' &&
            (msg.decision == 'AUTO_DECLINE' || msg.decision == 'ROUND_CAP_EXHAUSTED')) ||
        pillId == 'below_floor_decline' ||
        pillId == 'offer_disabled';

    Color bubbleColor;
    Color? borderColor;
    Color contentColor = textColor;
    Widget? leadingIcon;
    String? label; // short header label — "Deal!", "Seller counters", etc.
    int? amountToShow;

    if (isAgreement) {
      // Deal reached — green, celebratory
      bubbleColor = isDark ? const Color(0xFF1A3A2A) : const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF22C55E);
      contentColor = const Color(0xFF14532D);
      label = '✓ Deal!';
      amountToShow = msg.acceptPrice ?? msg.offerAmount;
    } else if (isCounter) {
      // Seller / AI counter-offer — yellow
      bubbleColor = isDark ? const Color(0xFF3D3418) : const Color(0xFFFEF9C3);
      borderColor = const Color(0xFFFFD600);
      label = 'Seller counters';
      amountToShow = msg.counterPrice ?? msg.offerAmount;
    } else if (isDecline) {
      // Decline — red tint
      bubbleColor = isDark ? const Color(0xFF3A1F1F) : const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFEF4444);
      contentColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
    } else {
      // Generic AI reply (pill_response, keyword_bot) — blue tint + lightning
      bubbleColor = isDark ? const Color(0xFF1E2A3E) : const Color(0xFFEBF4FF);
      leadingIcon = Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Icon(
          Icons.flash_on_rounded,
          size: 14,
          color: isDark ? const Color(0xFF4D9FFF) : const Color(0xFF1677FF),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
            border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Short header label + prominent ₹ amount on agreement /
              // counter bubbles. Omitted for generic replies + declines
              // where the body text already carries the full message.
              if (label != null) ...[
                Text(
                  label,
                  style: AppTextStyles.labelSmall(contentColor).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                if (amountToShow != null && amountToShow > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${_formatInr(amountToShow)}',
                    style: AppTextStyles.bodyMedium(contentColor).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leadingIcon != null) leadingIcon,
                  Expanded(
                    child: Text(
                      msg.message ?? '',
                      style: AppTextStyles.bodyMedium(contentColor).copyWith(
                        fontSize: 15,
                        fontWeight: isAgreement ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(msg.formattedTime, style: timeText),
            ],
          ),
        ),
      ),
    );
  }

  // ── Buyer-side pill bubble ─────────────────────────────────────────
  // Replaces the raw pillId ("is_available") with the pill's human label
  // and icon from the catalog. Right-aligned buyer-colored bubble, same
  // shape as regular text bubbles so it feels like "I said X" rather
  // than a system event.
  Widget _buildBuyerPillBubble(BuildContext context, Messages msg) {
    final spec = PillCatalog.specFor(msg.pillId ?? '');
    // Unknown pill → fall through to raw text rendering so nothing is
    // invisible even if the catalog is out of date.
    if (spec == null) return _buildDefaultBubble(context, msg, isMe: true);

    final bubbleColor = _meBubble(context);
    final textColor = ThemeHelper.textColor(context);
    final timeText = AppTextStyles.labelSmall(textColor.withOpacity(.6));

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(spec.icon, size: 16, color: textColor.withOpacity(.85)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      spec.label,
                      style: AppTextStyles.bodyMedium(textColor).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(msg.formattedTime, style: timeText),
            ],
          ),
        ),
      ),
    );
  }

  // ── Buyer-side offer bubble ────────────────────────────────────────
  // Used when the buyer submits an offer via the offer sheet (Step 10).
  // Right-aligned bubble with a prominent ₹ amount + "You offered" caption.
  Widget _buildBuyerOfferBubble(BuildContext context, Messages msg) {
    final bubbleColor = _meBubble(context);
    final textColor = ThemeHelper.textColor(context);
    final timeText = AppTextStyles.labelSmall(textColor.withOpacity(.6));

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You offered',
                style: AppTextStyles.labelSmall(textColor.withOpacity(.7))
                    .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${_formatInr(msg.offerAmount ?? 0)}',
                style: AppTextStyles.bodyMedium(textColor).copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(msg.formattedTime, style: timeText),
            ],
          ),
        ),
      ),
    );
  }

  // Fallback to a plain text/image bubble when an SWA-branched bubble
  // encounters unexpected input (e.g. unknown pill id). Avoids blank
  // rendering — the catch-all keeps content visible.
  Widget _buildDefaultBubble(BuildContext context, Messages msg,
      {required bool isMe}) {
    final bubbleColor = isMe ? _meBubble(context) : _otherBubble(context);
    final bodyText = AppTextStyles.bodyMedium(ThemeHelper.textColor(context));
    final timeText = AppTextStyles.labelSmall(
      ThemeHelper.textColor(context).withOpacity(.6),
    );
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(msg.message ?? '', style: bodyText.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text(msg.formattedTime, style: timeText),
            ],
          ),
        ),
      ),
    );
  }

  /// Format an integer as Indian-locale grouped currency (e.g. 52000 →
  /// "52,000"). Kept inline — adding intl NumberFormat just for this
  /// was overkill.
  String _formatInr(int n) {
    final s = n.abs().toString();
    if (s.length <= 3) return n < 0 ? '-$s' : s;
    // Indian grouping: last 3 digits, then pairs of 2.
    final last3 = s.substring(s.length - 3);
    final head = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    int cursor = head.length;
    while (cursor > 2) {
      buf.write(',');
      buf.write(head.substring(cursor - 2, cursor));
      cursor -= 2;
    }
    final prefix = head.substring(0, cursor) + buf.toString();
    return (n < 0 ? '-' : '') + prefix + ',' + last3;
  }

  // ── Composer dispatcher ───────────────────────────────────────────────
  // Looks at the conversation's SWA mode and chooses between the real
  // text input and a "pills-only" hint strip. Pure-P2P threads (where
  // chatModeSnapshot is null) always see the text input — unchanged
  // behaviour.
  Widget _buildComposerArea(BuildContext context) {
    return BlocBuilder<ChatMessagesCubit, ChatMessagesStates>(
      builder: (context, historyState) {
        Data? convData;
        if (historyState is ChatMessagesLoaded) {
          convData = historyState.chatMessages.data;
        } else if (historyState is ChatMessagesLoadingMore) {
          convData = historyState.chatMessages.data;
        }

        // Only intercept when the seller explicitly chose pills_only on
        // an SWA thread. All other cases (P2P, ai_chat, p2p mode,
        // seller_takeover, pending/accepted states on SWA) keep the
        // regular text input so the buyer can coordinate pickup, reply
        // to a seller override, etc.
        if (convData != null && convData.isSwa && convData.isPillsOnly) {
          return _buildPillsOnlyHint(context);
        }
        return _buildInputArea(context);
      },
    );
  }

  /// Replaces the text composer on pills_only SWA threads. A thin strip
  /// with an icon + muted label, safe-area aware, theme-matched. Keeps
  /// the bottom of the screen from feeling broken/empty when the text
  /// input is intentionally absent.
  Widget _buildPillsOnlyHint(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = ThemeHelper.backgroundColor(context);
    final hintColor = isDark
        ? Colors.white.withOpacity(0.55)
        : Colors.black.withOpacity(0.55);
    final iconColor = isDark
        ? const Color(0xFF7DE3F0)
        : const Color(0xFF0E7C8D);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: bg,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Tap a quick reply above to continue',
                style: AppTextStyles.bodySmall(hintColor),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final fill = _inputFill(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        color: ThemeHelper.backgroundColor(context),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: AppTextStyles.bodyMedium(textColor),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: AppTextStyles.bodyMedium(_hintColor(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: fill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendText(context),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: textColor),
              onPressed: () => _sendText(context),
            ),
          ],
        ),
      ),
    );
  }

  void _sendText(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      context.read<PrivateChatCubit>().sendMessage(text);
      _controller.clear();
    } catch (e) {
      debugPrint('Error accessing PrivateChatCubit in _sendText: $e');
    }
  }

  // ── SWA pill rail ──────────────────────────────────────────────────────
  // Renders above the composer on Sell-with-AI threads. Watches both
  // cubits:
  //   • ChatMessagesCubit — provides the REST-loaded history and the
  //     conversation-level SWA state (`data.isSwa`, `data.chatModeSnapshot`).
  //   • PrivateChatCubit — provides live WS-delivered messages with their
  //     own `follow_up_pills`, which should supersede history when newer.
  //
  // The rail only mounts when the thread is SWA (conversation_id present)
  // AND the seller's mode allows pills (pills_only or ai_chat). It stays
  // hidden on pure-P2P threads and on p2p mode ("Direct Messages"), so
  // the existing ChatScreen experience is unchanged there.
  Widget _buildPillRail(BuildContext context) {
    return BlocBuilder<ChatMessagesCubit, ChatMessagesStates>(
      builder: (context, historyState) {
        // Only compute once we have a loaded history response.
        Data? convData;
        if (historyState is ChatMessagesLoaded) {
          convData = historyState.chatMessages.data;
        } else if (historyState is ChatMessagesLoadingMore) {
          convData = historyState.chatMessages.data;
        }

        // Pure-P2P thread → rail stays hidden. No SWA chrome at all.
        if (convData == null || !convData.isSwa) {
          return const SizedBox.shrink();
        }

        // Status gates — hide the rail only when further interaction
        // doesn't make sense:
        //   • terminal (expired/completed/declined) — conversation is over
        //   • accepted — deal is locked, only pickup coordination via text
        //
        // Pills REMAIN visible in Quick Replies, Smart Chat, Direct
        // Chat, Seller Takeover, and Pending Acceptance. The pill's
        // behaviour per mode is decided in [_onPillTap]:
        //   • AI modes (pills_only, keyword_chat) → pill_tap WS (AI
        //     answers)
        //   • Human modes (p2p, seller_takeover) → plain text WS
        //     (seller reads)
        if (convData.isTerminal) return const SizedBox.shrink();
        if (convData.isAccepted) return const SizedBox.shrink();

        final isHumanMode =
            convData.isP2PMode || convData.isSellerTakeover;

        // Persistent rail: always render the same opener set for the
        // lifetime of the conversation. Previously we tracked the most
        // recent AI `follow_up_pills` which removed already-tapped
        // pills — but that denied buyers the ability to re-tap
        // "Make an offer" for a second try, or re-ask about pickup
        // after reading condition. A static rail matches OLX-style
        // quick-replies and is far more usable.
        //
        // PrivateChatCubit state is no longer needed here — the rail
        // doesn't change per message. Kept as BlocBuilder so the
        // `_isPillSending` lock still re-renders the dimmed chips.
        return BlocBuilder<PrivateChatCubit, PrivateChatState>(
          builder: (context, liveState) {
            var pills = convData!.initialPills;
            if (pills != null) {
              if (isHumanMode) {
                // Human modes: text composer is the escape hatch, so
                // `something_else` is redundant. Everything else
                // (info + action + conversational) shows.
                pills =
                    pills.where((id) => id != 'something_else').toList();
              } else if (convData.isPillsOnly) {
                // Quick Replies mode (pills_only): the seller opted
                // out of human interaction entirely, and the
                // pills_only_reject backend guard rejects free text.
                // Conversational pills (hello, okay, etc.) would hit
                // that guard and show a rejection bubble — filter
                // them out so the rail only shows pills with AI
                // intents that will actually produce a response.
                pills = pills.where((id) {
                  final spec = PillCatalog.specFor(id);
                  return spec?.hasAiIntent == true;
                }).toList();
              }
              // Smart Chat: show everything. Conversational pills send
              // as text which the keyword engine can soft-handle.

              // ── Contextual closure pills ─────────────────────────
              // When the AI has counter-offered, the buyer needs a way
              // to accept it (deal), lock in their own offer (final),
              // or walk away (reject). The backend persists these in
              // each counter response's follow_up_pills, but the rail
              // is built from a static opener set so we re-inject them
              // here based on conversation state. Visible in every mode
              // (pills_only, smart_chat, human) since the closure
              // semantics apply uniformly.
              if (convData.counterOffer != null && convData.counterOffer! > 0) {
                final closurePills = ['deal', 'final', 'reject'];
                // De-dupe in case any of these ever land in the opener.
                final seen = pills.toSet();
                for (final p in closurePills) {
                  if (!seen.contains(p)) pills.add(p);
                }
              }
            }
            if (pills == null || pills.isEmpty) {
              return const SizedBox.shrink();
            }
            return SwaPillRail(
              pillIds: pills,
              enabled: !_isPillSending,
              onTap: (pillId) => _onPillTap(context, pillId),
            );
          },
        );
      },
    );
  }

  /// Opens the SWA offer sheet. Reads the listed price from current
  /// chat state so the sheet can render "Listed at ₹X" as a reference
  /// (optional — sheet works without it). On submit, dispatches to
  /// PrivateChatCubit.sendOffer which fires the WS + emits an optimistic
  /// offer bubble.
  void _openOfferSheet(BuildContext context) {
    int? listingPrice;
    final state = context.read<ChatMessagesCubit>().state;
    if (state is ChatMessagesLoaded) {
      listingPrice = state.chatMessages.data?.listing?.price;
    } else if (state is ChatMessagesLoadingMore) {
      listingPrice = state.chatMessages.data?.listing?.price;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SwaOfferSheet(
        listingPrice: listingPrice,
        // Mode-aware submit. In AI-backed modes (pills_only,
        // keyword_chat) the offer fires as a structured WS message
        // that the AI scores against the seller's floor + expected
        // price. In human-facing modes (p2p chat, seller takeover)
        // the seller has explicitly opted out of AI handling — we
        // honour that by sending the offer as a readable text
        // message the seller negotiates in their own words.
        onSubmit: (amount) {
          try {
            final isHumanMode = _isHumanChatModeForRail(context);
            if (isHumanMode) {
              final text = 'My offer: ₹${_formatInr(amount)}';
              context.read<PrivateChatCubit>().sendMessage(text);
            } else {
              context.read<PrivateChatCubit>().sendOffer(amount);
            }
          } catch (e) {
            debugPrint('Error dispatching offer: $e');
          }
        },
      ),
    );
  }

  /// Dispatches a pill tap. Two-branch mode-aware routing:
  ///   • `make_offer` → open the offer sheet (whose own submit decides
  ///     between AI-structured offer and plain-text "My offer: ₹X"
  ///     based on mode).
  ///   • AI modes (pills_only, keyword_chat) → fire a WS `pill_tap` so
  ///     the backend can respond with its canned pill template.
  ///   • Human modes (p2p, seller_takeover) → fire a plain WS `text`
  ///     message carrying the pill's human-readable `messageText`. The
  ///     seller reads this in their chat tab like any other message.
  ///
  /// The rail self-disables for up to 10s after a tap as a double-tap
  /// safety guard; it re-enables naturally sooner when a new message
  /// arrives (via the BlocBuilder watching PrivateChatCubit).
  void _onPillTap(BuildContext context, String pillId) {
    if (_isPillSending) return;

    if (pillId == 'make_offer') {
      _openOfferSheet(context);
      return;
    }

    try {
      final isHumanMode = _isHumanChatModeForRail(context);
      final spec = PillCatalog.specFor(pillId);

      // Routing decision:
      //   • Conversational pills (hasAiIntent=false) — ALWAYS sent as
      //     plain text regardless of mode. They're chat shortcuts, not
      //     AI commands. Filtered out of pills_only mode upstream.
      //   • AI-intent pills — in AI modes fire pill_tap for canned
      //     backend responses; in human modes send as text.
      final sendAsText = !isHumanMode && spec?.hasAiIntent == true
          ? false
          : true;

      if (sendAsText) {
        final text = spec?.messageText ?? spec?.label ?? pillId;
        context.read<PrivateChatCubit>().sendMessage(text);
      } else {
        context.read<PrivateChatCubit>().sendPillTap(pillId);
      }
      setState(() => _isPillSending = true);

      // Defensive timeout: clears the lock after 10s so a stuck tap
      // doesn't permanently disable the rail. Arrives of a new message
      // from the peer normally reset the UI faster via BlocBuilder.
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isPillSending) {
          setState(() => _isPillSending = false);
        }
      });
    } catch (e) {
      debugPrint('Error dispatching pill tap: $e');
    }
  }

  /// True when the current chat mode is human-facing (p2p or
  /// seller-takeover). Pill taps in these modes send as plain text so
  /// the seller reads them directly. Reads ChatMessagesCubit state
  /// without subscribing because the mode doesn't flip mid-frame.
  bool _isHumanChatModeForRail(BuildContext context) {
    final state = context.read<ChatMessagesCubit>().state;
    Data? data;
    if (state is ChatMessagesLoaded) {
      data = state.chatMessages.data;
    } else if (state is ChatMessagesLoadingMore) {
      data = state.chatMessages.data;
    }
    if (data == null) return false;
    return data.isP2PMode || data.isSellerTakeover;
  }
}

class _SafetyBanner extends StatelessWidget {
  final Color textColor;
  final VoidCallback onClose;

  const _SafetyBanner({
    Key? key,
    required this.textColor,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = ThemeHelper.isDarkMode(context)
        ? const Color(0xFF2A2E35)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Please do not share personal details like bank info, OTPs, or passwords in chat. Deal safely.",
                style: TextStyle(color: textColor, fontSize: 13, height: 1.3),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: textColor.withOpacity(0.7),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SWA status banner
//
// Renders a compact strip at the top of the chat thread that tells the
// user what mode the conversation is in. Driven by `conversation_status`
// from the unified getChatMessages response. The default/`active`
// state and pure-P2P (null) threads show nothing — the banner only
// appears when something worth surfacing has happened.
//
// Copy is intentionally neutral so the same string works for both
// buyer and seller; the distinction doesn't add meaningful info (both
// parties know who took over).
// ─────────────────────────────────────────────────────────────────────
class _SwaStatusBanner extends StatefulWidget {
  final String? status;

  /// Deadline for the `pending_acceptance` cooling-off window. Drives
  /// the live countdown in the subtitle. Null on every other status.
  final DateTime? expiresAt;

  /// Locked-in price once the deal reaches `accepted`. Shown in the
  /// success-banner subtitle so the buyer sees the amount they committed
  /// to without scrolling back to the agreement bubble.
  final int? agreedPrice;

  const _SwaStatusBanner({
    required this.status,
    this.expiresAt,
    this.agreedPrice,
  });

  @override
  State<_SwaStatusBanner> createState() => _SwaStatusBannerState();
}

class _SwaStatusBannerState extends State<_SwaStatusBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _maybeStartTicker();
  }

  @override
  void didUpdateWidget(covariant _SwaStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Status changed (e.g. seller confirmed the pending offer) → either
    // start or stop the countdown as appropriate.
    if (widget.status != oldWidget.status ||
        widget.expiresAt != oldWidget.expiresAt) {
      _ticker?.cancel();
      _ticker = null;
      _maybeStartTicker();
    }
  }

  void _maybeStartTicker() {
    // Only the pending-acceptance banner shows a live "X min left"
    // string; other statuses are static. Tick every 30s — fine for
    // a minute-granularity display and cheap enough not to matter.
    if (widget.status == 'pending_acceptance' && widget.expiresAt != null) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(
      widget.status,
      expiresAt: widget.expiresAt,
      agreedPrice: widget.agreedPrice,
    );
    if (copy == null) return const SizedBox.shrink();

    final isDark = ThemeHelper.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: copy.bg(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: copy.border(isDark)),
      ),
      child: Row(
        children: [
          Icon(copy.icon, size: 18, color: copy.iconColor(isDark)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0A1628),
                  ),
                ),
                if (copy.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    copy.subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the banner copy for a given status. Side-data fields
  /// (expiresAt, agreedPrice) are optional — when present they enrich
  /// the subtitle with live countdowns and amounts.
  static _BannerCopy? _copyFor(
    String? s, {
    DateTime? expiresAt,
    int? agreedPrice,
  }) {
    switch (s) {
      case 'seller_takeover':
        return _BannerCopy(
          title: 'Seller is handling this conversation',
          subtitle:
              'Smart Assist has paused — messages go directly to the seller.',
          icon: Icons.pause_circle_outline_rounded,
          tone: _BannerTone.info,
        );
      case 'pending_acceptance':
        return _BannerCopy(
          title: 'Your offer is in',
          subtitle: _pendingSubtitle(expiresAt),
          icon: Icons.hourglass_top_rounded,
          tone: _BannerTone.pending,
        );
      case 'accepted':
        return _BannerCopy(
          title: 'Deal confirmed',
          subtitle: _acceptedSubtitle(agreedPrice),
          icon: Icons.check_circle_outline_rounded,
          tone: _BannerTone.success,
        );
      case 'completed':
        return _BannerCopy(
          title: 'Deal completed',
          icon: Icons.verified_rounded,
          tone: _BannerTone.success,
        );
      case 'declined':
        return _BannerCopy(
          title: 'Conversation declined',
          subtitle: 'This offer is closed.',
          icon: Icons.cancel_outlined,
          tone: _BannerTone.warn,
        );
      case 'expired':
        return _BannerCopy(
          title: 'Conversation ended',
          subtitle: 'This listing is no longer active.',
          icon: Icons.history_toggle_off_rounded,
          tone: _BannerTone.warn,
        );
      case 'legal_hold':
        return _BannerCopy(
          title: 'Under review',
          subtitle:
              'This conversation is temporarily paused pending review.',
          icon: Icons.gpp_maybe_outlined,
          tone: _BannerTone.warn,
        );
      // 'active' and null → no banner
      default:
        return null;
    }
  }

  /// Live countdown for the seller-confirmation window. Rounds to
  /// whole minutes; "moments" for the last 60 seconds so the banner
  /// never shows "0 min left" and feels alive.
  static String _pendingSubtitle(DateTime? expiresAt) {
    if (expiresAt == null) {
      return 'Waiting for the seller to confirm.';
    }
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    if (diff.inSeconds <= 0) {
      // Expiry clock ran out client-side; server's cron auto-promotes
      // within the next minute. Keep the user informed instead of
      // flipping to a blank subtitle.
      return 'Finalising with the seller...';
    }
    if (diff.inSeconds < 60) {
      return 'Waiting for the seller to confirm — any moment now.';
    }
    final mins = diff.inMinutes + (diff.inSeconds % 60 >= 30 ? 1 : 0);
    return 'Waiting for the seller to confirm — $mins min left.';
  }

  static String _acceptedSubtitle(int? agreedPrice) {
    if (agreedPrice != null && agreedPrice > 0) {
      return 'Confirmed at ₹${_formatInrStatic(agreedPrice)}. '
          'Coordinate pickup in chat.';
    }
    return 'Coordinate pickup in chat. Smart Assist has stepped aside.';
  }

  /// Static copy of the Indian-grouping formatter; banner is rendered
  /// outside the `_ChatScreenState` class so it cannot reach the
  /// instance method. Keep in sync with `_ChatScreenState._formatInr`.
  static String _formatInrStatic(int n) {
    final s = n.abs().toString();
    if (s.length <= 3) return n < 0 ? '-$s' : s;
    final last3 = s.substring(s.length - 3);
    final head = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    int cursor = head.length;
    while (cursor > 2) {
      buf.write(',');
      buf.write(head.substring(cursor - 2, cursor));
      cursor -= 2;
    }
    final prefix = head.substring(0, cursor) + buf.toString();
    return (n < 0 ? '-' : '') + prefix + ',' + last3;
  }
}

enum _BannerTone { info, pending, success, warn }

class _BannerCopy {
  final String title;
  final String? subtitle;
  final IconData icon;
  final _BannerTone tone;
  _BannerCopy({required this.title, this.subtitle, required this.icon, required this.tone});

  Color bg(bool isDark) {
    switch (tone) {
      case _BannerTone.info:
        return isDark ? const Color(0xFF0F2847) : const Color(0xFFEBF4FF);
      case _BannerTone.pending:
        return isDark ? const Color(0xFF3A2B0A) : const Color(0xFFFFF4E0);
      case _BannerTone.success:
        return isDark ? const Color(0xFF0E2E18) : const Color(0xFFE6F6EA);
      case _BannerTone.warn:
        return isDark ? const Color(0xFF3A1212) : const Color(0xFFFDE8E8);
    }
  }
  Color border(bool isDark) {
    switch (tone) {
      case _BannerTone.info:
        return const Color(0xFF1677FF).withOpacity(isDark ? 0.35 : 0.25);
      case _BannerTone.pending:
        return const Color(0xFFD97706).withOpacity(isDark ? 0.35 : 0.25);
      case _BannerTone.success:
        return const Color(0xFF16A34A).withOpacity(isDark ? 0.35 : 0.25);
      case _BannerTone.warn:
        return const Color(0xFFDC2626).withOpacity(isDark ? 0.35 : 0.25);
    }
  }
  Color iconColor(bool isDark) {
    switch (tone) {
      case _BannerTone.info:    return const Color(0xFF1677FF);
      case _BannerTone.pending: return const Color(0xFFD97706);
      case _BannerTone.success: return const Color(0xFF16A34A);
      case _BannerTone.warn:    return const Color(0xFFDC2626);
    }
  }
}
