import 'package:flutter_bloc/flutter_bloc.dart';

import 'FreeAdRepository.dart';
import 'FreeAdStates.dart';

class FreeAdCubit extends Cubit<FreeAdStates> {
  FreeAdRepository freeAdRepository;

  FreeAdCubit(this.freeAdRepository) : super(FreeAdInitially());

  Future<void> getFreeAd() async {
    emit(FreeAdLoading());
    try {
      final response = await freeAdRepository.getFreeAd();
      if (response != null && response.success == true) {
        emit(FreeAdLoaded(response));
      } else {
        emit(FreeAdFailure("Something went wrong"));
      }
    } catch (e) {
      emit(FreeAdFailure(e.toString()));
    }
  }
}