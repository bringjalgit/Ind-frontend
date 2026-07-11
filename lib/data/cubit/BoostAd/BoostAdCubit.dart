import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/BoostAd/BoostAdRepo.dart';
import 'package:classifieds/data/cubit/BoostAd/BoostAdStates.dart';

class BoostAdCubit extends Cubit<BoostAdStates> {
  BoostAdRepository boostAdRepository;
  BoostAdCubit(this.boostAdRepository) : super(BoostAdInitially());

  Future<void> createPayment(Map<String, dynamic> data) async {
    emit(BoostAdLoading());
    try {
      final response = await boostAdRepository.boostAdCreatePayment(data);
      if (response != null && response.success == true) {
        emit(BoostAdPaymentCreated(response));
      } else {
        emit(BoostAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(BoostAdFailure(e.toString()));
    }
  }

  Future<void> verifyPayment(Map<String, dynamic> data) async {
    emit(BoostAdLoading());
    try {
      final response = await boostAdRepository.boostAdVerifyPayment(data);
      if (response != null && response.success == true) {
        emit(BoostAdPaymentVerified(response));
      } else {
        emit(BoostAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(BoostAdFailure(e.toString()));
    }
  }
}
