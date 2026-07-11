import '../../../../model/AdSuccessModel.dart';


abstract class CoWorkingAdStates {}

class CoWorkingAdInitially extends CoWorkingAdStates {}

class CoWorkingAdLoading extends CoWorkingAdStates {}

class CoWorkingAdSuccess extends CoWorkingAdStates {
  AdSuccessModel adSuccessModel;
  CoWorkingAdSuccess(this.adSuccessModel);
}

class CoWorkingAdFailure extends CoWorkingAdStates {
  String error;
  CoWorkingAdFailure(this.error);
}
