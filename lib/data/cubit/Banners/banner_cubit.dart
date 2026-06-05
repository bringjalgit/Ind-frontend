import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Banners/banner_repository.dart';
import 'package:classifieds/data/cubit/Banners/banner_states.dart';

class BannerCubit extends Cubit<BannerStates> {
  BannersRepository bannersRepository;
  BannerCubit(this.bannersRepository) : super(BannerInitially());

  Future<void> getBanners() async {
    emit(BannerLoading());
    try {
      final response = await bannersRepository.getBanners();
      if (response != null && response.success == true) {
        emit(BannerLoaded(response));
      } else {
        emit(BannerFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(BannerFailure(e.toString()));
    }
  }
}
