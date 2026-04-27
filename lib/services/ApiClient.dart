import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';
import 'AuthService.dart';
import 'BackendResolver.dart';
import 'api_endpoint_urls.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: APIEndpointUrls.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {"Content-Type": "application/json"},
      // 2xx–4xx are treated as normal responses; 5xx become errors
      validateStatus: (status) => status != null && status < 500,
      // optional but handy:
      receiveDataWhenStatusError: true,
    ),
  );

  static void setupInterceptors() {
    _dio.interceptors.clear();

    // 1) Auth interceptor (token attach + refresh)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('Interceptor triggered for: ${options.uri}');

          final isGuestUser = await AuthService.isGuest;
          if (isGuestUser) {
            debugPrint('Guest user → skipping token for ${options.uri}');
            options.headers.remove('Authorization');
            return handler.next(options);
          }

          final isExpired = await AuthService.isTokenExpired();
          if (isExpired) {
            debugPrint('Token expired → trying refresh...');
            final refreshed = await _refreshToken();
            if (!refreshed) {
              debugPrint('❌ Token refresh failed, logging out...');
              await AuthService.logout();
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Token refresh failed, please log in again',
                  type: DioExceptionType.cancel,
                ),
              );
            }
          }

          final accessToken = await AuthService.getAccessToken();
          if (accessToken?.isNotEmpty == true) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          } else {
            debugPrint('⚠️ Non-guest but no token found');
          }

          return handler.next(options);
        },
      ),
    );

    // 2) Global status handling interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          final status = response.statusCode ?? 0;

          if (status >= 200 && status < 300) {
            // true success
            return handler.next(response);
          }

          // 3xx — let it pass through (Dio handles redirects internally
          // but if any 3xx lands here, treat it as non-error).
          if (status >= 300 && status < 400) {
            return handler.next(response);
          }

          // 4xx arrive here because validateStatus(<500) returns true.
          // CRITICAL DISTINCTION: a 401 means "session expired" ONLY when
          // the request carried an Authorization header. A 401 on an
          // unauthenticated request (login OTP verify, recovery token,
          // google auth) is a business-logic error — the user was never
          // logged in, so logging them out is wrong and blows away the
          // real error message from the backend body.
          final hadAuthHeader =
              response.requestOptions.headers.containsKey('Authorization');

          if (status == 401 && hadAuthHeader) {
            debugPrint(
              '❌ 401 on authed request → session expired, logging out',
            );
            await AuthService.logout();
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: 'Session expired, please log in again',
                type: DioExceptionType.badResponse,
              ),
            );
          }

          // Only admin-level account blocks should kick the user to the
          // blocked-account screen. A 403 with any other code (FORBIDDEN
          // from a resource-level ownership check, NOT_PARTICIPANT from
          // the chat participant guard, seller-only SWA actions hit by a
          // buyer, etc.) is a normal per-request denial — let the caller
          // surface the error inline instead of nuking the session.
          if (status == 403) {
            final body = response.data;
            final isAccountBlocked =
                body is Map && body['code'] == 'ACCOUNT_BLOCKED';
            if (isAccountBlocked) {
              debugPrint('❌ 403 ACCOUNT_BLOCKED → routing to /blocked_account');
              final context = navigatorKey.currentContext;
              context?.go('/blocked_account');
            } else {
              debugPrint(
                '⚠️ 403 ${body is Map ? body['code'] : 'no-code'} → inline error',
              );
            }
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: response.data ?? 'Forbidden (${response.statusCode})',
                type: DioExceptionType.badResponse,
              ),
            );
          }

          // All other 4xx (401 on unauthed login, 400 MISSING_FIELDS,
          // 401 INVALID_OTP / INVALID_RECOVERY_TOKEN, 404 USER_NOT_FOUND,
          // 429 RATE_LIMITED, etc.): reject with the full response
          // preserved so caller's catch can read e.response?.data and
          // parse the backend's error shape.
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: response.data ?? 'Request failed (${response.statusCode})',
              type: DioExceptionType.badResponse,
            ),
          );
        },

        onError: (DioException e, handler) async {
          // Only 5xx (and network/timeout/cancel) reach here due to validateStatus(<500)
          final code = e.response?.statusCode;

          // 503 BACKEND_DORMANT → admin flipped active_backend mid-session, or
          // we hit the wrong backend on the very first request after launch.
          // Re-probe /health and retry the request once with the new base URL.
          // Marked with `extra['__rebound']=true` so a second 503 doesn't loop.
          if (code == 503) {
            final body = e.response?.data;
            final isDormant = body is Map && body['code'] == 'BACKEND_DORMANT';
            final alreadyRetried = e.requestOptions.extra['__rebound'] == true;
            if (isDormant && !alreadyRetried) {
              try {
                await BackendResolver.reresolve();
                final newPath = _swapBaseToResolvedBackend(e.requestOptions.path);
                if (newPath != null && newPath != e.requestOptions.path) {
                  final retryOptions = e.requestOptions.copyWith(path: newPath);
                  retryOptions.extra['__rebound'] = true;
                  debugPrint('[ApiClient] 503 BACKEND_DORMANT → reresolved, retrying $newPath');
                  final retryResponse = await _dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (retryErr) {
                debugPrint('[ApiClient] 503 retry failed: $retryErr');
                // Fall through to the default error path below
              }
            }
          }

          if (code == 401) {
            // Defensive: if a 401 somehow reaches the error interceptor
            // (shouldn't, since validateStatus(<500) routes 4xx to
            // onResponse), only logout when the request had an auth
            // header. Same reasoning as the onResponse branch.
            final hadAuthHeader =
                e.requestOptions.headers.containsKey('Authorization');
            if (hadAuthHeader) {
              AuthService.logout();
            }
            return handler.next(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: e.response?.data ?? 'Request failed (401)',
                type: DioExceptionType.badResponse,
              ),
            );
          }

          // Mirror the onResponse branch: only ACCOUNT_BLOCKED (admin
          // ban) triggers the /blocked_account redirect. Resource-level
          // FORBIDDEN errors flow through as normal DioException so the
          // caller can surface them inline.
          if (code == 403) {
            final body = e.response?.data;
            final isAccountBlocked =
                body is Map && body['code'] == 'ACCOUNT_BLOCKED';
            if (isAccountBlocked) {
              final context = navigatorKey.currentContext;
              context?.go('/blocked_account');
            }
            return handler.next(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: e.response?.data ?? 'Forbidden (403)',
                type: DioExceptionType.badResponse,
              ),
            );
          }

          // Optionally map timeouts / no-internet to friendly errors
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            return handler.next(
              DioException(
                requestOptions: e.requestOptions,
                error: 'Network timeout, please try again',
                type: e.type,
                response: e.response,
              ),
            );
          }

          if (e.type == DioExceptionType.connectionError) {
            return handler.next(
              DioException(
                requestOptions: e.requestOptions,
                error: 'No internet connection',
                type: e.type,
                response: e.response,
              ),
            );
          }

          // leave others as-is (includes 5xx)
          return handler.next(e);
        },
      ),
    );
  }

  static Future<bool> _refreshToken() async {
    try {
      final newToken = await AuthService.refreshToken();
      if (newToken) {
        debugPrint("✅ Token refreshed successfully");
        return true;
      }
      debugPrint("❌ Token refresh returned false");
    } catch (e) {
      debugPrint("❌ Token refresh failed: $e");
    }
    return false;
  }

  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Response _handleError(dynamic error) {
    if (error is DioException) {
      throw error;
    } else {
      throw Exception("Unexpected error occurred");
    }
  }

  // Placeholder for _handleNavigation (implement as needed)
  static void _handleNavigation(
    int? statusCode,
    GlobalKey<NavigatorState> navigatorKey,
  ) {}

  /// Returns the same URL with its main-stack base URL replaced by whatever
  /// BackendResolver currently resolves to. Returns null if the URL doesn't
  /// belong to either main-stack base (e.g. chat-stack URLs, S3 uploads) —
  /// the caller should fall through to normal error handling in that case.
  static String? _swapBaseToResolvedBackend(String url) {
    final newBase = BackendResolver.currentBaseUrl;
    if (url.startsWith(BackendResolver.lambdaBaseUrl)) {
      return url.replaceFirst(BackendResolver.lambdaBaseUrl, newBase);
    }
    if (url.startsWith(BackendResolver.ec2BaseUrl)) {
      return url.replaceFirst(BackendResolver.ec2BaseUrl, newBase);
    }
    return null;
  }
}
