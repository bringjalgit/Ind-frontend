import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:classifieds/utils/AppLogger.dart';

/// BackendResolver — picks which backend (Lambda main stack or EC2 mirror)
/// the app should hit for main-stack endpoints.
///
/// Architecture:
///   - Lambda main stack and EC2 mirror serve the SAME endpoints; only one
///     is active at a time, gated by `active_backend` in MongoDB AppConfig.
///   - The Lambda chat stack (chat REST + WebSocket + app-config + delete/
///     recovery account) is permanently on Lambda — never resolved.
///   - JWTs are signed with the same secret on both backends, so a token
///     issued by one works on the other; backend switches mid-session are
///     invisible to the user.
///
/// How it picks:
///   1. On startup, hydrate `currentBaseUrl` from SharedPreferences cache
///      so the very first request uses the last known good backend.
///   2. Then probe `/health` (3s timeout) — first Lambda, then EC2 if
///      Lambda is unreachable. The response carries `active_backend`.
///   3. If both probes fail, keep the cached value (or default to Lambda
///      on first launch).
///
/// On 503 BACKEND_DORMANT mid-session, ApiClient calls [reresolve] and
/// retries the request once with the new base URL. This handles admin-
/// triggered switchovers without forcing the user to restart.
class BackendResolver {
  // ── Base URLs (compile-time constants) ───────────────────────────────────
  // Update _ec2BaseUrl with the production hostname after the EC2 elastic IP
  // is mapped to a domain (e.g. https://api2.indclassifieds.in/app/). Until
  // then this placeholder is harmless because EC2 is dormant in production.
  static const String lambdaBaseUrl =
      'https://tn7v9gtczd.execute-api.ap-south-1.amazonaws.com/dev/app/';
  static const String ec2BaseUrl =
      'https://remedios-unprecocious-gaynell.ngrok-free.dev/app/'; // ⚠️ ngrok for testing — replace with real domain before production deploy

  // ── Cache + timing ───────────────────────────────────────────────────────
  static const String _cacheKey = 'backend_resolver_choice';
  static const String _cacheTimeKey = 'backend_resolver_choice_time';
  static const Duration _cacheTtl = Duration(hours: 24);
  static const Duration _healthTimeout = Duration(seconds: 3);

  // ── Runtime state ────────────────────────────────────────────────────────
  static String _currentBaseUrl = lambdaBaseUrl;
  static bool _initialized = false;

  /// The base URL every main-stack endpoint should be built on top of.
  /// Used by `api_endpoint_urls.dart` getters and by ApiClient retry.
  static String get currentBaseUrl => _currentBaseUrl;

  static bool get isUsingEc2 => _currentBaseUrl == ec2BaseUrl;
  static bool get isUsingLambda => _currentBaseUrl == lambdaBaseUrl;
  static bool get isInitialized => _initialized;

  /// Call once at app startup, before `runApp`. Hydrates the cached choice
  /// and runs a /health probe to refresh it. Total worst case: ~3 seconds.
  static Future<void> initialize() async {
    // Step 1: hydrate cache so the very first API call has a sensible target
    final cached = await _getCachedChoice();
    if (cached != null) {
      _currentBaseUrl = cached;
      AppLogger.log('[BackendResolver] hydrated cache → $cached');
    }

    // Step 2: probe to refresh — won't block if cache was hydrated
    try {
      final probed = await _probeBackend();
      if (probed != null) {
        if (probed != _currentBaseUrl) {
          AppLogger.log('[BackendResolver] probe switched: $_currentBaseUrl → $probed');
        }
        _currentBaseUrl = probed;
        await _saveChoice(probed);
      } else {
        AppLogger.log('[BackendResolver] probe failed on both backends, keeping $_currentBaseUrl');
      }
    } catch (e) {
      AppLogger.error('[BackendResolver] probe error: $e');
    }

    _initialized = true;
  }

  /// Force a fresh /health probe. Called by ApiClient on 503 BACKEND_DORMANT
  /// so a request that hit the wrong backend can be auto-retried.
  static Future<void> reresolve() async {
    try {
      final probed = await _probeBackend();
      if (probed != null) {
        if (probed != _currentBaseUrl) {
          AppLogger.log('[BackendResolver] reresolve switched: $_currentBaseUrl → $probed');
        }
        _currentBaseUrl = probed;
        await _saveChoice(probed);
      }
    } catch (e) {
      AppLogger.error('[BackendResolver] reresolve error: $e');
    }
  }

  // ── private ──────────────────────────────────────────────────────────────

  /// Probes /health on Lambda first, then EC2 as a fallback. Returns the
  /// base URL that matches the `active_backend` field in the response, or
  /// null if both probes failed.
  static Future<String?> _probeBackend() async {
    final fromLambda = await _readHealth(lambdaBaseUrl);
    if (fromLambda != null) {
      return fromLambda == 'ec2' ? ec2BaseUrl : lambdaBaseUrl;
    }
    final fromEc2 = await _readHealth(ec2BaseUrl);
    if (fromEc2 != null) {
      return fromEc2 == 'ec2' ? ec2BaseUrl : lambdaBaseUrl;
    }
    return null;
  }

  /// Calls `<root>/health` (with /app stripped) and returns the
  /// `active_backend` string from the response, or null on failure.
  static Future<String?> _readHealth(String baseUrl) async {
    try {
      final root = baseUrl.replaceAll(RegExp(r'/app/?$'), '');
      final dio = Dio(BaseOptions(
        connectTimeout: _healthTimeout,
        receiveTimeout: _healthTimeout,
      ));
      final res = await dio.get('$root/health');
      if (res.statusCode == 200 && res.data is Map) {
        final active = res.data['active_backend']?.toString();
        if (active == 'lambda' || active == 'ec2') return active;
      }
    } catch (_) {
      // swallow — caller decides whether to fall back
    }
    return null;
  }

  static Future<String?> _getCachedChoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getInt(_cacheTimeKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - t;
      if (age > _cacheTtl.inMilliseconds) return null;
      final url = prefs.getString(_cacheKey);
      // Sanity-check: only return one of the two known base URLs
      if (url == lambdaBaseUrl || url == ec2BaseUrl) return url;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveChoice(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, url);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}
