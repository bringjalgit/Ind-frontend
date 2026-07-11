import '../../../../model/AdSuccessModel.dart';


abstract class CommercialVehileAdStates {}

class CommercialVehileAdInitially extends CommercialVehileAdStates {}

class CommercialVehileAdLoading extends CommercialVehileAdStates {}

class CommercialVehileAdSuccess extends CommercialVehileAdStates {
  AdSuccessModel adSuccessModel;
  CommercialVehileAdSuccess(this.adSuccessModel);
}

class CommercialVehileAdFailure extends CommercialVehileAdStates {
  String error;
  CommercialVehileAdFailure(this.error);
}
