import 'package:flutter_bloc/flutter_bloc.dart';
import 'common_ad_repo.dart';
import 'common_ad_states.dart';

class CommonAdCubit extends Cubit<CommonAdStates> {
  CommonAdRepository commonAdRepository;
  CommonAdCubit(this.commonAdRepository) : super(CommonAdInitially());

  Future<void> postCommonAd(Map<String, dynamic> data) async {
    emit(CommonAdLoading());
    try {
      final response = await commonAdRepository.postCommonAd(data);
      if (response != null && response.success == true) {
        emit(CommonAdSuccess(response));
      } else {
        emit(CommonAdFailure("${response?.message ?? ""}.${response?.error ?? ""}"));
      }
    } catch (e) {
      emit(CommonAdFailure(e.toString()));
    }
  }
}
