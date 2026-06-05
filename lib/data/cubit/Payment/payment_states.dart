import 'package:classifieds/model/CreatePaymentModel.dart';

import '../../../model/AdSuccessModel.dart';


abstract class PaymentStates {}

class PaymentInitially extends PaymentStates {}

class PaymentLoading extends PaymentStates {}

class PaymentCreated extends PaymentStates {
  CreatePaymentModel createPaymentModel;
  PaymentCreated(this.createPaymentModel);
}

class PaymentVerified extends PaymentStates {
  AdSuccessModel successModel;
  PaymentVerified(this.successModel);
}

class PaymentFailure extends PaymentStates {
  String error;
  PaymentFailure(this.error);
}
