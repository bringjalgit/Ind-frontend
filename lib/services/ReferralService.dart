import 'package:dio/dio.dart';
import 'package:classifieds/services/ApiClient.dart';
import 'package:classifieds/services/api_endpoint_urls.dart';
import 'package:classifieds/model/ReferralModels.dart';
import 'package:classifieds/utils/AppLogger.dart';

/// Thin data layer for Refer & Earn. Calls the chat-stack referral endpoints
/// via ApiClient (auth token attached by the ApiClient interceptor).
class ReferralService {
  static Future<ReferralInfo> getInfo() async {
    final res = await ApiClient.get(APIEndpointUrls.referral_info);
    return ReferralInfo.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<List<ReferredFriend>> getList() async {
    final res = await ApiClient.get(APIEndpointUrls.referral_list);
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => ReferredFriend.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Redeem reward points for a free listing (server debits the cost + grants
  /// one free-listing credit atomically). Returns success/message.
  static Future<ApplyReferralResult> redeemFreeListing() async {
    try {
      final res = await ApiClient.post(
        APIEndpointUrls.rewards_redeem,
        data: {'type': 'free_listing'},
      );
      return ApplyReferralResult.fromJson(Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map) {
        return ApplyReferralResult.fromJson(Map<String, dynamic>.from(body));
      }
      AppLogger.error('redeem free_listing dio: ${e.response?.statusCode} ${e.message}');
      return ApplyReferralResult(success: false, message: 'Could not redeem right now');
    } catch (e) {
      AppLogger.error('redeem free_listing: $e');
      return ApplyReferralResult(success: false, message: 'Could not redeem right now');
    }
  }

  /// Apply a referral code (one per account, ever). Idempotent on the server.
  static Future<ApplyReferralResult> apply(String code) async {
    try {
      final res = await ApiClient.post(
        APIEndpointUrls.referral_apply,
        data: {'code': code.trim().toUpperCase()},
      );
      return ApplyReferralResult.fromJson(Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      // Server returns structured error bodies (INVALID_CODE, ALREADY_APPLIED,
      // SELF_REFERRAL, DISABLED, RATE_LIMITED) with non-2xx status.
      final body = e.response?.data;
      if (body is Map) {
        return ApplyReferralResult.fromJson(Map<String, dynamic>.from(body));
      }
      AppLogger.error('referral apply dio: ${e.response?.statusCode} ${e.message}');
      return ApplyReferralResult(success: false, message: 'Could not apply code');
    } catch (e) {
      AppLogger.error('referral apply: $e');
      return ApplyReferralResult(success: false, message: 'Could not apply code');
    }
  }
}
