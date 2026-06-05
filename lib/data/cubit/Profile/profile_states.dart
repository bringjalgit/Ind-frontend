import 'package:classifieds/model/ProfileModel.dart';

abstract class ProfileStates {}

class ProfileInitially extends ProfileStates {}

class ProfileLoading extends ProfileStates {}

class ProfileLoaded extends ProfileStates {
  ProfileModel profileModel;
  ProfileLoaded(this.profileModel);
}

class ProfileFailure extends ProfileStates {
  String error;
  ProfileFailure(this.error);
}
