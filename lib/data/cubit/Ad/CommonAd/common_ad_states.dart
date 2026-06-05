import '../../../../model/AdSuccessModel.dart';


abstract class CommonAdStates {}

class CommonAdInitially extends CommonAdStates {}

class CommonAdLoading extends CommonAdStates {}

class CommonAdSuccess extends CommonAdStates {
  AdSuccessModel adSuccessModel;
  CommonAdSuccess(this.adSuccessModel);
}

class CommonAdFailure extends CommonAdStates {
  String error;
  CommonAdFailure(this.error);
}
