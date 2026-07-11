import '../../../model/NotificationModel.dart';

abstract class NotificationStates {}

class NotificationInitial extends NotificationStates {}

class NotificationLoading extends NotificationStates {}

class NotificationLoaded extends NotificationStates {
  final List<NotificationItem> items;
  final int unreadCount;
  NotificationLoaded(this.items, this.unreadCount);
}

class NotificationFailure extends NotificationStates {
  final String error;
  NotificationFailure(this.error);
}
