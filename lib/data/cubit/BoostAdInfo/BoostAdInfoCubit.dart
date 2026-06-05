import 'package:flutter_bloc/flutter_bloc.dart';

import 'BoostAdInfoRepo.dart';
import 'BoostAdInfoStates.dart';

class BoostAdInfoCubit extends Cubit<BoostAdInfoStates> {
  final BoostAdInfoRepo boostAdInfoRepo;

  BoostAdInfoCubit(this.boostAdInfoRepo) : super(BoostAdInfoInitially());

  Future<void> getBoostAdInfoDetails() async {
    emit(BoostAdInfoLoading());
    try {
      final response = await boostAdInfoRepo.getBoostAdInfoDetails();
      if (response != null && response.success == true) {
        emit(BoostAdInfoLoaded(response));
      } else {
        emit(BoostAdInfoFailure("Failed to load Boost Ad Info details!"));
      }
    } catch (e) {
      emit(BoostAdInfoFailure(e.toString()));
    }
  }
}
