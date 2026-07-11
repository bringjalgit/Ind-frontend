import 'package:flutter_bloc/flutter_bloc.dart';
import 'pets_ad_repo.dart';
import 'pets_ad_states.dart';

class PetsAdCubit extends Cubit<PetsAdStates> {
  PetsAdRepository petsAdRepository;
  PetsAdCubit(this.petsAdRepository) : super(PetsAdInitially());

  Future<void> postPetsAd(Map<String, dynamic> data) async {
    emit(PetsAdLoading());
    try {
      final response = await petsAdRepository.postPetsAd(data);
      if (response != null && response.success == true) {
        emit(PetsAdSuccess(response));
      } else {
        emit(PetsAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(PetsAdFailure(e.toString()));
    }
  }
}
