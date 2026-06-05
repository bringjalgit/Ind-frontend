import 'package:classifieds/model/AdSuccessModel.dart';

abstract class DeleteAccountStates {}

class DeleteAccountInitially extends DeleteAccountStates {}

class DeleteAccountLoading extends DeleteAccountStates {}

class DeleteAccountLoaded extends DeleteAccountStates {
  AdSuccessModel successModel;
  DeleteAccountLoaded(this.successModel);
}

class DeleteAccountFailure extends DeleteAccountStates {
  String error;
  DeleteAccountFailure(this.error);
}
