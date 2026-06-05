
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../model/PlanModel.dart';

abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final List<PlanModel> plans;
  final List<ProductDetails> products;
  final List<PurchaseDetails> purchases;

  SubscriptionLoaded(this.plans, this.products, this.purchases);
}

class SubscriptionError extends SubscriptionState {
  final String message;

  SubscriptionError(this.message);
}

class SubscriptionSuccess extends SubscriptionState {}

