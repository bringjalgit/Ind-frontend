import '../../../../model/AdSuccessModel.dart';


abstract class CarsAdStates {}

class CarsAdInitially extends CarsAdStates {}

class CarsAdLoading extends CarsAdStates {}

class CarsAdSuccess extends CarsAdStates {
  AdSuccessModel adSuccessModel;
  CarsAdSuccess(this.adSuccessModel);
}

class CarsAdFailure extends CarsAdStates {
  String error;
  CarsAdFailure(this.error);
}
