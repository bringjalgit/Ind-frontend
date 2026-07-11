import 'package:classifieds/model/AdSuccessModel.dart';

abstract class RegisterStates {}

class RegisterInitially extends RegisterStates {}

class RegisterLoading extends RegisterStates {}

class RegisterLoaded extends RegisterStates {
  AdSuccessModel adSuccessModel;
  RegisterLoaded(this.adSuccessModel);
}

class RegisterFailure extends RegisterStates {
  String error;
  RegisterFailure(this.error);
}
