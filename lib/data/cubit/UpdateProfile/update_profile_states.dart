import 'package:classifieds/model/AdSuccessModel.dart';

abstract class UpdateProfileStates {}

class UpdateProfileInitially extends UpdateProfileStates {}

class UpdateProfileLoading extends UpdateProfileStates {}

class UpdateProfileSuccess extends UpdateProfileStates {
  AdSuccessModel successModel;
  UpdateProfileSuccess(this.successModel);
}

class UpdateProfileFailure extends UpdateProfileStates {
  String error;
  UpdateProfileFailure(this.error);
}
