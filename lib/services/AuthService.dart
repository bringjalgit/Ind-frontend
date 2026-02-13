import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/utils/AppLogger.dart';
import '../services/api_endpoint_urls.dart';
import '../services/ApiClient.dart';
import '../utils/constants.dart';
import 'SecureStorageService.dart';

class AuthService {
  static const String _accessTokenKey = "access_token";
  static const String _planStatus = "plan_status";
  static const String _freePlanStatus = "free_plan_status";
  static const String _refreshTokenKey = "refresh_token";
  static const String _tokenExpiryKey = "token_expiry";
  static const String _userName = "user_name";
  static const String _email = "email";
  static const String _mobile = "mobile";
  static const String _id = "id";
  static const String _isNewUser = "isNewUser";
  static const String _state = "state";
  static const String _stateId = "stateId";
  static const String _cityId = "cityId";
  static const String _city = "city";
  static const String _isSubscribed = "isSubscribed";

  static final SecureStorageService _secure = SecureStorageService.instance;

  /// ------------------------
  /// BASIC GETTERS
  /// ------------------------

  static Future<String?> getName() => _secure.getString(_userName);
  static Future<String?> getEmail() => _secure.getString(_email);
  static Future<String?> getMobile() => _secure.getString(_mobile);
  static Future<String?> getId() => _secure.getString(_id);
  static Future<String?> getState() => _secure.getString(_state);
  static Future<String?> getCity() => _secure.getString(_city);
  static Future<String?> getStateId() => _secure.getString(_stateId);
  static Future<String?> getCityId() => _secure.getString(_cityId);
  static Future<String?> getAccessToken() => _secure.getString(_accessTokenKey);
  static Future<String?> getRefreshToken() =>
      _secure.getString(_refreshTokenKey);

  /// ------------------------
  /// STATUS GETTERS
  /// ------------------------

  static Future<String?> getPlanStatus() => _secure.getString(_planStatus);

  static Future<String?> getFreePlanStatus() =>
      _secure.getString(_freePlanStatus);

  static Future<String?> getSubscriptionStatus() =>
      _secure.getString(_isSubscribed);

  static Future<String?> getUserStatus() => _secure.getString(_isNewUser);

  /// ------------------------
  /// BOOLEAN HELPERS
  /// ------------------------

  static Future<bool> get isGuest async {
    final token = await getAccessToken();
    return token == null || token.isEmpty;
  }

  static Future<bool> get isEligibleForAd async =>
      (await getPlanStatus()) != "false";

  static Future<bool> get isEligibleForFree async =>
      (await getFreePlanStatus()) != "false";

  static Future<bool> get isSubscribedUser async =>
      (await getSubscriptionStatus()) != "false";

  static Future<bool> get isNewUser async => (await getUserStatus()) != "false";

  /// ------------------------
  /// SETTERS
  /// ------------------------

  static Future<void> setPlanStatus(String status) =>
      _secure.setString(_planStatus, status);

  static Future<void> setSubscribeStatus(String status) =>
      _secure.setString(_isSubscribed, status);

  static Future<void> setFreePlanStatus(String status) =>
      _secure.setString(_freePlanStatus, status);

  static Future<void> setUserStatus(String status) =>
      _secure.setString(_isNewUser, status);

  /// ------------------------
  /// TOKEN EXPIRY CHECK
  /// ------------------------

  static Future<bool> isTokenExpired() async {
    final expiryTimestampStr = await _secure.getString(_tokenExpiryKey);

    if (expiryTimestampStr == null) return true;

    final expiryTimestamp = int.tryParse(expiryTimestampStr);
    if (expiryTimestamp == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= expiryTimestamp;
  }

  /// ------------------------
  /// SAVE TOKENS (LOGIN)
  /// ------------------------

  static Future<void> saveTokens(
    String accessToken,
    String userName,
    String email,
    String mobile,
    int id,
    String? refreshToken,
    int expiryTimestamp,
    bool isNewUser,
    String? state,
    String? city,
    int? stateId,
    int? cityId,
  ) async {
    await _secure.setString(_accessTokenKey, accessToken);
    await _secure.setString(_userName, userName);
    await _secure.setString(_email, email);
    await _secure.setString(_mobile, mobile);
    await _secure.setString(_id, id.toString());
    await _secure.setString(_refreshTokenKey, refreshToken ?? "");
    await _secure.setString(_tokenExpiryKey, expiryTimestamp.toString());
    await _secure.setString(_isNewUser, isNewUser.toString());

    if (state != null) await _secure.setString(_state, state);
    if (city != null) await _secure.setString(_city, city);
    if (stateId != null) await _secure.setString(_stateId, stateId.toString());
    if (cityId != null) await _secure.setString(_cityId, cityId.toString());

    debugPrint("✅ Tokens saved successfully");
  }

  /// ------------------------
  /// UPDATE TOKENS (REFRESH)
  /// ------------------------

  static Future<void> updateTokens(
    String accessToken,
    String? refreshToken,
    int expiryTimestamp,
  ) async {
    await _secure.setString(_accessTokenKey, accessToken);
    await _secure.setString(_refreshTokenKey, refreshToken ?? "");
    await _secure.setString(_tokenExpiryKey, expiryTimestamp.toString());
    debugPrint("🔄 Tokens updated successfully");
  }

  /// ------------------------
  /// REFRESH TOKEN
  /// ------------------------

  static Future<bool> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await ApiClient.post(
        APIEndpointUrls.refreshtoken,
        data: {"refreshToken": refreshToken},
      );

      if (response.statusCode != 200) return false;

      final data = response.data as Map<String, dynamic>;

      final newAccessToken = data["accessToken"];
      final newRefreshToken = data["refreshToken"];
      final expiryTime = data["accessTokenExpiry"];

      if (newAccessToken == null ||
          newRefreshToken == null ||
          expiryTime == null) {
        return false;
      }

      await updateTokens(newAccessToken, newRefreshToken, expiryTime);

      return true;
    } catch (e) {
      debugPrint("❌ Token refresh failed: $e");
      return false;
    }
  }

  /// ------------------------
  /// LOGOUT
  /// ------------------------

  static Future<void> logout() async {
    await _secure.deleteAll();
    debugPrint("🚪 User logged out");

    final context = navigatorKey.currentContext;
    if (context != null) {
      context.go('/login');
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) ctx.go('/login');
      });
    }
  }
}
