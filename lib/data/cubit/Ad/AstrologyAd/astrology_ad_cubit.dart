import 'package:flutter_bloc/flutter_bloc.dart';
import 'astrology_ad_repo.dart';
import 'astrology_ad_states.dart';

class AstrologyAdCubit extends Cubit<AstrologyAdStates> {
  AstrologyAdRepository astrologyAdRepository;
  AstrologyAdCubit(this.astrologyAdRepository) : super(AstrologyAdInitially());

  Future<void> postAstrologyAd(Map<String, dynamic> data) async {
    emit(AstrologyAdLoading());
    try {
      final response = await astrologyAdRepository.postAstrologyAd(data);
      if (response != null && response.success == true) {
        emit(AstrologyAdSuccess(response));
      } else {
        emit(AstrologyAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(AstrologyAdFailure(e.toString()));
    }
  }
}
