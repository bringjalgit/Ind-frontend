import 'package:classifieds/model/UserActivePlansModel.dart';

abstract class UserActivePlanStates {}

class UserActivePlanInitially extends UserActivePlanStates {}

class UserActivePlanLoading extends UserActivePlanStates {}

class UserActivePlanLoaded extends UserActivePlanStates {
  UserActivePlansModel userActivePlansModel;
  UserActivePlanLoaded(this.userActivePlansModel);
}

class UserActivePlanFailure extends UserActivePlanStates {
  String error;
  UserActivePlanFailure(this.error);
}
