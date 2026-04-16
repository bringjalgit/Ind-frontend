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
                _buildInputArea(context),
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
