import 'package:classifieds/model/AdSuccessModel.dart';

abstract class RecoverAccountStates {}

class RecoverAccountInitially extends RecoverAccountStates {}

class RecoverAccountLoading extends RecoverAccountStates {}

class RecoverAccountLoaded extends RecoverAccountStates {
  AdSuccessModel adSuccessModel;
  RecoverAccountLoaded(this.adSuccessModel);
}

class RecoverAccountFailure extends RecoverAccountStates {
  String error;
  RecoverAccountFailure(this.error);
}
