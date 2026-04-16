import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:classifieds/model/AppConfigModel.dart';
import 'package:classifieds/services/api_endpoint_urls.dart';
import 'package:classifieds/utils/AppLogger.dart';
import 'package:classifieds/utils/VersionUtils.dart';

class AppConfigService {
  static AppConfigModel? _config;
  static String _currentVersion = '1.0.0';

  static const _cacheKey = 'app_config_cache';
  static const _cacheTimeKey = 'app_config_cache_time';
  static const _cacheTtlMinutes = 60; // 1 hour

  /// Fetch config from API. Always tries fresh data first because
  /// force-update and maintenance checks must never use stale cache —
  /// an admin flipping maintenance ON must block users on their very
  /// next app launch, not after a 1-hour cache expires.
  ///
  /// Flow:
  ///   1. Try API (3s timeout) → use fresh data, update cache
  ///   2. If API fails → fall back to cache (stale is better than nothing)
  ///   3. If no cache either → use safe defaults
  static Future<AppConfigModel> fetch() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // Always try fresh API data first (3s timeout is acceptable on splash)
      final fresh = await _fetchFromApi();
      if (fresh != null) {
        _config = fresh;
        return fresh;
      }

      // API failed — fall back to cache
      final cached = await _getCached();
      if (cached != null) {
        _config = cached;
        AppLogger.log('AppConfigService: API unreachable, using cache');
        return cached;
      }
    } catch (e) {
      AppLogger.error('AppConfigService.fetch error: $e');
    }

    // Fallback to defaults
    _config = AppConfigModel.defaults();
    return _config!;
  }

  static Future<AppConfigModel?> _fetchFromApi() async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)));
      final response = await dio.get('${APIEndpointUrls.chatLambdaUrl}app-config');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        final config = AppConfigModel.fromJson(data);
        await _saveCache(data);
        return config;
      }
    } catch (e) {
      AppLogger.error('AppConfigService API error: $e');
    }
    return null;
  }

  static Future<void> _saveCache(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<AppConfigModel?> _getCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - cacheTime;

      if (age > _cacheTtlMinutes * 60 * 1000) return null; // Expired

      final json = prefs.getString(_cacheKey);
      if (json != null) {
        return AppConfigModel.fromJson(jsonDecode(json));
      }
    } catch (_) {}
    return null;
  }

  // ─── Getters ───────────────────────────────────────────────────────

  static AppConfigModel get config => _config ?? AppConfigModel.defaults();
  static String get currentVersion => _currentVersion;

  static bool get isMaintenanceActive => config.maintenance.isActive;
  static String get maintenanceMessage => config.maintenance.message;

  static bool get needsForceUpdate =>
      VersionUtils.needsForceUpdate(_currentVersion, config.platform.minSupportedVersion);

  static bool get hasOptionalUpdate =>
      !needsForceUpdate && VersionUtils.hasOptionalUpdate(_currentVersion, config.platform.latestVersion);

  static bool get forceUpdateFlag => config.platform.forceUpdate;
  static String get updateMessage => config.platform.updateMessage;
  static String get storeUrl => config.platform.storeUrl;

  static bool isFeatureEnabled(String flag) => config.featureFlags[flag] ?? true;

  static AnnouncementConfig get announcement => config.announcement;

  /// Check if announcement was already dismissed
  static Future<bool> isAnnouncementDismissed() async {
    if (!announcement.isActive || announcement.dismissKey == null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dismissed_${announcement.dismissKey}') ?? false;
  }

  /// Mark announcement as dismissed
  static Future<void> dismissAnnouncement() async {
    if (announcement.dismissKey != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dismissed_${announcement.dismissKey}', true);
    }
  }
}
