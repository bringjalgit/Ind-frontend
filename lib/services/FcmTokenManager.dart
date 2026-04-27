import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/AppLogger.dart';

/// Centralized Firebase Cloud Messaging token lifecycle manager.
///
/// Every login / registration path must call [ensureFcmToken] right
/// before dispatching its verify request — that's the moment the
/// backend is about to create or update the User document, and it's
/// the one place the token can be cheaply persisted server-side.
///
/// The old pattern (`FirebaseMessaging.instance.getToken()` inline) had
/// three silent failure modes that caused push notifications to never
/// deliver:
///   1. `getToken()` returns null if APNs/FCM provisioning hasn't
///      completed — common on the very first launch after install.
///      The old code had no retry.
///   2. On Android 13+, `getToken()` returns a token even when the OS
///      has denied notification permission. The app would happily log
///      in with a token the OS later refuses to deliver to.
///   3. `onTokenRefresh` — the OS-initiated rotation — was never
///      subscribed, so once the token changed the backend kept the
///      stale one forever.
///
/// This manager handles all three.
///
/// Behaviour:
///   • [ensureFcmToken] requests permission (platform-appropriate),
///     calls `getToken()` with a 3-second timeout, retries once if
///     null, returns null if both attempts fail. Never throws.
///   • [startAutoRefresh] subscribes to `onTokenRefresh`, caches the
///     latest token, and invokes an optional callback so callers can
///     persist the new token. When no callback is passed, the token
///     is still cached in memory for the next login.
///   • [lastToken] returns the most recently observed token (from
///     ensure or refresh) — useful for a post-login sync endpoint.
class FcmTokenManager {
  FcmTokenManager._();

  static String? _lastToken;

  /// Fetch a usable FCM token, requesting notification permission if
  /// necessary. Returns null on denied permission, provisioning
  /// timeouts, or web (where FCM web is not configured). Callers
  /// should treat null as "send login without fcm_token" — logins
  /// must never be blocked on notification permission.
  static Future<String?> ensureFcmToken() async {
    if (kIsWeb) return null;

    try {
      // ── Permission ────────────────────────────────────────────────
      // iOS uses Firebase's native permission modal. Android 13+ uses
      // the POST_NOTIFICATIONS runtime permission (surfaced via the
      // local-notifications plugin). Older Android: no-op (implicit
      // grant).
      if (Platform.isIOS) {
        final settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          AppLogger.info('[fcm] permission denied by user');
          return null;
        }
      } else if (Platform.isAndroid) {
        final plugin = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await plugin?.requestNotificationsPermission();
      }

      // ── Token fetch with timeout + one retry ──────────────────────
      // First attempt: 3s. Fast path for warm installs.
      String? token =
          await _getTokenWithTimeout(const Duration(seconds: 3));
      if (_isUsable(token)) {
        _lastToken = token;
        return token;
      }

      // Retry: 5s window after a short breather. On a cold install
      // the provisioner typically resolves within ~1-2s after the
      // first null return.
      await Future.delayed(const Duration(milliseconds: 500));
      token = await _getTokenWithTimeout(const Duration(seconds: 5));
      if (_isUsable(token)) {
        _lastToken = token;
        return token;
      }

      AppLogger.info(
        '[fcm] getToken returned null after retry — user may have denied permission '
        'or provisioning is still pending',
      );
      return null;
    } catch (e) {
      // Never propagate FCM errors into the login path.
      AppLogger.error('[fcm] ensureFcmToken failed: $e');
      return null;
    }
  }

  /// Subscribe to OS-initiated token rotation. Should be called once,
  /// at app start, after Firebase is initialized. The optional
  /// [onRefresh] callback receives the new token — wire it to a
  /// backend "update device token" endpoint when one is available.
  /// Without a callback, the new token is still cached in [lastToken]
  /// so the next login picks it up.
  static void startAutoRefresh({
    void Function(String newToken)? onRefresh,
  }) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (!_isUsable(newToken)) return;
      if (_lastToken == newToken) return;
      _lastToken = newToken;
      AppLogger.info('[fcm] token refreshed');
      if (onRefresh != null) {
        try {
          onRefresh(newToken);
        } catch (e) {
          AppLogger.error('[fcm] onRefresh callback threw: $e');
        }
      }
    });
  }

  /// Most recently observed token. Null before [ensureFcmToken] has
  /// resolved successfully. Read by post-login sync paths.
  static String? get lastToken => _lastToken;

  // ── Internals ──────────────────────────────────────────────────────

  static Future<String?> _getTokenWithTimeout(Duration timeout) async {
    try {
      return await FirebaseMessaging.instance.getToken().timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  static bool _isUsable(String? t) => t != null && t.isNotEmpty;
}
