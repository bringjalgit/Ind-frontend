import 'package:flutter_bloc/flutter_bloc.dart';
import 'co_working_ad_repo.dart';
import 'co_working_ad_states.dart';

class CoWorkingAdCubit extends Cubit<CoWorkingAdStates> {
  CoWorkingAdRepository coWorkingAdRepository;
  CoWorkingAdCubit(this.coWorkingAdRepository) : super(CoWorkingAdInitially());

  Future<void> postCoWorkingAd(Map<String, dynamic> data) async {
    emit(CoWorkingAdLoading());
    try {
      final response = await coWorkingAdRepository.postCoWorkingAd(data);
      if (response != null && response.success == true) {
        emit(CoWorkingAdSuccess(response));
      } else {
        emit(CoWorkingAdFailure("${response?.message ?? ""}.${response?.error ?? ""}"));
      }
    } catch (e) {
      emit(CoWorkingAdFailure(e.toString()));
    }
  }
}
