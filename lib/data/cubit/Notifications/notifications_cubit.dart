import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/NotificationService.dart';
import 'notifications_repository.dart';
import 'notifications_states.dart';

class NotificationsCubit extends Cubit<NotificationStates> {
  final NotificationRepo repo;
  NotificationsCubit(this.repo) : super(NotificationInitial());

  Future<void> getNotifications() async {
    emit(NotificationLoading());
    final res = await repo.getNotifications();
    if (res != null && res.success) {
      emit(NotificationLoaded(res.items, res.unreadCount));
    } else {
      emit(NotificationFailure('Failed to load notifications'));
    }
  }

  Future<void> markRead(String id) async {
    await repo.markRead(id);
    // Keep the launcher badge in lockstep with the inbox.
    await NotificationService.instance.refreshAppBadge();
    await getNotifications();
  }

  Future<void> markAllRead() async {
    await repo.markAllRead();
    await NotificationService.instance.refreshAppBadge();
    await getNotifications();
  }
}
