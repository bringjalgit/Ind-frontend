import 'package:flutter_bloc/flutter_bloc.dart';
import '../PropertyAd/property_ad_repo.dart';
import 'cars_ad_repo.dart';
import 'cars_ad_states.dart';

class CarsAdCubit extends Cubit<CarsAdStates> {
  CarsAdRepository carsAdRepository;
  CarsAdCubit(this.carsAdRepository) : super(CarsAdInitially());

  Future<void> postCarsAd(Map<String, dynamic> data) async {
    emit(CarsAdLoading());
    try {
      final response = await carsAdRepository.postCarsAd(data);
      if (response != null && response.success == true) {
        emit(CarsAdSuccess(response));
      } else {
        emit(CarsAdFailure("${response?.message ?? ""}.${response?.error ?? ""}."));
      }
    } catch (e) {
      emit(CarsAdFailure(e.toString()));
    }
  }
}
