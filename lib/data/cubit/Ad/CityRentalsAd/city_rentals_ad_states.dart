import '../../../../model/AdSuccessModel.dart';


abstract class CityRentalsAdStates {}

class CityRentalsAdInitially extends CityRentalsAdStates {}

class CityRentalsAdLoading extends CityRentalsAdStates {}

class CityRentalsAdSuccess extends CityRentalsAdStates {
  AdSuccessModel adSuccessModel;
  CityRentalsAdSuccess(this.adSuccessModel);
}

class CityRentalsAdFailure extends CityRentalsAdStates {
  String error;
  CityRentalsAdFailure(this.error);
}
