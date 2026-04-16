import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for dashboard data (banners, categories, listings)
/// Uses stale-while-revalidate pattern: show cached data instantly, refresh in background
class DashboardCacheService {
  static const _keyBanners = 'dashboard_banners';
  static const _keyCategories = 'dashboard_categories';
  static const _keyNewCategories = 'dashboard_new_categories';
  static const _keyProducts = 'dashboard_products';
  static const _keyTimestamp = 'dashboard_cache_time';

  // Cache TTL — data older than this will still show but trigger background refresh
  static const Duration _cacheTTL = Duration(minutes: 30);

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save all dashboard data to cache
  static Future<void> saveAll({
    Map<String, dynamic>? banners,
    Map<String, dynamic>? categories,
    Map<String, dynamic>? newCategories,
    Map<String, dynamic>? products,
  }) async {
    final prefs = await _instance;
    if (banners != null) await prefs.setString(_keyBanners, jsonEncode(banners));
    if (categories != null) await prefs.setString(_keyCategories, jsonEncode(categories));
    if (newCategories != null) await prefs.setString(_keyNewCategories, jsonEncode(newCategories));
    if (products != null) await prefs.setString(_keyProducts, jsonEncode(products));
    await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached banners (returns null if no cache)
  static Future<Map<String, dynamic>?> getBanners() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyBanners);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Get cached categories
  static Future<Map<String, dynamic>?> getCategories() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyCategories);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Get cached new categories
  static Future<Map<String, dynamic>?> getNewCategories() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyNewCategories);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Get cached products
  static Future<Map<String, dynamic>?> getProducts() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyProducts);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Check if cache exists
  static Future<bool> hasCache() async {
    final prefs = await _instance;
    return prefs.containsKey(_keyBanners) || prefs.containsKey(_keyCategories);
  }

  /// Check if cache is stale (older than TTL)
  static Future<bool> isStale() async {
    final prefs = await _instance;
    final ts = prefs.getInt(_keyTimestamp);
    if (ts == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age > _cacheTTL.inMilliseconds;
  }

  /// Clear all dashboard cache
  static Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(_keyBanners);
    await prefs.remove(_keyCategories);
    await prefs.remove(_keyNewCategories);
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyTimestamp);
  }
}
