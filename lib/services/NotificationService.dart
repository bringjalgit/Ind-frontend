import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../data/cubit/Notifications/notifications_cubit.dart';
import '../utils/AppLogger.dart';
import '../utils/NotificationIntent.dart';
import '../utils/constants.dart';
import 'ApiClient.dart';
import 'FcmTokenManager.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  // -------------------- INIT --------------------

  Future<void> initialize() async {
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _handleColdStartLaunch();
    await _configureForegroundPresentation();
    _setupFirebaseListeners();
    // Subscribe to OS-initiated FCM token rotation. The backend now
    // exposes POST /app/register-fcm-token (authenticated, idempotent)
    // so we wire the refreshed token straight there — no fresh login
    // required. Without this, a rotated token (iOS does it regularly,
    // Android less often, plus GMS updates / Clear-data / reinstall)
    // would silently render the user unreachable until they re-logged.
    FcmTokenManager.startAutoRefresh(
      onRefresh: (newToken) {
        // Fire-and-forget — ApiClient swallows errors and the next
        // cold start / rotation will retry anyway.
        ApiClient.registerFcmToken(newToken);
      },
    );

    // Cold-start sync. Covers two leak paths:
    //   • Users whose server-side fcm_token went stale because
    //     onTokenRefresh fired before this listener was wired
    //     (i.e., older app versions that didn't have a register-
    //     fcm-token endpoint).
    //   • Users whose original /verify-otp call landed with a null
    //     fcm_token because Firebase hadn't provisioned by then —
    //     ensureFcmToken now waits up to 8s with retry, and the
    //     result is posted to the backend on each launch.
    // Fire-and-forget; never blocks app initialization.
    // ignore: unawaited_futures
    _coldStartRegisterFcmToken();
  }

  Future<void> _coldStartRegisterFcmToken() async {
    try {
      final token = await FcmTokenManager.ensureFcmToken();
      if (token != null && token.isNotEmpty) {
        await ApiClient.registerFcmToken(token);
      }
    } catch (e) {
      AppLogger.error('[fcm] cold-start register failed: $e');
    }
  }

  // -------------------- PERMISSIONS --------------------

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else if (Platform.isAndroid) {
      final plugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await plugin?.requestNotificationsPermission();
    }
  }

  Future<void> _configureForegroundPresentation() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // -------------------- LOCAL NOTIFICATIONS --------------------

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload?.isNotEmpty == true) {
          final data = jsonDecode(payload!) as Map<String, dynamic>;
          _navigateFromPushData(data);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  // -------------------- COLD-START LAUNCH --------------------

  /// Handle the case where tapping a notification launched the app from a
  /// fully-closed state.
  ///
  /// Our pushes are data-only and rendered as LOCAL notifications, so a
  /// cold-start tap is delivered neither by
  /// `onDidReceiveNotificationResponse` (only fires while the isolate is
  /// already alive) nor by `FirebaseMessaging.getInitialMessage` (only
  /// covers FCM-DISPLAYED notification messages). It lives in the plugin's
  /// launch details. Without reading it here, a closed-app notification
  /// tap dropped the user on Home instead of the chat — the "sometimes
  /// chat, sometimes home" bug.
  ///
  /// There's no UI yet at this point, so `_navigateFromPushData` stashes a
  /// pending intent (NotificationIntent) that Dashboard.initState consumes
  /// once the router is up.
  Future<void> _handleColdStartLaunch() async {
    try {
      final details =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return;
      final payload = details!.notificationResponse?.payload;
      if (payload == null || payload.isEmpty) return;
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromPushData(data);
    } catch (_) {
      // Best-effort — never block startup on a malformed payload.
    }
  }

  // -------------------- FIREBASE LISTENERS --------------------

  void _setupFirebaseListeners() {
    // Foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background → Tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromPushData(message.data);
    });

    // Terminated → Tap
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateFromPushData(message.data);
        });
      }
    });
  }

  // -------------------- MESSAGE HANDLERS --------------------

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint("📥 🔔 Foreground message received");
    debugPrint(message.toMap().toString());

    // App is in the FOREGROUND → show an in-app heads-up banner (Flushbar)
    // for ALL types, instead of an OS notification. Chat used to be fully
    // suppressed here, but the backend already skips the chat push when the
    // user is actively viewing that exact thread — so any chat push that
    // reaches us is for a thread they're NOT looking at, worth a banner. The
    // OS notification still shows when backgrounded (background handler).
    final title =
        (message.data['title'] ?? message.notification?.title)?.toString() ?? '';
    final body =
        (message.data['body'] ?? message.notification?.body)?.toString() ?? '';

    if (title.isNotEmpty) {
      _showInAppBanner(title, body, message.data);
    }

    // Keep the launcher app-icon badge in sync with the server's unified count.
    refreshAppBadge();

    // Refresh the IN-APP notification inbox so the bell badge updates the
    // instant a foreground push arrives — not only on app-resume/cold-start.
    // Production apps bump the count live. navigatorKey sits above the bloc
    // providers, so this reaches the global NotificationsCubit.
    try {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) ctx.read<NotificationsCubit>().getNotifications();
    } catch (_) {}
  }

  // -------------------- IN-APP BANNER (FOREGROUND) --------------------

  /// Heads-up banner shown over the app when a push arrives while foreground.
  /// Tapping it routes via the same _navigateFromPushData used for taps.
  void _showInAppBanner(String title, String body, Map<String, dynamic> data) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return; // no UI yet (cold start) — nothing to show on
    Flushbar(
      title: title,
      message: body.isNotEmpty ? body : ' ',
      duration: const Duration(seconds: 4),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: const Color(0xFF1F2733),
      leftBarIndicatorColor: const Color(0xFF22C55E),
      icon: const Icon(Icons.notifications_active, color: Colors.white),
      isDismissible: true,
      onTap: (_) => _navigateFromPushData(data),
    ).show(ctx);
  }

  // -------------------- APP-ICON BADGE --------------------

  /// Refresh the launcher app-icon badge from the server's UNIFIED unread
  /// count (inbox + chat). Safe to call on push receipt, app resume, and
  /// after mark-read. No-op where the launcher doesn't support badges.
  Future<void> refreshAppBadge() async {
    try {
      if (!await AppBadgePlus.isSupported()) return;
      final count = await ApiClient.getUnreadNotificationCount();
      AppBadgePlus.updateBadge(count); // 0 clears the badge
    } catch (e) {
      AppLogger.error('[badge] refresh failed: $e');
    }
  }

  // -------------------- SHOW NOTIFICATION FROM DATA PAYLOAD --------------------

  Future<void> showDataNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final imageUrl = data['image']?.toString();
    BigPictureStyleInformation? style;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final path = await _downloadAndSaveFile(imageUrl, 'bigPicture.jpg');
        style = BigPictureStyleInformation(
          FilePathAndroidBitmap(path),
          contentTitle: title,
          summaryText: body,
        );
      } catch (e) {
        debugPrint('❌ Image download failed: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: style,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: _generateNotificationId(data),
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(data),
    );
  }

  // -------------------- SHOW NOTIFICATION --------------------

  Future<void> showNotification(
    RemoteNotification notification,
    AndroidNotification android,
    Map<String, dynamic> data,
  ) async {
    String? imageUrl =
        notification.android?.imageUrl ??
        notification.apple?.imageUrl ??
        data['image'] as String?;

    BigPictureStyleInformation? style;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final path = await _downloadAndSaveFile(imageUrl, 'bigPicture.jpg');
        style = BigPictureStyleInformation(
          FilePathAndroidBitmap(path),
          contentTitle: notification.title,
          summaryText: notification.body,
        );
      } catch (e) {
        debugPrint('❌ Image download failed: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: style,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: _generateNotificationId(data),
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(data),
    );
  }

  // -------------------- NAVIGATION --------------------

  void _navigateFromPushData(Map<String, dynamic> data) {
    // Listing moderation result (approved / rejected) — backend sends
    // `type: 'listing_status'` with a listing_id but NO receiverId, so
    // it must route to My Ads (dashboard tab 1), not chat. Without this
    // branch the chat-routing below bails out early (no receiverId) and
    // the app just opens to Home.
    // Detect a listing-moderation result robustly. The backend *should*
    // send type:'listing_status', but we also accept a moderation `status`
    // (approved/rejected/pending/expired) or an approval/rejection title,
    // so an approval push can never fall through to the chat-routing below
    // (which was sending these to ChatScreen on some builds).
    final pushType = (data['type'] ?? data['fcmType'])?.toString();
    final modStatus =
        (data['status'] ?? data['listing_status'])?.toString().toLowerCase();
    final titleLc = (data['title'] ?? '').toString().toLowerCase();
    final isListingResult = pushType == 'listing_status' ||
        (modStatus != null &&
            const ['approved', 'rejected', 'pending', 'expired']
                .contains(modStatus)) ||
        titleLc.contains('listing approved') ||
        titleLc.contains('listing rejected') ||
        titleLc.contains('under review');
    if (isListingResult) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        // go() (not push()) so it lands on the dashboard's My Ads tab;
        // Dashboard.didUpdateWidget honors the new ?tab= even when the
        // dashboard is already alive.
        GoRouter.of(ctx).go('/dashboard?tab=1');
      } else {
        // Cold start — stash; Dashboard.initState consumes it.
        NotificationIntent.setPendingTab(1);
      }
      return;
    }

    // The notification's "other party" is the senderId (whoever sent
    // the chat message). From the receiver-of-the-notification's POV
    // that user is the chat's `receiverId` — match the keys the
    // backend [messaging.js sendChatNotification](handler/chat/messaging.js)
    // emits + a few legacy aliases.
    // The notification recipient (seller, in the SWA case) wants to land
    // on a chat with the OTHER party. For P2P chat notifications the
    // "other party" is `senderId` (whoever sent the chat). For SWA
    // `offer_forwarded` notifications the backend sends `buyer_id` —
    // the buyer is the other party from the seller's POV. Both shapes
    // resolve to the same `/chat?receiverId=...` URL, so we accept
    // either key and route to ChatScreen (NOT the SWA dashboard).
    final receiverId =
        (data['senderId'] ??
                data['sender_id'] ??
                data['receiverId'] ??
                data['receiver_id'] ??
                data['buyer_id'] ??
                data['rid'])
            ?.toString();

    // listingId is required — chats are scoped to (listing, peer)
    // pairs. Without it the /chat route falls back to "0" and the
    // PrivateChatCubit can't load any messages.
    final listingId =
        (data['listingId'] ?? data['listing_id'])?.toString();

    final listingTitle =
        (data['listingTitle'] ?? data['listing_title'])?.toString();

    if (receiverId == null || receiverId.isEmpty) return;
    if (listingId == null || listingId.isEmpty) return;

    final query = StringBuffer('/chat?receiverId=$receiverId&listingId=$listingId');
    if (listingTitle != null && listingTitle.isNotEmpty) {
      query.write('&listingTitle=${Uri.encodeComponent(listingTitle)}');
    }

    final ctx = navigatorKey.currentContext;

    // If the app's UI is up, push /chat directly on top of whatever
    // the user is currently on. We previously gated this on
    // `canPop()`, but `canPop()` returns false when the user is
    // sitting on Dashboard (the root) — and `go('/')` to the same
    // route is a no-op, so the pending intent never got consumed and
    // the user stayed on home. Push always works (chat sits on top
    // of dashboard / chat list / wherever).
    if (ctx != null) {
      GoRouter.of(ctx).push(query.toString());
      return;
    }

    // No context → app hasn't finished booting (cold start from
    // notification tap). Stash the intent; Dashboard.initState picks
    // it up via the post-frame callback once the router is ready.
    NotificationIntent.setPendingChat(
      receiverId: receiverId,
      listingId: listingId,
      listingTitle: listingTitle,
    );
  }

  // -------------------- HELPERS --------------------

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  /// Stable local-notification id (Android requires a 31-bit int). Prefer the
  /// backend's notification_id, then the FCM messageId, else a rolling
  /// counter — replaces the old `remainder(100000)` / `hashCode` schemes that
  /// collided and silently overwrote notifications.
  int _idCounter = 0;
  int _generateNotificationId(Map<String, dynamic> data) {
    final stable = (data['notification_id'] ??
            data['notificationId'] ??
            data['messageId'])
        ?.toString();
    if (stable != null && stable.isNotEmpty) {
      return stable.hashCode & 0x7fffffff; // positive 31-bit
    }
    _idCounter = (_idCounter + 1) & 0x7fffffff;
    return _idCounter;
  }

  // ✅ THIS MUST EXIST
  Future<void> requestPermissions() async {
    await _requestPermissions();
  }
}
