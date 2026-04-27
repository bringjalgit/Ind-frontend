import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/NotificationIntent.dart';
import '../utils/constants.dart';
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
    await _configureForegroundPresentation();
    _setupFirebaseListeners();
    // Subscribe to OS-initiated FCM token rotation. Without this, a
    // rotated token (iOS does this regularly; Android less often) is
    // never resynced — the backend keeps sending pushes to the dead
    // old token and everything silently drops. For now the refreshed
    // token is only cached in [FcmTokenManager.lastToken]; a future
    // step will add a POST /app/device-token endpoint so the new
    // token lands on the User row without requiring a fresh login.
    FcmTokenManager.startAutoRefresh();
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

    // Suppress OS popup for chat messages while app is in foreground —
    // the WebSocket already pushes the new message + unread count to the
    // chat list cubit, which updates the badge in real time.
    final type = message.data['type']?.toString();
    if (type == 'chat_message') {
      return;
    }

    // Data-only payload (preferred — prevents duplicate notifications)
    final title = message.data['title']?.toString();
    final body = message.data['body']?.toString();

    if (title != null && title.isNotEmpty) {
      showDataNotification(title, body ?? '', message.data);
      return;
    }

    // Fallback: legacy notification payload
    final notification = message.notification;
    final android = notification?.android;
    if (notification != null && android != null) {
      showNotification(notification, android, message.data);
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
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
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
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(data),
    );
  }

  // -------------------- NAVIGATION --------------------

  void _navigateFromPushData(Map<String, dynamic> data) {
    final receiverId =
        (data['receiverId'] ??
                data['receiver_id'] ??
                data['senderId'] ??
                data['rid'])
            ?.toString();

    if (receiverId == null || receiverId.isEmpty) return;

    final ctx = navigatorKey.currentContext;

    if (ctx != null && GoRouter.of(ctx).canPop()) {
      GoRouter.of(ctx).push('/chat?receiverId=$receiverId');
    } else {
      NotificationIntent.setPendingChat(receiverId);
      GoRouter.of(navigatorKey.currentContext!).go('/');
    }
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

  // ✅ THIS MUST EXIST
  Future<void> requestPermissions() async {
    await _requestPermissions();
  }
}
