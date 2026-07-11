import 'package:classifieds/model/ReferralModels.dart';

abstract class ReferralState {}

class ReferralInitial extends ReferralState {}

class ReferralLoading extends ReferralState {}

/// Feature is off for this user (disabled globally or not allow-listed).
class ReferralDisabled extends ReferralState {}

class ReferralLoaded extends ReferralState {
  final ReferralInfo info;
  final List<ReferredFriend> friends;
  ReferralLoaded(this.info, this.friends);
}

class ReferralError extends ReferralState {
  final String message;
  ReferralError(this.message);
}
