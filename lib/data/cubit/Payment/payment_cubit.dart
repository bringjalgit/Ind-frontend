import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Payment/payment_repository.dart';
import 'package:classifieds/data/cubit/Payment/payment_states.dart';

class PaymentCubit extends Cubit<PaymentStates> {
  PaymentRepository paymentRepository;
  PaymentCubit(this.paymentRepository) : super(PaymentInitially());

  Future<void> createPayment(Map<String, dynamic> data) async {
    emit(PaymentLoading());
    try {
      final response = await paymentRepository.createPayment(data);
      if (response != null && response.success == true) {
        emit(PaymentCreated(response));
      } else {
        emit(PaymentFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> verifyPayment(Map<String, dynamic> data) async {
    emit(PaymentLoading());
    try {
      final response = await paymentRepository.verifyPayment(data);
      if (response != null && response.success==true) {
        emit(PaymentVerified(response));
      } else {
        emit(PaymentFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

}
