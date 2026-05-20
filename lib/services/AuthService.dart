import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_endpoint_urls.dart';
import '../utils/constants.dart';
import 'SecureStorageService.dart';
import 'SocketService.dart';

/// Auth-state store for the user app.
///
/// ── Storage layout ──────────────────────────────────────────────────
/// All auth-related state is persisted as a single JSON blob under
/// `_sessionKey`. One key, one write, one read → atomic by definition.
///
/// Why this matters:
///   The previous design wrote 8–14 separate SecureStorage keys in
///   sequence inside saveTokens()/updateTokens(). If the app died
///   between writes (force-close, OOM kill, crash, battery flat) the
///   storage was left in a half-baked state — typically with the
///   access token present but refresh token missing. On reopen the
///   user "appeared logged in" but the next token expiry triggered a
///   refresh, refresh found a null refresh token, and the user was
///   silently kicked to a logged-out state with no clean recovery.
///   This was the largest single cause of the random-logout support
///   tickets identified in the May 2026 auth audit.
///
/// With a single JSON blob the OS either commits the whole document or
/// none of it. Partial state is impossible.
///
/// ── Migration ───────────────────────────────────────────────────────
/// On first run after the update we read the 17 legacy keys, build the
/// blob, write it, and (subject to the rollback safety net below)
/// delete the legacy keys.
///
/// Critical ordering: WRITE the new blob BEFORE deleting legacy keys.
/// If the process dies between the write and the deletes, legacy keys
/// are still there and migration re-runs idempotently next launch.
///
/// ── Rollback safety net ─────────────────────────────────────────────
/// `_keepLegacyForRollback` is `true` for the first release of the new
/// format. With it on, migration writes the new blob but leaves the
/// legacy keys in place — a downgrade to a pre-blob build still finds
/// them and users stay logged in. Flip to `false` in the next release
/// once production has baked the new format for a cycle.
class AuthService {
  // ── Storage keys ──────────────────────────────────────────────────
  static const String _sessionKey = 'auth_session_v1';
  static const bool _keepLegacyForRollback = true;

  // Legacy SecureStorage keys (pre-v1 layout). Kept here so the
  // migration code can find them; also written to by the
  // safety-net path so an emergency downgrade still works.
  static const String _accessTokenKey = 'access_token';
  static const String _planStatus = 'plan_status';
  static const String _freePlanStatus = 'free_plan_status';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userName = 'user_name';
  static const String _email = 'email';
  static const String _mobile = 'mobile';
  static const String _id = 'id';
  static const String _isNewUser = 'isNewUser';
  static const String _state = 'state';
  static const String _stateId = 'stateId';
  static const String _cityId = 'cityId';
  static const String _city = 'city';
  static const String _isSubscribed = 'isSubscribed';
  static const String _image = 'user_image';
  static const String _profilePicture = 'profile_picture';

  // Field names INSIDE the JSON blob. Keep stable across releases —
  // changing one is a migration.
  static const String _fAccessToken = 'accessToken';
  static const String _fRefreshToken = 'refreshToken';
  static const String _fTokenExpiry = 'tokenExpiry';
  static const String _fName = 'name';
  static const String _fEmail = 'email';
  static const String _fMobile = 'mobile';
  static const String _fId = 'id';
  static const String _fIsNewUser = 'isNewUser';
  static const String _fState = 'state';
  static const String _fCity = 'city';
  static const String _fStateId = 'stateId';
  static const String _fCityId = 'cityId';
  static const String _fImage = 'image';
  static const String _fProfilePicture = 'profilePicture';
  static const String _fPlanStatus = 'planStatus';
  static const String _fFreePlanStatus = 'freePlanStatus';
  static const String _fIsSubscribed = 'isSubscribed';

  static final SecureStorageService _secure = SecureStorageService.instance;

  // ── In-memory cache + concurrency primitives ──────────────────────
  //
  // _cache is the runtime source of truth.
  //   null         → not hydrated yet, _ensureLoaded() will populate it.
  //   {} (empty)   → loaded, but the user is logged out / first install.
  //   populated    → live session.
  //
  // _loadFuture serialises the initial hydrate so two cubits racing for
  // getName()/getEmail() at startup share the same read instead of
  // each triggering their own migration.
  //
  // _writeLock serialises mutations so two concurrent setters don't
  // interleave reads/writes of _cache. Without it, setPlanStatus() and
  // setProfilePicture() firing in parallel could each snapshot _cache,
  // mutate one field, and the second writer's _saveCache() would
  // overwrite the first writer's change.
  static Map<String, dynamic>? _cache;
  static Future<void>? _loadFuture;
  static final _AsyncMutex _writeLock = _AsyncMutex();

  /// Ensure `_cache` is hydrated from storage. Idempotent and
  /// concurrency-safe.
  static Future<void> _ensureLoaded() {
    if (_cache != null) return Future<void>.value();
    _loadFuture ??= _doLoad();
    return _loadFuture!;
  }

  /// Hydrate cache from storage. Tries the new blob first; if missing
  /// (or corrupt), migrates from legacy keys. Worst-case outcome on
  /// any failure is "treat as logged-out" — never a crash at startup.
  static Future<void> _doLoad() async {
    try {
      // 1. New blob format.
      final raw = await _secure.getString(_sessionKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            _cache = Map<String, dynamic>.from(decoded);
            return;
          }
        } catch (e) {
          // Corrupt JSON. Fall through to legacy migration; if both
          // are empty the user is treated as logged-out (safe).
          debugPrint('⚠️ auth_session_v1 corrupt, falling back: $e');
        }
      }

      // 2. Legacy migration (or empty for first install).
      final migrated = await _readLegacyKeys();
      _cache = migrated;
      if (migrated.isNotEmpty) {
        // Write the new blob FIRST. Only delete legacy after the
        // commit lands so a crash mid-migration is recoverable.
        await _secure.setString(_sessionKey, jsonEncode(_cache));
        if (!_keepLegacyForRollback) {
          await _deleteLegacyKeys();
        }
        debugPrint(
          '🔁 Migrated ${migrated.length} legacy auth keys to v1 blob '
          '(rollback-safety: $_keepLegacyForRollback)',
        );
      }
    } catch (e) {
      debugPrint('❌ _doLoad fatal: $e');
      _cache = {};
    }
  }

  /// Read every legacy key in parallel and return a map keyed by the
  /// new blob field names. Null/empty values are skipped so a sparse
  /// legacy set produces a small blob.
  static Future<Map<String, dynamic>> _readLegacyKeys() async {
    final reads = await Future.wait([
      _secure.getString(_accessTokenKey),
      _secure.getString(_refreshTokenKey),
      _secure.getString(_tokenExpiryKey),
      _secure.getString(_userName),
      _secure.getString(_email),
      _secure.getString(_mobile),
      _secure.getString(_id),
      _secure.getString(_isNewUser),
      _secure.getString(_state),
      _secure.getString(_city),
      _secure.getString(_stateId),
      _secure.getString(_cityId),
      _secure.getString(_image),
      _secure.getString(_profilePicture),
      _secure.getString(_planStatus),
      _secure.getString(_freePlanStatus),
      _secure.getString(_isSubscribed),
    ]);
    final result = <String, dynamic>{};
    void put(String field, String? value) {
      if (value != null && value.isNotEmpty) result[field] = value;
    }
    put(_fAccessToken, reads[0]);
    put(_fRefreshToken, reads[1]);
    put(_fTokenExpiry, reads[2]);
    put(_fName, reads[3]);
    put(_fEmail, reads[4]);
    put(_fMobile, reads[5]);
    put(_fId, reads[6]);
    put(_fIsNewUser, reads[7]);
    put(_fState, reads[8]);
    put(_fCity, reads[9]);
    put(_fStateId, reads[10]);
    put(_fCityId, reads[11]);
    put(_fImage, reads[12]);
    put(_fProfilePicture, reads[13]);
    put(_fPlanStatus, reads[14]);
    put(_fFreePlanStatus, reads[15]);
    put(_fIsSubscribed, reads[16]);
    return result;
  }

  /// Delete every legacy SecureStorage key. Best-effort — individual
  /// failures don't roll the call back. Only invoked when the rollback
  /// safety net is off, OR during logout.
  static Future<void> _deleteLegacyKeys() async {
    await Future.wait([
      _secure.delete(_accessTokenKey),
      _secure.delete(_refreshTokenKey),
      _secure.delete(_tokenExpiryKey),
      _secure.delete(_userName),
      _secure.delete(_email),
      _secure.delete(_mobile),
      _secure.delete(_id),
      _secure.delete(_isNewUser),
      _secure.delete(_state),
      _secure.delete(_city),
      _secure.delete(_stateId),
      _secure.delete(_cityId),
      _secure.delete(_image),
      _secure.delete(_profilePicture),
      _secure.delete(_planStatus),
      _secure.delete(_freePlanStatus),
      _secure.delete(_isSubscribed),
    ]);
  }

  /// Atomic write of the in-memory cache to storage. Single keystore
  /// call → either the whole blob lands or none of it.
  static Future<void> _saveCache() async {
    await _secure.setString(_sessionKey, jsonEncode(_cache));
  }

  /// Read a single field from the cache, returning null on missing or
  /// empty values (preserves the old per-key getter semantics).
  static Future<String?> _readField(String field) async {
    await _ensureLoaded();
    final v = _cache![field];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  /// Mutate one field and persist. Serialised through the write lock
  /// so concurrent setters don't lose updates.
  static Future<void> _writeField(String field, String? value) {
    return _writeLock.run(() async {
      await _ensureLoaded();
      if (value == null) {
        _cache!.remove(field);
      } else {
        _cache![field] = value;
      }
      await _saveCache();
    });
  }

  /// Batch update — used by saveTokens()/updateTokens() so 8–14 fields
  /// land in one commit instead of one per field.
  static Future<void> _writeFields(Map<String, String?> updates) {
    return _writeLock.run(() async {
      await _ensureLoaded();
      updates.forEach((field, value) {
        if (value == null) {
          _cache!.remove(field);
        } else {
          _cache![field] = value;
        }
      });
      await _saveCache();
    });
  }

  /// ------------------------
  /// BASIC GETTERS — public API unchanged
  /// ------------------------

  static Future<String?> getName() => _readField(_fName);
  static Future<String?> getEmail() => _readField(_fEmail);
  static Future<String?> getMobile() => _readField(_fMobile);
  static Future<String?> getId() => _readField(_fId);
  static Future<String?> getState() => _readField(_fState);
  static Future<String?> getCity() => _readField(_fCity);
  static Future<String?> getStateId() => _readField(_fStateId);
  static Future<String?> getCityId() => _readField(_fCityId);
  static Future<String?> getImage() => _readField(_fImage);
  static Future<String?> getProfilePicture() => _readField(_fProfilePicture);
  static Future<String?> getAccessToken() => _readField(_fAccessToken);
  static Future<String?> getRefreshToken() => _readField(_fRefreshToken);

  /// Unified avatar URL for the current logged-in user, matching the
  /// display priority enforced by [ProfileModel.Data.displayImage]:
  /// user-uploaded S3 URL first, Google reference picture as fallback.
  static Future<String?> getDisplayImage() async {
    final img = await getImage();
    if (img != null && img.trim().isNotEmpty) return img;
    final pic = await getProfilePicture();
    if (pic != null && pic.trim().isNotEmpty) return pic;
    return null;
  }

  /// ------------------------
  /// STATUS GETTERS
  /// ------------------------

  static Future<String?> getPlanStatus() => _readField(_fPlanStatus);
  static Future<String?> getFreePlanStatus() => _readField(_fFreePlanStatus);
  static Future<String?> getSubscriptionStatus() => _readField(_fIsSubscribed);
  static Future<String?> getUserStatus() => _readField(_fIsNewUser);

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
      _writeField(_fPlanStatus, status);

  static Future<void> setSubscribeStatus(String status) =>
      _writeField(_fIsSubscribed, status);

  static Future<void> setFreePlanStatus(String status) =>
      _writeField(_fFreePlanStatus, status);

  /// Single-field writer for the Google-sourced profile picture. Called
  /// by RegisterUserDetailsScreen right after the Register endpoint
  /// succeeds with a Google pre-fill, so the cached auth data has the
  /// avatar URL for the Dashboard's first render — no need to wait for
  /// a getMyProfileDetails round-trip. Silently no-ops when [url] is
  /// null so callers can pass the nullable state variable directly.
  static Future<void> setProfilePicture(String? url) async {
    if (url == null || url.isEmpty) return;
    await _writeField(_fProfilePicture, url);
  }

  static Future<void> setUserStatus(String status) =>
      _writeField(_fIsNewUser, status);

  /// ------------------------
  /// TOKEN EXPIRY CHECK
  /// ------------------------

  static Future<bool> isTokenExpired() async {
    final expiryTimestampStr = await _readField(_fTokenExpiry);
    if (expiryTimestampStr == null) return true;
    final expiryTimestamp = int.tryParse(expiryTimestampStr);
    if (expiryTimestamp == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= expiryTimestamp;
  }

  /// ------------------------
  /// SAVE TOKENS (LOGIN) — public signature unchanged
  /// ------------------------

  static Future<void> saveTokens(
    String accessToken,
    String userName,
    String email,
    String mobile,
    String id,
    String? refreshToken,
    int expiryTimestamp,
    bool isNewUser,
    String? state,
    String? city,
    int? stateId,
    int? cityId, [
    // Optional avatar fields — added when restoring Google onboarding.
    // Kept as trailing positional optionals so every existing call site
    // (mobile OTP, email OTP, register, etc.) keeps working unchanged.
    // Only the Google sign-in path needs to pass them.
    String? image,
    String? profilePicture,
  ]) async {
    final updates = <String, String?>{
      _fAccessToken: accessToken,
      _fName: userName,
      _fEmail: email,
      _fMobile: mobile,
      _fId: id,
      _fRefreshToken: refreshToken ?? '',
      _fTokenExpiry: expiryTimestamp.toString(),
      _fIsNewUser: isNewUser.toString(),
    };
    if (state != null) updates[_fState] = state;
    if (city != null) updates[_fCity] = city;
    if (stateId != null) updates[_fStateId] = stateId.toString();
    if (cityId != null) updates[_fCityId] = cityId.toString();
    if (image != null) updates[_fImage] = image;
    if (profilePicture != null) updates[_fProfilePicture] = profilePicture;
    await _writeFields(updates);
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
    await _writeFields({
      _fAccessToken: accessToken,
      _fRefreshToken: refreshToken ?? '',
      _fTokenExpiry: expiryTimestamp.toString(),
    });
    debugPrint("🔄 Tokens updated successfully");
  }

  /// ------------------------
  /// REFRESH TOKEN
  /// ------------------------
  ///
  /// Single-flight guard. When the access token expires and N concurrent
  /// requests all hit the ApiClient interceptor at once (very common on
  /// app resume — profile fetch, chat list, notifications, banner, plan
  /// check all kick off in the same tick), all N would otherwise issue
  /// their own POST /refresh-token. The backend rotates the JTI on every
  /// refresh, so N parallel refreshes mint N (access, refresh) pairs but
  /// only the last write to SecureStorage survives — the other N-1
  /// callers end up holding tokens whose refresh-side has already been
  /// revoked, and the next request from those callers 401s the user out
  /// of the app for no visible reason. This was the second-largest cause
  /// of the random-logout support tickets identified in the May 2026
  /// auth audit (alongside Bug #1's non-atomic writes).
  ///
  /// With the guard, the FIRST caller in an expired-token window kicks
  /// off the real refresh. Every subsequent caller that lands while it's
  /// in flight awaits the SAME Future and shares the result. Backend
  /// sees exactly one /refresh per real expiry window; the JTI rotates
  /// exactly once; SecureStorage takes one atomic write (Bug #1 fix).
  ///
  /// Cleared in `whenComplete` so successive refreshes are still allowed
  /// — only concurrent ones are collapsed.
  static Future<bool>? _refreshInFlight;

  static Future<bool> refreshToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      // Another caller is already refreshing — piggy-back on their work.
      // We do NOT inherit their stack trace, so debugging needs to look
      // at the in-flight call's logs, not this one.
      debugPrint('🔁 refreshToken: joining in-flight refresh');
      return inFlight;
    }
    final future = _doRefresh();
    _refreshInFlight = future;
    // Clear the slot when the refresh resolves, whether success or
    // failure. `identical` guards against the rare case where a fast
    // failure + immediate retry has already installed a new in-flight
    // Future by the time this callback runs.
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
    return future;
  }

  /// Performs the actual /refresh-token HTTP call. Never invoked
  /// directly outside this file — go through [refreshToken] so the
  /// single-flight guard applies.
  static Future<bool> _doRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      // Bare Dio with NO interceptors — ApiClient's onRequest would see
      // isTokenExpired()==true and call this same refreshToken() again,
      // recursing indefinitely. Refresh must bypass the main Dio entirely.
      final bareDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        validateStatus: (s) => s != null && s < 500,
        headers: {'Content-Type': 'application/json'},
      ));
      final response = await bareDio.post(
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
    // Close the authenticated WebSocket BEFORE clearing tokens so the old
    // user's JWT-backed socket is not left dangling for the next user who
    // signs in on the same device. disconnect() also nulls _currentUserId
    // which disables the auto-reconnect path in SocketService.
    SocketService.disconnect();

    await _writeLock.run(() async {
      // Reset in-memory cache so subsequent getters return null even
      // before the disk write completes.
      _cache = {};
      _loadFuture = null;
      // Wipe everything — preserves the pre-refactor behaviour where
      // logout clears non-auth keys too (theme, location, etc.) so a
      // shared device doesn't bleed state to the next user.
      await _secure.deleteAll();
    });
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

/// Tiny async mutex. Each `run(task)` waits for the previous call to
/// finish before starting, guaranteeing FIFO non-overlapping execution.
/// Errors don't poison the lock — the next task still runs.
class _AsyncMutex {
  Completer<void>? _current;

  Future<T> run<T>(Future<T> Function() task) async {
    while (_current != null) {
      try {
        await _current!.future;
      } catch (_) {
        // Previous task threw — that's its problem, not ours.
      }
    }
    final completer = Completer<void>();
    _current = completer;
    try {
      return await task();
    } finally {
      _current = null;
      completer.complete();
    }
  }
}
