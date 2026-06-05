import '../../../../model/AdSuccessModel.dart';


abstract class JobsAdStates {}

class JobsAdInitially extends JobsAdStates {}

class JobsAdLoading extends JobsAdStates {}

class JobsAdSuccess extends JobsAdStates {
  AdSuccessModel adSuccessModel;
  JobsAdSuccess(this.adSuccessModel);
}

class JobsAdFailure extends JobsAdStates {
  String error;
  JobsAdFailure(this.error);
}
