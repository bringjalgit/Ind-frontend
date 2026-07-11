import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/cubit/Notifications/notifications_cubit.dart';
import '../../data/cubit/Notifications/notifications_states.dart';
import '../../model/NotificationModel.dart';
import '../../services/NotificationService.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Load the inbox, then auto-mark everything read so the bell badge clears
    // the moment Notifications is opened — the user shouldn't have to tap
    // "Mark all read". Standard notification-center behaviour: opening = seen.
    // We load first so the list renders immediately; markAllRead re-emits the
    // read state, and refreshAppBadge syncs the launcher app-icon badge.
    Future.microtask(() async {
      final cubit = context.read<NotificationsCubit>();
      await cubit.getNotifications();
      if (!mounted) return;
      await cubit.markAllRead();
      NotificationService.instance.refreshAppBadge();
    });
  }

  void _onTap(NotificationItem n) {
    if (!n.read) context.read<NotificationsCubit>().markRead(n.id);

    // Best-effort deep-link, mirroring the push-tap routing.
    final receiverId = (n.data['senderId'] ??
            n.data['sender_id'] ??
            n.data['buyer_id'] ??
            n.data['receiverId'])
        ?.toString();
    final listingId =
        (n.data['listingId'] ?? n.data['listing_id'])?.toString();
    if (receiverId != null &&
        receiverId.isNotEmpty &&
        listingId != null &&
        listingId.isNotEmpty) {
      context.push('/chat?receiverId=$receiverId&listingId=$listingId');
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Notifications', style: AppTextStyles.headlineSmall(textColor)),
        actions: [
          TextButton(
            onPressed: () =>
                context.read<NotificationsCubit>().markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationStates>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load notifications',
                      style: AppTextStyles.bodyMedium(textColor)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<NotificationsCubit>().getNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final items = (state as NotificationLoaded).items;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No notifications yet',
                      style: AppTextStyles.bodyMedium(textColor)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<NotificationsCubit>().getNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = items[index];
                return InkWell(
                  onTap: () => _onTap(n),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: n.read
                          ? Colors.grey.withValues(alpha: 0.08)
                          : Colors.blue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: n.read
                          ? null
                          : Border.all(color: Colors.blue.shade200),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications,
                              color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: AppTextStyles.bodyMedium(textColor)
                                    .copyWith(
                                  fontWeight: n.read
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              if (n.body.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(n.body,
                                    style: AppTextStyles.bodyMedium(
                                        textColor.withValues(alpha: 0.7))),
                              ],
                              const SizedBox(height: 5),
                              Text(_timeAgo(n.createdAt),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          textColor.withValues(alpha: 0.5))),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Container(
                            margin: const EdgeInsets.only(top: 4, left: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.blue, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
