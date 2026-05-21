import 'dart:async';

import 'package:classifieds/Components/debugPrint.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:classifieds/data/cubit/ChatMessages/ChatMessagesCubit.dart';
import '../../Components/CustomSnackBar.dart';
import '../../data/cubit/Chat/private_chat_cubit.dart';
import '../../data/cubit/ChatMessages/ChatMessagesStates.dart';
import '../../model/ChatMessagesModel.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../widgets/P2PPillCatalog.dart';
import '../../widgets/P2POfferSheet.dart';
import '../../widgets/IncomingOfferCard.dart';
import '../../model/OfferRecommendationModel.dart';
import '../../data/remote_data_source.dart';
import '../../utils/AppLauncher.dart';
import '../../widgets/SafeDealDialog.dart';
import 'ReportBottomSheet.dart';
import 'swa/SwaPillRail.dart';
import 'swa/SwaOfferSheet.dart';
import 'swa/pill_catalog.dart';

extension ChatScreenMessagesX on Messages {
  DateTime get createdAtDate {
    final raw = createdAt?.toString() ?? '';
    // Backend serializes timestamps as ISO with the 'Z' suffix (UTC).
    // DateTime.tryParse honors that and returns a UTC DateTime; we
    // convert to local once here so every call site (formatting, day
    // bucketing, comparisons) sees IST without having to remember to
    // toLocal() again.
    return (DateTime.tryParse(raw) ?? DateTime.now()).toLocal();
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

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
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

  // Coupled-scroll controllers for the P2P pill rail's two rows.
  // Lazily created the first time the rail mounts (non-SWA only). The
  // listeners mirror one controller's offset onto the other so the
  // bottom row glides in the opposite direction as the user drags the
  // top — and vice versa. `_railLock` prevents the mirror set from
  // looping back through the destination's listener.
  ScrollController? _p2pTopRailCtrl;
  ScrollController? _p2pBotRailCtrl;
  bool _railLock = false;
  bool _railCouplingAttached = false;

  // P2P "Make an Offer" — AI recommendation cache. Fetched once on
  // chat open (best-effort, non-blocking) so the hero pill can show
  // "AI suggests ₹X" before the buyer taps, and the sheet can render
  // the AI card without spinning. Null when the fetch hasn't returned
  // yet OR failed — both the hero pill and the sheet fall back to
  // local heuristics in that case.
  OfferRecommendation? _offerRec;
  bool _offerRecLoaded = false;

  // Continuous gradient-flow animation for the buyer-side hero pill.
  // One controller drives a single [_SlidingGradient] transform on
  // the pill's LinearGradient — the colours appear to slide left →
  // right indefinitely while only the pill rebuilds (AnimatedBuilder
  // scope = the gradient layer, not the chat list). 4.5 s per cycle
  // matches the "gradient flow" variant chosen during design.
  late final AnimationController _heroPillFlowCtrl =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  )..repeat();

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

    // Best-effort AI recommendation fetch for the P2P "Make an Offer"
    // hero pill + sheet. Non-blocking — the sheet still renders
    // without a server rec (falls back to local heuristic). Fired
    // once per chat open; the value is cached for the lifetime of
    // the screen since listing prices don't move during a session.
    _prefetchOfferRecommendation();

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
    _p2pTopRailCtrl?.dispose();
    _p2pBotRailCtrl?.dispose();
    _heroPillFlowCtrl.dispose();

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
                // Avatar + name + listing title is a tap target —
                // routes to the OTHER party's profile. The screen
                // (SellerProfileScreen) is generic; we override the
                // header title based on which role the OTHER party
                // plays:
                //   • Buyer viewing seller's profile → "Seller Profile"
                //   • Seller viewing buyer's profile → "Buyer Profile"
                // We read `viewer_is_seller` from the loaded chat data
                // when available; otherwise default to "Seller Profile"
                // (the original entry-point flow).
                InkWell(
                  onTap: () {
                    try {
                      if (widget.receiverId.isEmpty) return;
                      final cubitState =
                          context.read<ChatMessagesCubit>().state;
                      bool viewerIsSeller = false;
                      if (cubitState is ChatMessagesLoaded) {
                        viewerIsSeller =
                            cubitState.chatMessages.data?.viewerIsSeller ?? false;
                      } else if (cubitState is ChatMessagesLoadingMore) {
                        viewerIsSeller =
                            cubitState.chatMessages.data?.viewerIsSeller ?? false;
                      }
                      final title = Uri.encodeComponent(
                          viewerIsSeller ? 'Buyer Profile' : 'Seller Profile');
                      context.push(
                        '/seller_profile?userId=${widget.receiverId}&title=$title',
                      );
                    } catch (_) {}
                  },
                  child: Row(
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
              // Phone-privacy gate (2026-05-19): the call icon only
              // renders when the other party's mobile number is actually
              // available in the REST response. For SWA chats where the
              // seller has `hide_phone_from_buyers` ON, the backend
              // returns mobile=null and we render nothing here — no
              // confusing icon that always snackbar-fails. The icon
              // reappears automatically once mobile is populated again
              // (seller flipped the toggle / conversation went to
              // seller_takeover) because ValueListenableBuilder rebuilds.
              ValueListenableBuilder(
                valueListenable: mobileNotifier,
                builder: (context, mobile, child) {
                  if (mobile == null || mobile.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.call),
                    color: textColor,
                    onPressed: () => AppLauncher.call(mobile),
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
                      viewerIsSeller: data?.viewerIsSeller ?? false,
                    );
                  },
                ),
                // Listing context strip — sits directly under the app
                // bar so the buyer/seller always sees what they're
                // negotiating on. Renders nothing when the chat hasn't
                // loaded yet OR when the listing has no price (an
                // unpriced listing has no anchor for an offer flow,
                // and the strip would just be visual noise).
                BlocBuilder<ChatMessagesCubit, ChatMessagesStates>(
                  buildWhen: (p, c) =>
                      c is ChatMessagesLoaded || c is ChatMessagesLoadingMore,
                  builder: (context, state) {
                    ChatListingSummary? listing;
                    bool viewerIsSeller = false;
                    if (state is ChatMessagesLoaded) {
                      listing = state.chatMessages.data?.listing;
                      viewerIsSeller = state.chatMessages.data?.viewerIsSeller ?? false;
                    } else if (state is ChatMessagesLoadingMore) {
                      listing = state.chatMessages.data?.listing;
                      viewerIsSeller = state.chatMessages.data?.viewerIsSeller ?? false;
                    }
                    if (listing == null ||
                        (listing.price ?? 0) <= 0) {
                      return const SizedBox.shrink();
                    }
                    return _buildListingStrip(
                      context,
                      listing: listing,
                      viewerIsSeller: viewerIsSeller,
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

                        // Captured for the SWA-aware isMe alignment fix
                        // below — when the seller views an SWA thread,
                        // messages authored by the AI on their behalf
                        // (sender=seller|system|keyword_bot) need to
                        // render on the RIGHT, not the LEFT.
                        bool viewerIsSeller = false;
                        if (historyState is ChatMessagesLoaded) {
                          viewerIsSeller =
                              historyState.chatMessages.data?.viewerIsSeller ?? false;
                        } else if (historyState is ChatMessagesLoadingMore) {
                          viewerIsSeller =
                              historyState.chatMessages.data?.viewerIsSeller ?? false;
                        }

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
                                          // SWA-aware "is mine" check.
                                          // The viewer-owned senderId
                                          // catches buyer-typed and
                                          // seller-typed messages. The
                                          // OR-branch catches AI
                                          // auto-replies on the
                                          // seller's behalf (sender =
                                          // seller / system /
                                          // keyword_bot) — those land
                                          // with a non-seller senderId
                                          // server-side but should
                                          // visually read as the
                                          // seller's own outgoing
                                          // messages, on the right.
                                          final senderRole = msg.sender ?? '';
                                          // SWA messages loaded from REST don't carry a
                                          // per-message `sender_id` — the schema records
                                          // the role string ('buyer' / 'seller' / 'system')
                                          // and the user IDs live at the conversation
                                          // root. Resolve `isMe` from the role too so that
                                          // a buyer's REST-loaded pill_tap message still
                                          // renders as the buyer's own bubble (pretty
                                          // labelled pill) rather than falling through to
                                          // the plain-text path that dumps the raw pill ID.
                                          final isMe =
                                              (msg.senderId?.toString() ??
                                                  '') ==
                                                  widget.currentUserId ||
                                              (viewerIsSeller &&
                                                  (senderRole == 'seller' ||
                                                      senderRole == 'system' ||
                                                      senderRole == 'keyword_bot')) ||
                                              (!viewerIsSeller &&
                                                  senderRole == 'buyer');
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
      // Pass isMe down so the SWA bubble can flip to the right side
      // when the SELLER views the conversation (AI auto-replies are
      // effectively the seller's outgoing messages and should mirror
      // a normal sent bubble).
      return _buildSwaBubble(context, msg, isMe);
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
  Widget _buildSwaBubble(BuildContext context, Messages msg, bool isMe) {
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
      // 2026-05-17 — alignment + corner tail now respect isMe so the
      // seller sees AI-on-their-behalf replies on the RIGHT (like
      // their own outgoing messages) instead of stacked on the left
      // beside the buyer's messages.
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

        // Phase 2 spam-lowball cooldown (2026-04-26) — when the chat
        // was closed by the engine for joke offers AND the 48h
        // cooldown is still active, replace the composer with the
        // "Chat paused" banner so the buyer can't keep retrying. The
        // banner shows hours remaining; once the cooldown elapses,
        // `isSpamLowballCooldown` flips false and the regular
        // composer comes back (the next send naturally resets the
        // conversation server-side).
        if (convData != null && convData.isSpamLowballCooldown) {
          return _buildSpamLowballCooldownBanner(
            context,
            convData.spamLowballCooldownHoursRemaining,
          );
        }

        // Only intercept when the seller explicitly chose pills_only on
        // an SWA thread AND the conversation hasn't been taken over.
        // All other cases (P2P, ai_chat, p2p mode, seller_takeover,
        // pending/accepted states on SWA) keep the regular text input
        // so the buyer can coordinate pickup, reply to a seller
        // override, etc.
        //
        // The `!convData.isSellerTakeover` guard is the second half of
        // the per-conversation takeover model: once the seller types
        // anything on this thread, AI goes silent forever for this
        // (listing, buyer) pair, and the buyer needs a composer to
        // close out the deal 1:1. `chatModeSnapshot` stays frozen at
        // 'disabled' for the lifetime of the conversation, so we
        // can't rely on it alone — we have to combine it with the
        // live `conversation_status` to pick the right surface.
        //
        // Sellers always see the plain text composer regardless of mode
        // — typing here is the implicit-takeover signal handled by the
        // gateway in messaging.js, and they need a way to do it from
        // the regular chat list (not just from the SWA Dashboard).
        if (convData != null &&
            convData.isSwa &&
            convData.isPillsOnly &&
            !convData.viewerIsSeller &&
            !convData.isSellerTakeover) {
          return _buildPillsOnlyHint(context);
        }
        return _buildInputArea(context);
      },
    );
  }

  /// "Chat paused" banner — replaces the input composer when the chat
  /// was closed by SPAM_LOWBALL_CLOSE and the 48h cooldown is still
  /// active. Headline + body match Option C wording. Read-only —
  /// the buyer cannot dismiss it (the cooldown is what dismisses it).
  Widget _buildSpamLowballCooldownBanner(BuildContext context, int hoursRemaining) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = ThemeHelper.backgroundColor(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0A1628);
    final mutedColor = isDark
        ? Colors.white.withOpacity(0.65)
        : const Color(0xFF6B7280);
    final amberFg = isDark ? const Color(0xFFFFD600) : const Color(0xFFB45309);
    final amberBg = isDark
        ? const Color(0x14FFD600)
        : const Color(0x0FB45309);

    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: amberFg.withOpacity(0.35)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: amberBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pause_circle_outline_rounded,
                    color: amberFg,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat paused',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This chat is paused for the next ${hoursRemaining}h. '
                        'Come back with a serious offer.',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
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

  Future<void> _sendText(BuildContext context) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // ── Takeover warning gate (point 2) ───────────────────────────────
    // First-time warning for the seller when they're about to send a
    // text-box message on an SWA-active conversation. Per-conversation
    // flag in SharedPreferences (`swa_takeover_warned_<conversationId>`)
    // so re-opening the same chat doesn't keep nagging. Cancelling the
    // dialog leaves the typed message in the input — the seller can
    // tap Cancel without losing their draft.
    final cubitState = context.read<ChatMessagesCubit>().state;
    Data? convData;
    if (cubitState is ChatMessagesLoaded) {
      convData = cubitState.chatMessages.data;
    } else if (cubitState is ChatMessagesLoadingMore) {
      convData = cubitState.chatMessages.data;
    }
    final viewerIsSeller = convData?.viewerIsSeller ?? false;
    final status = convData?.conversationStatus;
    final convId = convData?.conversationId;
    final swaStillRunning =
        status == 'active' || status == 'pending_acceptance';

    if (viewerIsSeller &&
        swaStillRunning &&
        convId != null &&
        convId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'swa_takeover_warned_$convId';
      final alreadyWarned = prefs.getBool(key) ?? false;
      if (!alreadyWarned) {
        if (!context.mounted) return;
        final proceed = await _showTakeoverWarningDialog(context);
        if (proceed != true) return; // cancelled — keep draft
        await prefs.setBool(key, true);
        if (!context.mounted) return;
      }
    }

    try {
      context.read<PrivateChatCubit>().sendMessage(text);
      _controller.clear();
    } catch (e) {
      debugPrint('Error accessing PrivateChatCubit in _sendText: $e');
    }
  }

  /// Modal dialog shown the first time a seller sends a text-box
  /// message on an SWA-active conversation. Returns true when the
  /// seller confirms takeover, false (or null) when they cancel.
  ///
  /// 2026-05-17 v2 — redesigned from a flat AlertDialog into a card
  /// with an amber-tinted "warning" header (icon in a soft circle +
  /// title), a roomy body, and two equal-weight action buttons. All
  /// colours theme-aware:
  ///   • Light: white card, amber-50 header tint, slate body text,
  ///     bordered Cancel button, blue-gradient confirm.
  ///   • Dark:  near-black card, amber@10% header tint, lighter body
  ///     text, white@8% Cancel surface, same blue confirm.
  Future<bool?> _showTakeoverWarningDialog(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final lineSoft = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE5E8EE);

    // Amber palette for the warning band — Tailwind amber-ish, tuned
    // for both surfaces.
    const amberIcon = Color(0xFFFFB020);
    final amberTint = isDark
        ? amberIcon.withOpacity(0.12)
        : const Color(0xFFFFF4DC);
    final amberIconBg = isDark
        ? amberIcon.withOpacity(0.18)
        : const Color(0xFFFFE6B0);

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(isDark ? 0.65 : 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lineSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.50 : 0.18),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Warning header band ──────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: amberTint,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: amberIconBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: amberIcon,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Take over from Smart Assist?',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  "Smart Assist is currently negotiating with this buyer "
                  "on your behalf. Sending this message will pause it — "
                  "you'll handle the conversation yourself from here.",
                  style: TextStyle(
                    color: textColor.withOpacity(isDark ? 0.78 : 0.72),
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ),

              // ── Actions ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.transparent,
                            side: BorderSide(color: lineSoft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1677FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ).copyWith(
                            shadowColor: WidgetStateProperty.all(
                              const Color(0xFF1677FF).withOpacity(0.32),
                            ),
                            elevation: WidgetStateProperty.all(2),
                          ),
                          child: const Text(
                            'Send & take over',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  // ── P2P quick-reply pill rail ─────────────────────────────────────
  //
  // Renders a horizontally-scrolling chip strip above the composer for
  // non-SWA chats. Buyer always sees the same set; seller sees pills
  // contextual to the most-recent buyer message's `intent`, falling
  // back to seller-initiator chips when there's no useful context.
  //
  // Pills are accelerators only — the composer (text input) stays
  // available next to the rail. Tapping a pill calls
  // `PrivateChatCubit.sendMessage(text, intent: pill.id)` and the
  // optimistic local message appears immediately in the chat list.
  //
  // SWA paths never reach this method — the early `!convData.isSwa`
  // branch in [_buildPillRail] routes here only for plain P2P threads.
  Widget _buildP2PPillRail(BuildContext context, Data convData) {
    final viewerIsSeller = convData.viewerIsSeller;

    // Buyer view: two rows (six chips each) with coupled scroll.
    // Top row sweeps the openers + asks; bottom row carries logistics
    // + closure. Drag the top right → bottom slides left (and vice
    // versa) so a single gesture exposes new chips on both rows.
    if (!viewerIsSeller) {
      return _buildBuyerTwoRowRail(context);
    }

    // Seller view: single row, contextual. Watching PrivateChatCubit
    // so the strip re-renders the moment a new buyer pill lands.
    return BlocBuilder<PrivateChatCubit, PrivateChatState>(
      builder: (context, live) {
        // Merge history + live, walk newest-first, find the most
        // recent non-self message. If it has an intent → contextual
        // answers; otherwise (free text / image) → seller-initiator
        // fallback.
        final all = <Messages>[];
        all.addAll(convData.messages ?? const <Messages>[]);
        all.addAll(live.messages);
        all.sort((a, b) => b.createdAtDate.compareTo(a.createdAtDate));

        String? lastBuyerIntent;
        for (final m in all) {
          if (m.senderId == widget.currentUserId) continue;
          if (m.intent != null && m.intent!.isNotEmpty) {
            lastBuyerIntent = m.intent;
          }
          break;
        }

        // Pending-offer detection: when the most recent buyer-vs-seller
        // exchange ends with a buyer offer the seller hasn't answered,
        // render the yellow incoming-offer hero card and the
        // accept/counter/decline response row. Walks the same merged
        // timeline newest-first so it stays in sync with the pill
        // strip's intent resolution above.
        final pendingOffer = _findPendingBuyerOffer(all);
        if (pendingOffer != null) {
          final amount = _parseOfferAmount(pendingOffer.message);
          if (amount != null && amount > 0) {
            return _buildSellerIncomingOfferStack(context, amount);
          }
        }

        return _renderP2PPillStripSingle(
          context,
          P2PPillCatalog.sellerAnswersFor(lastBuyerIntent),
        );
      },
    );
  }

  /// Seller-side stack rendered when a buyer offer is pending —
  /// IncomingOfferCard (hero) on top of a single-row response strip
  /// (Accept · Counter ₹X · Decline). Replaces the default seller
  /// pill rail for the duration of the pending state.
  Widget _buildSellerIncomingOfferStack(BuildContext context, int buyerOffer) {
    final listingPrice = _currentListingPrice(context);
    final suggestedCounter =
        _suggestedSellerCounter(buyerOffer, listingPrice, _offerRec);
    final isDark = ThemeHelper.isDarkMode(context);
    final surface =
        isDark ? const Color(0xFF131826) : const Color(0xFFFFFFFF);
    final lineSoft = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: lineSoft)),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IncomingOfferCard(
            buyerOffer: buyerOffer,
            listedPrice: listingPrice,
            aiSuggestedCounter: suggestedCounter,
          ),
          const SizedBox(height: 10),
          _buildSellerOfferResponseRow(context, buyerOffer, suggestedCounter),
        ],
      ),
    );
  }

  /// Three-button row that replaces the seller's contextual pill rail
  /// when a buyer offer is pending. Mapped to the existing offer-
  /// response intents — `offer_accept`, `counter_offer`,
  /// `offer_decline` — so the message wire contract stays unchanged.
  ///
  /// Dark-mode treatment:
  ///   • Accept stays solid green — works on both backgrounds.
  ///   • Counter switches to the theme card surface so it doesn't
  ///     light up white on a dark sheet; foreground is theme text.
  ///   • Decline foreground brightens to a lighter red and the
  ///     border drops to a translucent red so the outline still
  ///     reads on the dark surface.
  Widget _buildSellerOfferResponseRow(
      BuildContext context, int buyerOffer, int suggestedCounter) {
    final isDark = ThemeHelper.isDarkMode(context);
    final declineFg =
        isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
    final declineBorder = isDark
        ? const Color(0xFFFCA5A5).withOpacity(0.30)
        : const Color(0xFFFECACA);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSellerActionPill(
              context,
              label: 'Accept',
              icon: Icons.check_rounded,
              color: const Color(0xFF2E7D32),
              foreground: Colors.white,
              onTap: () {
                try {
                  context.read<PrivateChatCubit>().sendMessage(
                        'Accepted — ₹${_formatInr(buyerOffer)}',
                        intent: 'offer_accept',
                      );
                } catch (e) {
                  debugPrint('offer_accept error: $e');
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildSellerActionPill(
              context,
              label: 'Counter ₹${_formatInr(suggestedCounter)}',
              icon: Icons.swap_horiz_rounded,
              color: ThemeHelper.cardColor(context),
              foreground: ThemeHelper.textColor(context),
              bordered: true,
              onTap: () => _openSellerCounterSheet(context, buyerOffer),
            ),
          ),
          const SizedBox(width: 8),
          _buildSellerActionPill(
            context,
            label: '',
            icon: Icons.close_rounded,
            color: Colors.transparent,
            foreground: declineFg,
            bordered: true,
            borderColor: declineBorder,
            iconOnly: true,
            onTap: () {
              try {
                context.read<PrivateChatCubit>().sendMessage(
                      "Sorry, that's too low",
                      intent: 'offer_decline',
                    );
              } catch (e) {
                debugPrint('offer_decline error: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSellerActionPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color foreground,
    required VoidCallback onTap,
    bool bordered = false,
    bool iconOnly = false,
    Color? borderColor,
  }) {
    final lineColor = borderColor ??
        (ThemeHelper.isDarkMode(context)
            ? Colors.white.withOpacity(0.10)
            : const Color(0xFFE5E8EE));
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: iconOnly ? 14 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: bordered ? Border.all(color: lineColor, width: 1.4) : null,
          ),
          alignment: Alignment.center,
          child: iconOnly
              ? Icon(icon, size: 18, color: foreground)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Compact listing context strip rendered between the AppBar and
  /// the chat thread. Shows a placeholder thumbnail (we don't fetch
  /// the listing image in ChatListingSummary to keep the message
  /// fetch lean) + the title + a small status meta line + the listed
  /// price. Tap routes to the listing detail screen so either party
  /// can re-check the spec mid-conversation. Designed to stay alive
  /// even when the seller is the viewer — they want their own
  /// listing anchor too.
  Widget _buildListingStrip(
    BuildContext context, {
    required ChatListingSummary listing,
    required bool viewerIsSeller,
  }) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final surface = isDark
        ? const Color(0xFF131826)
        : const Color(0xFFF8FBFF);
    final lineSoft = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFE7EFFA);
    final thumbBg = isDark
        ? const Color(0xFF1B2233)
        : const Color(0xFFE3ECF7);
    final thumbIconColor = isDark
        ? Colors.white.withOpacity(0.55)
        : const Color(0xFF5F7390);

    final priceLabel = listing.sold == true ? 'SOLD' : 'LISTED';
    final priceText = '₹${_formatInr(listing.price ?? 0)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: lineSoft)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 42,
              height: 42,
              child: (listing.image ?? '').isNotEmpty
                  // Real listing image when the backend provides one.
                  // errorBuilder falls back to the placeholder so a
                  // 404 / broken URL never leaves a grey hole.
                  ? Image.network(
                      listing.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: thumbBg,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.local_offer_outlined,
                          size: 20,
                          color: thumbIconColor,
                        ),
                      ),
                    )
                  : Container(
                      color: thumbBg,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.local_offer_outlined,
                        size: 20,
                        color: thumbIconColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (listing.title ?? '').trim().isEmpty
                      ? widget.listingTitle
                      : listing.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.1,
                  ),
                ),
                if (viewerIsSeller) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Your listing',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                priceLabel,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: textColor.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                priceText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1677FF),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Parses an integer rupee amount out of a P2P offer/counter
  /// message body. Both flows send the offer as plain text — e.g.
  /// "My offer: ₹1,34,850" or "My counter: ₹1,40,000" — so the
  /// seller-side render needs to read the number back out. Returns
  /// null when no rupee amount is found (defensive — if the text is
  /// malformed for any reason the card simply doesn't render).
  int? _parseOfferAmount(String? text) {
    if (text == null || text.isEmpty) return null;
    final m = RegExp(r'₹\s*([\d,]+)').firstMatch(text);
    if (m == null) return null;
    final digits = (m.group(1) ?? '').replaceAll(',', '');
    return int.tryParse(digits);
  }

  /// Walks the message timeline newest-first and returns the most
  /// recent buyer offer that the seller hasn't responded to yet.
  /// "Hasn't responded" = there's no seller message AFTER the offer
  /// in the timeline. Returns null when no pending offer exists.
  ///
  /// Used to decide whether the seller-side incoming-offer hero card
  /// should render above the pill rail. As soon as the seller sends
  /// anything (accept/counter/decline pill or free text) the card
  /// disappears on the next rebuild.
  Messages? _findPendingBuyerOffer(List<Messages> messages) {
    // Sort newest-first; we walk that way.
    final sorted = [...messages]
      ..sort((a, b) => b.createdAtDate.compareTo(a.createdAtDate));
    for (final m in sorted) {
      // Any seller message AFTER an offer means the seller has
      // already responded — short-circuit, nothing pending.
      if (m.senderId == widget.currentUserId) return null;
      if (m.intent == 'make_offer') return m;
    }
    return null;
  }

  /// Heuristic for the seller's "AI suggested counter" — pre-fills
  /// the counter sheet and labels the Counter pill in the response
  /// row. Invariants:
  ///
  ///   • The counter NEVER exceeds the listed price. A seller asking
  ///     more than what they themselves advertised is nonsensical and
  ///     would surface as a UX bug ("AI suggests ₹26,300 on a ₹25,000
  ///     listing"). Hard-capped at the end of this function.
  ///   • The counter is strictly greater than the buyer's offer —
  ///     otherwise there's nothing to counter. If the buyer offered
  ///     at-or-above list we just return the listed price (the seller
  ///     should accept; we cap to keep the sheet usable either way).
  ///
  /// Candidate selection (in order of preference):
  ///   1. The server recommendation if it lives between buyerOffer
  ///      and listed — that's "where this listing typically closes".
  ///   2. Midpoint between buyer's offer and listed.
  ///   3. +5% over the buyer's offer (legacy fallback, only fires
  ///      when listed is missing).
  int _suggestedSellerCounter(int buyerOffer, int? listed, OfferRecommendation? rec) {
    // Edge case: buyer already at-or-above list — return listed so
    // the Counter button still renders a coherent number even though
    // the seller's real move here is Accept.
    if (listed != null && listed > 0 && buyerOffer >= listed) {
      return listed;
    }

    int candidate;
    if (rec != null &&
        rec.recommended > buyerOffer &&
        (listed == null || listed <= 0 || rec.recommended <= listed)) {
      candidate = rec.recommended;
    } else if (listed != null && listed > 0 && listed > buyerOffer) {
      // Round midpoint to nearest 100 for visual cleanliness.
      final mid = ((buyerOffer + listed) / 2).round();
      candidate = ((mid / 100).round()) * 100;
    } else {
      candidate = ((buyerOffer * 1.05) / 100).round() * 100;
    }

    // Hard cap at listed price — the invariant from the doc-comment.
    if (listed != null && listed > 0 && candidate > listed) {
      return listed;
    }
    return candidate;
  }

  /// Background fetch of the AI offer recommendation for this
  /// listing. Best-effort — failures are swallowed; the UI falls
  /// back to local heuristics. Mutates [_offerRec] + [_offerRecLoaded]
  /// once and triggers a rebuild so the hero pill can replace its
  /// loading state with the recommended number.
  Future<void> _prefetchOfferRecommendation() async {
    if (_offerRecLoaded) return;
    try {
      final rec = await RemoteDataSourceImpl()
          .getOfferRecommendation(widget.listingId);
      if (!mounted) return;
      setState(() {
        _offerRec = rec?.data;
        _offerRecLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _offerRecLoaded = true);
    }
  }

  /// Listed price for the current chat, pulled from ChatMessagesCubit
  /// state. Used by the hero pill, the offer sheet, and the
  /// incoming-offer card. Returns null when the messages fetch
  /// hasn't completed (or the listing has no price set).
  int? _currentListingPrice(BuildContext context) {
    final state = context.read<ChatMessagesCubit>().state;
    if (state is ChatMessagesLoaded) {
      return state.chatMessages.data?.listing?.price;
    }
    if (state is ChatMessagesLoadingMore) {
      return state.chatMessages.data?.listing?.price;
    }
    return null;
  }

  /// Hero "Make an Offer" pill — the buyer-side persistent CTA shown
  /// above the two-row pill rail. Always full-width, brand-blue
  /// gradient, with the AI's suggested offer surfaced on the right
  /// side so the value-add is visible before the buyer taps.
  ///
  /// Tapping the pill opens [P2POfferSheet] in buyer-offer mode with
  /// the cached recommendation. The sheet handles its own submit and
  /// dispatches via [PrivateChatCubit.sendP2POffer].
  Widget _buildMakeOfferHeroPill(BuildContext context) {
    final listingPrice = _currentListingPrice(context);
    if (listingPrice == null || listingPrice <= 0) {
      // Without a price we can't render a useful recommendation. Hide
      // the hero pill rather than show a half-broken one — the rail
      // below still gives the buyer plenty of ways to engage.
      return const SizedBox.shrink();
    }

    // Build the "AI suggests" trailing chip. While the rec is still
    // loading we show a soft "AI suggestion loading" so the buyer
    // doesn't see a blank space and wonder if the pill is broken.
    final rec = _offerRec;
    Widget trailing;
    if (rec != null && rec.recommended > 0) {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD600),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFFFFD600), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'AI suggests ₹${_formatInr(rec.recommended)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (!_offerRecLoaded) {
      trailing = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.6,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      );
    } else {
      // Rec fetch finished without data — keep the pill, drop the chip.
      trailing = const SizedBox.shrink();
    }

    // Static contents of the pill (icon + label + trailing chip).
    // Passed as `child:` to the AnimatedBuilder so the row isn't
    // rebuilt on every animation tick — only the gradient transform
    // recomputes per frame.
    final pillRow = Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.currency_rupee_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Make an Offer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openP2POfferSheet(context),
          // ─── Continuous gradient-flow animation (Variant 2) ───
          // AnimatedBuilder scope is JUST this Container — the chat
          // list, pill rails, and message stream don't rebuild per
          // frame. The trick:
          //
          //   • The gradient is 2× the visible box wide, with a 9-stop
          //     colour list that REPEATS the 5-colour pattern twice
          //     (A-B-C-B-A-B-C-B-A). The first half and second half
          //     look identical.
          //   • We slide begin/end leftward by one box-width over the
          //     controller's 0 → 1 cycle. Because the visible window
          //     of the gradient at value=0 and value=1 lands on
          //     identical halves of the pattern, the loop is seamless
          //     — no visual jump when the controller resets.
          //   • Perceived motion direction: the gradient slides left,
          //     so colours that were "to the right" enter each
          //     position over time = L → R flow.
          child: AnimatedBuilder(
            animation: _heroPillFlowCtrl,
            builder: (context, child) {
              final shift = 2.0 * _heroPillFlowCtrl.value;
              return Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 - shift, 0),
                    end: Alignment(3.0 - shift, 0),
                    colors: const [
                      Color(0xFF0F5FCE),
                      Color(0xFF1677FF),
                      Color(0xFF5A8CFF),
                      Color(0xFF1677FF),
                      Color(0xFF0F5FCE),
                      Color(0xFF1677FF),
                      Color(0xFF5A8CFF),
                      Color(0xFF1677FF),
                      Color(0xFF0F5FCE),
                    ],
                    stops: const [
                      0.0, 0.125, 0.25, 0.375, 0.5,
                      0.625, 0.75, 0.875, 1.0,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1677FF).withOpacity(.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: pillRow,
          ),
        ),
      ),
    );
  }

  /// Opens the P2P offer sheet in seller-counter mode, pre-filled
  /// with the AI-suggested counter computed from the buyer's offer
  /// + the listing's price + the AI rec. Submit dispatches via
  /// [PrivateChatCubit.sendP2PCounter] (intent: 'counter_offer').
  void _openSellerCounterSheet(BuildContext context, int buyerOffer) {
    final listingPrice = _currentListingPrice(context);
    final suggested = _suggestedSellerCounter(buyerOffer, listingPrice, _offerRec);
    // We feed an "AI-counter" recommendation into the sheet so the
    // AI card surfaces the seller-side number rather than the
    // buyer-side one. The reasonShort is regenerated in the sheet's
    // fallback path; we override here to be seller-specific.
    final sellerRec = OfferRecommendation(
      recommended: suggested,
      lowBound: buyerOffer,
      highBound: listingPrice ?? suggested,
      listedPrice: listingPrice ?? 0,
      discountPct: _offerRec?.discountPct ?? 0,
      categoryName: _offerRec?.categoryName ?? 'this category',
      reasonShort:
          'Sellers usually close around ₹${_formatInr(suggested)} when the buyer opens near ₹${_formatInr(buyerOffer)}.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => P2POfferSheet(
        mode: OfferSheetMode.sellerCounter,
        listingPrice: listingPrice,
        buyerOffer: buyerOffer,
        recommendation: sellerRec,
        onSubmit: (amount) {
          try {
            context.read<PrivateChatCubit>().sendP2PCounter(amount);
          } catch (e) {
            debugPrint('P2P counter submit error: $e');
          }
        },
      ),
    );
  }

  /// Opens the P2P offer sheet in buyer-offer mode, seeded with the
  /// cached AI recommendation and the listing's price. On submit,
  /// dispatches via [PrivateChatCubit.sendP2POffer] which sends a
  /// `type: 'text'` message stamped with `intent: 'make_offer'` —
  /// that's the marker the seller-side incoming-offer card looks for.
  void _openP2POfferSheet(BuildContext context) {
    final listingPrice = _currentListingPrice(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => P2POfferSheet(
        mode: OfferSheetMode.buyerOffer,
        listingPrice: listingPrice,
        recommendation: _offerRec,
        onSubmit: (amount) {
          try {
            context.read<PrivateChatCubit>().sendP2POffer(amount);
          } catch (e) {
            debugPrint('P2P offer submit error: $e');
          }
        },
      ),
    );
  }

  /// Two-row coupled-scroll buyer rail.
  Widget _buildBuyerTwoRowRail(BuildContext context) {
    // Lazily build the scroll controllers and wire the coupling.
    // Each controller's listener mirrors the offset onto the other —
    // `_railLock` short-circuits the reverse callback so we don't
    // loop. Same logic as the HTML mockup; the math is identical.
    _p2pTopRailCtrl ??= ScrollController();
    _p2pBotRailCtrl ??= ScrollController();
    _ensureRailCouplingAttached();

    final isDark = ThemeHelper.isDarkMode(context);
    final surface =
        isDark ? const Color(0xFF131826) : const Color(0xFFFFFFFF);
    final lineSoft = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: lineSoft)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero "Make an Offer" pill — sits above both rail rows so
          // the highest-intent buyer action is always one tap away.
          // Renders nothing when the listing has no price set.
          _buildMakeOfferHeroPill(context),
          const SizedBox(height: 8),
          _renderP2PPillRow(
            context,
            P2PPillCatalog.buyerPillsTop,
            controller: _p2pTopRailCtrl!,
          ),
          const SizedBox(height: 8),
          _renderP2PPillRow(
            context,
            P2PPillCatalog.buyerPillsBottom,
            controller: _p2pBotRailCtrl!,
          ),
        ],
      ),
    );
  }

  /// Wire the two rail controllers so each one's scroll is mirrored on
  /// the other. Idempotent — safe to call on every rebuild because
  /// addListener with the same closure is fine (we keep references in
  /// the controllers themselves).
  void _ensureRailCouplingAttached() {
    final top = _p2pTopRailCtrl!;
    final bot = _p2pBotRailCtrl!;

    void mirror(ScrollController src, ScrollController dst) {
      if (_railLock) return;
      if (!src.hasClients || !dst.hasClients) return;
      final srcMax = src.position.maxScrollExtent;
      final dstMax = dst.position.maxScrollExtent;
      if (srcMax <= 0 || dstMax <= 0) return;
      final ratio = (src.offset / srcMax).clamp(0.0, 1.0);
      final target = dstMax * (1 - ratio);
      _railLock = true;
      // jumpTo is synchronous; the dst's listener will fire and short-
      // circuit on _railLock=true.
      dst.jumpTo(target);
      WidgetsBinding.instance.addPostFrameCallback((_) => _railLock = false);
    }

    // Listeners are added at most once per controller — guard with a
    // hasListeners check would be ideal but Flutter doesn't expose
    // that. Instead we rely on the lazy `??=` above so the controllers
    // are created exactly once, and addListener is called exactly once
    // when we first attach below.
    if (!_railCouplingAttached) {
      top.addListener(() => mirror(top, bot));
      bot.addListener(() => mirror(bot, top));
      // First frame: pre-scroll the bottom row to its rightmost end so
      // the parallax is immediately visible on first drag.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (bot.hasClients) {
          final max = bot.position.maxScrollExtent;
          if (max > 0) bot.jumpTo(max);
        }
      });
      _railCouplingAttached = true;
    }
  }

  /// One pill row with a specific controller.
  Widget _renderP2PPillRow(
    BuildContext context,
    List<P2PPill> pills, {
    required ScrollController controller,
  }) {
    if (pills.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _renderP2PChip(context, pills[i]),
      ),
    );
  }

  /// Single-row pill strip (seller side, fewer chips).
  Widget _renderP2PPillStripSingle(
      BuildContext context, List<P2PPill> pills) {
    if (pills.isEmpty) return const SizedBox.shrink();
    final isDark = ThemeHelper.isDarkMode(context);
    final surface =
        isDark ? const Color(0xFF131826) : const Color(0xFFFFFFFF);
    final lineSoft = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFF1F5F9);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: lineSoft)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: pills.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => _renderP2PChip(context, pills[i]),
        ),
      ),
    );
  }

  /// Pill chip with three visual treatments. Neutral chips are
  /// quiet (the default for asks/questions). Primary fills with the
  /// brand colour and reads as "the forward action" — used sparingly
  /// (Deal, Accept). Danger outlines red — used for terminal/
  /// negative actions so the consequence is visible before the tap.
  Widget _renderP2PChip(BuildContext context, P2PPill pill) {
    final isDark = ThemeHelper.isDarkMode(context);

    Color bg, fg, border;
    FontWeight weight;
    switch (pill.style) {
      case PillStyle.primary:
        bg = const Color(0xFF1554B7); // IND blue
        fg = Colors.white;
        border = Colors.transparent;
        weight = FontWeight.w600;
        break;
      case PillStyle.danger:
        bg = Colors.transparent;
        fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
        border = isDark
            ? const Color(0xFFFCA5A5).withOpacity(0.30)
            : const Color(0xFFFECACA);
        weight = FontWeight.w500;
        break;
      case PillStyle.neutral:
        bg = isDark ? const Color(0xFF1B2233) : const Color(0xFFF1F5F9);
        fg = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF0F172A);
        border = isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFE2E8F0);
        weight = FontWeight.w500;
        break;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _onP2PPillTap(context, pill),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            pill.label,
            style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: weight,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  /// Tap handler for P2P pills. Sends the pill's prepared text as a
  /// regular `sendMessage` over the WebSocket, with the pill's intent
  /// id riding along so the receiver-side rail can re-compute.
  void _onP2PPillTap(BuildContext context, P2PPill pill) {
    try {
      context
          .read<PrivateChatCubit>()
          .sendMessage(pill.text, intent: pill.id);
    } catch (e) {
      // Cubit not available shouldn't happen in this code path (chat
      // screen always provides it) but defensively swallow rather
      // than crash the rail.
      debugPrint('P2P pill tap error: $e');
    }
  }

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

        // ── P2P (non-SWA) branch ───────────────────────────────────
        // 2026-05-15: pure-P2P chats now show a quick-reply pill rail
        // on BOTH sides (buyer always, seller contextual). This is a
        // completely separate code path from the SWA logic below — it
        // uses `widgets/P2PPillCatalog.dart` and `PrivateChatCubit`'s
        // generic `sendMessage` (with the optional `intent` arg). SWA
        // paths are untouched.
        //
        // 2026-05-20 — categories on the SWA blocklist (Community,
        // Events, Films, Find Investor) get plain text P2P only. The
        // pill rail's openers ("Make an offer", "Is it available?",
        // "What's the condition?") are nonsensical for community
        // posts or event listings; surface a clean composer instead.
        // The same `swa_category_eligible` flag that gates SWA
        // activation server-side now suppresses the P2P rail too —
        // single source of truth.
        if (convData != null && !convData.isSwa) {
          if (!convData.swaCategoryEligible) return const SizedBox.shrink();
          return _buildP2PPillRail(context, convData);
        }

        // Pure-P2P thread → rail stays hidden. No SWA chrome at all.
        if (convData == null || !convData.isSwa) {
          return const SizedBox.shrink();
        }

        // Seller's view — pills are buyer-only. The seller manages the
        // conversation through the SWA Dashboard (Accept / Counter /
        // Decline / Message buttons) or, if they open this thread from
        // their regular chat list, through the plain text composer
        // (which triggers implicit seller_takeover on the next message).
        if (convData.viewerIsSeller) {
          return const SizedBox.shrink();
        }

        // Post-takeover view — once the seller has typed even one
        // message on this conversation, the gateway flips it to
        // `seller_takeover` and AI auto-replies stop forever for this
        // thread. From the buyer's POV the rail no longer makes sense:
        // any pill they tap would NOT get an AI response (the AI is
        // silent in seller_takeover), and we want them in plain P2P
        // chat to finalize the deal. Hiding the rail + showing the
        // composer (see _buildComposerArea) gives them the 1:1 chat
        // they earned by getting the seller to engage.
        if (convData.isSellerTakeover) {
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
        // Phase 2 spam-lowball cooldown — hide the rail while the
        // 48h pause is in effect. The "Chat paused" banner already
        // replaces the composer; showing pills on top would be a
        // confusing dead end (taps would 429 with cooldown error).
        // Once the cooldown elapses, the rail comes back and the
        // first tap implicitly resets the conversation server-side.
        if (convData.isSpamLowballCooldown) return const SizedBox.shrink();
        // Phase 2 post-deal guard — when the AI just auto-accepted an
        // offer, the conversation is in a 15-min cooling-off window
        // before the seller confirms / auto-promotes. Re-tapping
        // pills here makes no sense (the deal IS the deal); the
        // backend would 409 every offer attempt. Composer stays open
        // so buyer can text seller about pickup. Conversation auto-
        // resets to `active` if the seller cancels the pending deal,
        // so the rail comes back automatically in that case.
        if (convData.isPendingAcceptance) return const SizedBox.shrink();
        // Generic 'closed' guard — covers buyer_rejected and any
        // other future expiry_reason that isn't spam_lowball.
        // spam_lowball is already caught above with its bespoke
        // banner; this is the catch-all for the rest.
        if (convData.conversationStatus == 'closed') return const SizedBox.shrink();

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
        return BlocConsumer<PrivateChatCubit, PrivateChatState>(
          // Re-enable the pill rail the instant the AI's response
          // arrives via WebSocket — don't wait for the defensive
          // timeout. Two filters on listenWhen:
          //   1) messages grew (skip typing-indicator no-op churn)
          //   2) the NEWEST message is NOT from the buyer themselves
          //
          // Filter (2) is critical. PrivateChatCubit.sendPillTap()
          // optimistically adds the buyer's own message to state
          // BEFORE the WS round-trip completes, so without this guard
          // the listener would fire on the local echo and re-enable
          // the rail ~instantly — defeating the whole double-tap
          // safeguard. We want the rail to stay locked until the AI's
          // response actually arrives (sender != 'buyer').
          listenWhen: (prev, curr) {
            if (curr.messages.length <= prev.messages.length) return false;
            final newest = curr.messages.isNotEmpty
                ? curr.messages.last
                : null;
            return newest != null && newest.sender != 'buyer';
          },
          listener: (context, _) {
            if (_isPillSending && mounted) {
              setState(() => _isPillSending = false);
            }
          },
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
            // 2026-05-17 — wire onMakeOffer so the rewritten
            // SwaPillRail surfaces a hero "Make an Offer" pill above
            // the two rail rows whenever the backend includes
            // `make_offer` in `follow_up_pills`. Tap routes through
            // the existing _openOfferSheet (mode-aware: AI-structured
            // offer in pills_only / keyword_chat, plain-text "My
            // offer: ₹X" in P2P / seller-takeover modes).
            return SwaPillRail(
              pillIds: pills,
              enabled: !_isPillSending,
              onTap: (pillId) => _onPillTap(context, pillId),
              onMakeOffer: () => _openOfferSheet(context),
            );
          },
        );
      },
    );
  }

  /// Opens the buyer-side offer sheet for an SWA conversation.
  ///
  /// 2026-05-17 — upgraded from the basic [SwaOfferSheet] (single
  /// numeric input) to the full [P2POfferSheet]: AI-recommendation
  /// card (one-tap "Use AI suggestion"), three quick-pick price
  /// chips, custom-amount input, and the sliding-sheen pill CTA. Same
  /// AI recommendation source as the P2P flow — `_offerRec`, pre-
  /// fetched on chat open from `/app/get-offer-recommendation/:id`.
  ///
  /// Submit handler stays MODE-AWARE:
  ///   • AI-backed modes (pills_only / keyword_chat) → structured
  ///     `sendOffer(amount)` WS message the SWA pipeline scores
  ///     against the seller's floor + expected price.
  ///   • Human modes (p2p / seller_takeover) → plain-text "My offer:
  ///     ₹X" message the seller negotiates in their own words.
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
      builder: (_) => P2POfferSheet(
        mode: OfferSheetMode.buyerOffer,
        listingPrice: listingPrice,
        recommendation: _offerRec,
        // The UI is the new P2POfferSheet (AI recommendation card +
        // chips + custom input), but the on-submit dispatch is the
        // SAME as the legacy SWA make_offer pill — mode-aware:
        //
        //   • AI-backed modes (pills_only / keyword_chat) → call
        //     `sendOffer(amount)`. This emits a structured
        //     `type:'offer'` WS message that handleSWAMessage routes
        //     into the SWA pipeline (ladder scoring → accept /
        //     counter / decline, deal notifications, etc.). DO NOT
        //     replace this with `sendP2POffer` — that would emit
        //     `type:'text'` which the SWA gateway rejects in
        //     pills_only mode ("Seller is responding only via quick
        //     replies…").
        //
        //   • Human modes (p2p / seller_takeover) → send as plain
        //     text "My offer: ₹X" via `sendMessage`. Seller has opted
        //     out of AI handling; we honour that by letting them
        //     negotiate manually.
        //
        // Think of this widget as "the legacy make_offer pill, with
        // AI-recommendation UI bolted on" — wire contract unchanged.
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

      // Defensive fallback: 10 sec. The BlocConsumer's listener on
      // PrivateChatCubit clears the lock the instant the AI's
      // response actually arrives (filtered to ignore the buyer's
      // own local echo), so on warm requests the buyer sees the
      // rail re-enable in ~200ms. This timeout is the safety net
      // for the path where the WS response never arrives at all
      // (network drop, server crash, etc.) — long enough that we
      // never unlock prematurely on a slow Atlas / cold-start
      // round-trip, short enough that a truly stuck rail eventually
      // recovers without an app restart.
      // History: 10s (initial) → 800ms → 3000ms → 10s. The earlier
      // shrinks tried to compensate for the listener firing on the
      // buyer's local echo (since fixed); with the proper sender
      // filter the listener handles the happy path and 10s is the
      // appropriate ceiling.
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

  /// Drives viewer-aware copy. The seller_takeover + pending_acceptance
  /// banners read differently depending on who's looking — sellers see
  /// "buyer-side" framings (e.g. "Buyer's offer is pending your
  /// confirmation") while buyers see "seller-side" framings ("Waiting
  /// for the seller to confirm…"). Defaults to false (buyer view).
  final bool viewerIsSeller;

  const _SwaStatusBanner({
    required this.status,
    this.expiresAt,
    this.agreedPrice,
    this.viewerIsSeller = false,
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
      viewerIsSeller: widget.viewerIsSeller,
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
  ///
  /// 2026-05-17 — `viewerIsSeller` swaps the framing for the two
  /// statuses that read awkwardly when the wrong side sees buyer-
  /// authored copy: `seller_takeover` (seller doesn't need to be
  /// told "the seller is handling this") and `pending_acceptance`
  /// (seller never made "their offer" — buyer did).
  static _BannerCopy? _copyFor(
    String? s, {
    DateTime? expiresAt,
    int? agreedPrice,
    bool viewerIsSeller = false,
  }) {
    switch (s) {
      case 'seller_takeover':
        return _BannerCopy(
          title: viewerIsSeller
              ? "You're handling this conversation"
              : 'Seller is handling this conversation',
          subtitle: viewerIsSeller
              ? 'Smart Assist has paused for this buyer.'
              : 'Smart Assist has paused — messages go directly to the seller.',
          icon: Icons.pause_circle_outline_rounded,
          tone: _BannerTone.info,
        );
      // SIMPLIFIED FLOW (2026-05-19): the AI no longer moves a
      // conversation into `pending_acceptance`. Backend never emits
      // this status anymore for new flows, so the banner case is
      // disabled. Kept here (commented) so the change can be reverted
      // cleanly if we re-enable cooling-off later.
      // case 'pending_acceptance':
      //   return _BannerCopy(
      //     title: viewerIsSeller
      //         ? "Buyer's offer is pending your confirmation"
      //         : 'Your offer is in',
      //     subtitle: _pendingSubtitle(expiresAt, viewerIsSeller: viewerIsSeller),
      //     icon: Icons.hourglass_top_rounded,
      //     tone: _BannerTone.pending,
      //   );
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

  /// Live countdown for the pending-acceptance window. Subtitle copy
  /// swaps based on viewer: buyer sees "waiting for the seller…",
  /// seller sees "confirm within X min to lock the deal".
  static String _pendingSubtitle(
    DateTime? expiresAt, {
    bool viewerIsSeller = false,
  }) {
    if (expiresAt == null) {
      return viewerIsSeller
          ? 'Confirm to lock the deal.'
          : 'Waiting for the seller to confirm.';
    }
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    if (diff.inSeconds <= 0) {
      return viewerIsSeller
          ? 'Cooling-off ended — finalising the deal…'
          : 'Finalising with the seller...';
    }
    if (diff.inSeconds < 60) {
      return viewerIsSeller
          ? 'Confirm now — cooling-off ends in seconds.'
          : 'Waiting for the seller to confirm — any moment now.';
    }
    final mins = diff.inMinutes + (diff.inSeconds % 60 >= 30 ? 1 : 0);
    return viewerIsSeller
        ? 'Confirm within $mins min to lock the deal.'
        : 'Waiting for the seller to confirm — $mins min left.';
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
