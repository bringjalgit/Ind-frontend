import '../../../../model/AdSuccessModel.dart';


abstract class PropertyAdStates {}

class PropertyAdInitially extends PropertyAdStates {}

class PropertyAdLoading extends PropertyAdStates {}

class PropertyAdSuccess extends PropertyAdStates {
  AdSuccessModel adSuccessModel;
  PropertyAdSuccess(this.adSuccessModel);
}

class PropertyAdFailure extends PropertyAdStates {
  String error;
  PropertyAdFailure(this.error);
}
