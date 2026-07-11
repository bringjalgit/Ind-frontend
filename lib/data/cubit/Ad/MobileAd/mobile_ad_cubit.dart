import 'package:flutter_bloc/flutter_bloc.dart';
import 'mobile_ad_repo.dart';
import 'mobile_ad_states.dart';

class MobileAdCubit extends Cubit<MobileAdStates> {
  MobileAdRepository mobileAdRepository;
  MobileAdCubit(this.mobileAdRepository) : super(MobileAdInitially());

  Future<void> postMobileAd(Map<String, dynamic> data) async {
    emit(MobileAdLoading());
    try {
      final response = await mobileAdRepository.postMobileAd(data);
      if (response != null && response.success == true) {
        emit(MobileAdSuccess(response));
      } else {
        emit(
          MobileAdFailure(
            "Error:${response?.message ?? ""}.${response?.error ?? ""}",
          ),
        );
      }
    } catch (e) {
      emit(MobileAdFailure(e.toString()));
    }
  }
}
