import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../model/PlanModel.dart';
import 'SubscriptionRepository.dart';
import 'SubscriptionState.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final SubscriptionRepository repository;
  final InAppPurchase _iap = InAppPurchase.instance;

  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];

  // Expose purchases publicly as unmodifiable list
  List<PurchaseDetails> get purchases => List.unmodifiable(_purchases);

  SubscriptionCubit(this.repository) : super(SubscriptionInitial()) {
    listenToPurchaseUpdates();
  }

  Future<void> loadPlans(List<PlanModel> plans) async {
    emit(SubscriptionLoading());
    try {
      final ids = plans.map((p) => p.productId).toSet();

      // Query product details
      final response = await _iap.queryProductDetails(ids);
      _products = response.productDetails;

      // Restore purchases before emitting loaded state
      await _restorePurchases();

      emit(SubscriptionLoaded(plans, _products, List.unmodifiable(_purchases)));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> buyPlan(PlanModel plan) async {
    final product = _products.firstWhere(
      (p) => p.id == plan.productId,
      orElse: () => throw Exception('Product not found'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void listenToPurchaseUpdates() {
    _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          bool valid = await _verifyPurchase(purchase);
          if (valid) {
            if (!_purchases.any((p) => p.purchaseID == purchase.purchaseID)) {
              _purchases.add(purchase);
            }
            await _sendPurchaseToServer(purchase);

            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }

            // If currently loaded, update state with new purchases
            if (state is SubscriptionLoaded) {
              final current = state as SubscriptionLoaded;
              emit(
                SubscriptionLoaded(
                  current.plans,
                  _products,
                  List.unmodifiable(_purchases),
                ),
              );
            } else {
              emit(SubscriptionSuccess());
            }
          } else {
            emit(SubscriptionError('Purchase verification failed'));
          }
        } else if (purchase.status == PurchaseStatus.error) {
          emit(SubscriptionError(purchase.error?.message ?? 'Unknown error'));
        }
      }
    });
  }

  Future<void> _restorePurchases() async {
    try {
      final isAvailable = await _iap.isAvailable();
      if (!isAvailable) return;

      await _iap.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // Implement your backend verification logic here
    return true;
  }

  Future<void> _sendPurchaseToServer(PurchaseDetails purchase) async {
    final plan = _products.firstWhere((p) => p.id == purchase.productID);
    final duration = 30; // Replace with actual logic
    final adsCount = 50;

    await repository.sendPurchaseToServer({
      "product_id": purchase.productID,
      "receipt_data": purchase.verificationData.serverVerificationData,
      "duration_days": duration,
      "ads_count": adsCount,
    });
  }
}
