import '../../../../model/AdSuccessModel.dart';


abstract class MobileAdStates {}

class MobileAdInitially extends MobileAdStates {}

class MobileAdLoading extends MobileAdStates {}

class MobileAdSuccess extends MobileAdStates {
  AdSuccessModel adSuccessModel;
  MobileAdSuccess(this.adSuccessModel);
}

class MobileAdFailure extends MobileAdStates {
  String error;
  MobileAdFailure(this.error);
}
