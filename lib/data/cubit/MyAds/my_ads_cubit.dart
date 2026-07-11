import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/MyAds/my_ads_repo.dart';
import 'package:classifieds/data/cubit/MyAds/my_ads_states.dart';

import '../../../model/MyAdsModel.dart';

class MyAdsCubit extends Cubit<MyAdsStates> {
  final MyAdsRepo myAdsRepo;
  MyAdsCubit(this.myAdsRepo) : super(MyAdsInitially());

  MyAdsModel myAdsModel = MyAdsModel();

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  Future<void> getMyAds(String type) async {
    emit(MyAdsLoading());
    _currentPage = 1;
    try {
      final response = await myAdsRepo.getMyAds(
        type,
        _currentPage, // 👈 pass page number
      );
      if (response != null && response.success == true) {
        myAdsModel = response;
        _hasNextPage = response.settings?.nextPage ?? false;
        emit(MyAdsLoaded(myAdsModel, _hasNextPage));
      } else {
        emit(MyAdsFailure(response?.message ?? "Failed to load ads"));
      }
    } catch (e) {
      emit(MyAdsFailure(e.toString()));
    }
  }

  /// Load more ads (pagination)
  Future<void> getMoreMyAds(String type) async {
    if (_isLoadingMore || !_hasNextPage) return;
    _isLoadingMore = true;
    _currentPage++;
    emit(MyAdsLoadingMore(myAdsModel, _hasNextPage));
    try {
      final newData = await myAdsRepo.getMyAds(
        type,
        _currentPage, // 👈 next page
      );

      if (newData != null && newData.data?.isNotEmpty == true) {
        final combinedData = List<Data>.from(myAdsModel.data ?? [])
          ..addAll(newData.data!);

        myAdsModel = MyAdsModel(
          success: newData.success,
          message: newData.message,
          data: combinedData,
          settings: newData.settings,
        );

        _hasNextPage = newData.settings?.nextPage ?? false;

        emit(MyAdsLoaded(myAdsModel, _hasNextPage));
      }
    } catch (e) {
      print("MyAds pagination error: $e");
    } finally {
      _isLoadingMore = false;
    }
  }
}

