import '../../../services/ApiClient.dart';
import '../../../services/api_endpoint_urls.dart';
import '../../../model/NotificationModel.dart';

/// Notification inbox repo. Calls the chat-stack REST endpoints directly via
/// ApiClient (authed Dio) — keeps the feature self-contained without touching
/// the shared RemoteDataSource. Returns the parsed model / unified unread count.
abstract class NotificationRepo {
  Future<NotificationListResponse?> getNotifications({int page, int limit});
  Future<int> markRead(String id); // returns the new unified unread_count (-1 = unknown)
  Future<int> markAllRead();
}

class NotificationRepoImpl implements NotificationRepo {
  @override
  Future<NotificationListResponse?> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await ApiClient.get(
        APIEndpointUrls.get_notifications,
        queryParameters: {'page': page, 'limit': limit},
      );
      if (res.statusCode == 200 && res.data is Map) {
        return NotificationListResponse.fromJson(
            Map<String, dynamic>.from(res.data as Map));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> markRead(String id) async {
    try {
      final res = await ApiClient.post(
        APIEndpointUrls.notifications_mark_read,
        data: {'id': id},
      );
      if (res.data is Map && res.data['unread_count'] is num) {
        return (res.data['unread_count'] as num).toInt();
      }
    } catch (_) {}
    return -1;
  }

  @override
  Future<int> markAllRead() async {
    try {
      final res = await ApiClient.post(
        APIEndpointUrls.notifications_mark_all_read,
        data: {},
      );
      if (res.data is Map && res.data['unread_count'] is num) {
        return (res.data['unread_count'] as num).toInt();
      }
    } catch (_) {}
    return -1;
  }
}
