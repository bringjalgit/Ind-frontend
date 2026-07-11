import 'package:flutter_bloc/flutter_bloc.dart';
import 'bikes_ad_repo.dart';
import 'bikes_ad_states.dart';

class BikesAdCubit extends Cubit<BikesAdStates> {
  BikeAdRepository propertyAdRepository;
  BikesAdCubit(this.propertyAdRepository) : super(BikesAdInitially());

  Future<void> postBikeAd(Map<String, dynamic> data) async {
    emit(BikesAdLoading());
    try {
      final response = await propertyAdRepository.postBikeAd(data);
      if (response != null && response.success == true) {
        emit(BikesAdSuccess(response));
      } else {
        emit(BikesAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(BikesAdFailure(e.toString()));
    }
  }
}
