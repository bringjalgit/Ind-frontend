/// Models for the in-app notification inbox.
/// Built against the verified backend I/O:
///   GET /app/notifications -> { success, data:[{id,stream,priority,title,body,
///     data:{...}, read, read_at?, created_at}], pagination:{...}, unread_count }
class NotificationListResponse {
  final bool success;
  final List<NotificationItem> items;
  final int unreadCount;
  final NotificationPagination? pagination;

  NotificationListResponse({
    required this.success,
    required this.items,
    required this.unreadCount,
    this.pagination,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      success: json['success'] == true,
      items: (json['data'] as List?)
              ?.map((e) =>
                  NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          <NotificationItem>[],
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      pagination: json['pagination'] is Map
          ? NotificationPagination.fromJson(
              Map<String, dynamic>.from(json['pagination']))
          : null,
    );
  }
}

class NotificationItem {
  final String id;
  final String? stream;
  final String? priority;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? createdAt;

  NotificationItem({
    required this.id,
    this.stream,
    this.priority,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    this.createdAt,
  });

  /// Route/type hints the backend stamps under `data` (e.g. route:'chat',
  /// conversation_id, listing_id, senderId) — used to deep-link on tap.
  String? get route => data['route']?.toString();
  String? get type => data['type']?.toString();

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      stream: json['stream']?.toString(),
      priority: json['priority']?.toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : <String, dynamic>{},
      read: json['read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class NotificationPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  NotificationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      hasMore: json['has_more'] == true,
    );
  }
}
