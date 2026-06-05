
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Advertisement/advertisement_repo.dart';
import 'advertisement_details_states.dart';

class AdvertisementDetailsCubit extends Cubit<AdvertisementDetailsStates> {
  AdvertisementRepo advertisementRepo;
  AdvertisementDetailsCubit(this.advertisementRepo) : super(AdvertisementDetailsInitially());

  Future<void> getAdvertisementDetails() async {
    emit(AdvertisementDetailsLoading());
    try {
      final response = await advertisementRepo.getAdvertisementDetails();
      if (response != null && response.success == true) {
        emit(AdvertisementDetailsLoaded(response));
      } else {
        emit(AdvertisementDetailsFailure("Failed Loading Details!"));
      }
    } catch (e) {
      emit(AdvertisementDetailsFailure(e.toString()));
    }
  }
}