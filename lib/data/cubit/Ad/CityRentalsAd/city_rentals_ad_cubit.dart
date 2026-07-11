import 'package:flutter_bloc/flutter_bloc.dart';
import 'city_rentals_ad_repo.dart';
import 'city_rentals_ad_states.dart';

class CityRentalsAdCubit extends Cubit<CityRentalsAdStates> {
  CityRentalsAdRepository cityRentalsAdRepository;
  CityRentalsAdCubit(this.cityRentalsAdRepository) : super(CityRentalsAdInitially());

  Future<void> postCityRentalsAd(Map<String, dynamic> data) async {
    emit(CityRentalsAdLoading());
    try {
      final response = await cityRentalsAdRepository.postCityRentalsAd(data);
      if (response != null && response.success == true) {
        emit(CityRentalsAdSuccess(response));
      } else {
        emit(CityRentalsAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(CityRentalsAdFailure(e.toString()));
    }
  }
}
