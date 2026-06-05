import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/MyAds/MarkAsListing/mark_as_listing_state.dart';
import '../my_ads_repo.dart';

class MarkAsListingCubit extends Cubit<MarkAsListingState> {
  MyAdsRepo myAdsRepo;
  MarkAsListingCubit(this.myAdsRepo) : super(MarkAsListingInitially());

  Future<void> markAsSold(String id) async {
    emit(MarkAsListingLoading());
    try {
      final response = await myAdsRepo.markAsSold(id);
      if (response != null && response.success == true) {
        emit(MarkAsListingSuccess(response));
      } else {
        emit(MarkAsListingFailure("${response?.message ?? ""}.${response?.error ?? ""}"));
      }
    } catch (e) {
      emit(MarkAsListingFailure(e.toString()));
    }
  }

  Future<void> markAsDelete(String id) async {
    emit(MarkAsListingLoading());
    try {
      final response = await myAdsRepo.markAsDelete(id);
      if (response != null && response.success == true) {
        emit(MarkAsListingDeleted(response));
      } else {
        emit(MarkAsListingFailure("${response?.message ?? ""}.${response?.error ?? ""}"));
      }
    } catch (e) {
      emit(MarkAsListingFailure(e.toString()));
    }
  }

  Future<void> markAsUpdate(String id,Map<String,dynamic> data) async {
    emit(MarkAsListingUpdateLoading());
    try {
      final response = await myAdsRepo.markAsUpdate(id,data);
      if (response != null && response.success == true) {
        emit(MarkAsListingUpdateSuccess(response));
      } else {
        emit(MarkAsListingFailure("${response?.message ?? ""}.${response?.error ?? ""}"));
      }
    } catch (e) {
      emit(MarkAsListingFailure(e.toString()));
    }
  }

  Future<void> removeImageOnListingAd(String imageUrl, String listingId) async {
    emit(MarkAsListingLoading());
    try {
      final response = await myAdsRepo.removeImageOnListingAD(imageUrl, listingId);
      if (response != null && response.success == true) {
        emit(MarkAsListingImageDelete(response));
      } else {
        emit(MarkAsListingFailure("${response?.message ?? ""}.${response?.error ?? ""}"));
      }
    } catch (e) {
      emit(MarkAsListingFailure(e.toString()));
    }
  }
}
