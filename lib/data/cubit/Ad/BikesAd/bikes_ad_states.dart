import '../../../../model/AdSuccessModel.dart';


abstract class BikesAdStates {}

class BikesAdInitially extends BikesAdStates {}

class BikesAdLoading extends BikesAdStates {}

class BikesAdSuccess extends BikesAdStates {
  AdSuccessModel adSuccessModel;
  BikesAdSuccess(this.adSuccessModel);
}

class BikesAdFailure extends BikesAdStates {
  String error;
  BikesAdFailure(this.error);
}
