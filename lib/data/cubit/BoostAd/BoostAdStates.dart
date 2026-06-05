import '../../../model/AdSuccessModel.dart';
import '../../../model/CreatePaymentModel.dart';

abstract class BoostAdStates {}

class BoostAdInitially extends BoostAdStates {}

class BoostAdLoading extends BoostAdStates {}

class BoostAdPaymentCreated extends BoostAdStates {
  CreatePaymentModel createPaymentModel;
  BoostAdPaymentCreated(this.createPaymentModel);
}

class BoostAdPaymentVerified extends BoostAdStates {
  AdSuccessModel successModel;
  BoostAdPaymentVerified(this.successModel);
}

class BoostAdFailure extends BoostAdStates {
  String error;
  BoostAdFailure(this.error);
}