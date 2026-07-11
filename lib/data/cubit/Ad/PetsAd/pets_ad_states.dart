import '../../../../model/AdSuccessModel.dart';


abstract class PetsAdStates {}

class PetsAdInitially extends PetsAdStates {}

class PetsAdLoading extends PetsAdStates {}

class PetsAdSuccess extends PetsAdStates {
  AdSuccessModel adSuccessModel;
  PetsAdSuccess(this.adSuccessModel);
}

class PetsAdFailure extends PetsAdStates {
  String error;
  PetsAdFailure(this.error);
}
