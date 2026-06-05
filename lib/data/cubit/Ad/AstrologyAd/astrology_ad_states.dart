import '../../../../model/AdSuccessModel.dart';


abstract class AstrologyAdStates {}

class AstrologyAdInitially extends AstrologyAdStates {}

class AstrologyAdLoading extends AstrologyAdStates {}

class AstrologyAdSuccess extends AstrologyAdStates {
  AdSuccessModel adSuccessModel;
  AstrologyAdSuccess(this.adSuccessModel);
}

class AstrologyAdFailure extends AstrologyAdStates {
  String error;
  AstrologyAdFailure(this.error);
}
