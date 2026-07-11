import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/PostAdvertisement/post_advertisement_states.dart';

import '../Advertisement/advertisement_repo.dart';

class PostAdvertisementsCubit extends Cubit<PostAdvertisementStates> {
  AdvertisementRepo advertisementRepo;
  PostAdvertisementsCubit(this.advertisementRepo)
    : super(PostAdvertisementInitially());

  Future<void> postAdvertisement(Map<String, dynamic> data) async {
    emit(PostAdvertisementLoading());
    try {
      final response = await advertisementRepo.postAdvertisement(data);
      if (response != null && response.success == true) {
        emit(PostAdvertisementLoaded(response));
      } else {
        emit(PostAdvertisementFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(PostAdvertisementFailure(e.toString()));
    }
  }
}
