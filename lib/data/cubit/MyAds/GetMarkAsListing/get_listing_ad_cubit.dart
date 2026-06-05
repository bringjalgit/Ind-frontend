import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../model/getListingAdModel.dart';
import '../my_ads_repo.dart';
import 'get_listing_ad_state.dart';

class GetListingAdCubit extends Cubit<GetListingAdState> {
  MyAdsRepo myAdsRepo;

  GetListingAdCubit(this.myAdsRepo) : super(GetListingAdInitially());

  Future<getListingAdModel?> getListingAd(String id) async {
    emit(GetListingAdLoading());
    try {
      final response = await myAdsRepo.markAsgetListingAD(id);
      if (response != null && response.success == true) {
        emit(GetListingAdLoaded(response));
        return response;
      } else {
        emit(GetListingAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(GetListingAdFailure(e.toString()));
    }
  }
}
