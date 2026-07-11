import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Advertisement/advertisement_repo.dart';
import 'package:classifieds/data/cubit/Advertisement/advertisement_states.dart';
import 'package:classifieds/model/AdvertisementModel.dart';

class AdvertisementsCubit extends Cubit<AdvertisementStates> {
  AdvertisementRepo advertisementRepo;
  AdvertisementsCubit(this.advertisementRepo) : super(AdvertisementInitially());

  AdvertisementModel advertisementModel = AdvertisementModel();
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  // Getter to access _hasNextPage from outside the cubit
  bool get hasNextPage => _hasNextPage;

  /// Initial fetch (reset to page 1)
  Future<void> getAdvertisements(String type) async {
    emit(AdvertisementLoading());
    _currentPage = 1;
    try {
      final response = await advertisementRepo.getAdvertisements(
        _currentPage,
        type,
        // 👈 pass page number
      );
      if (response != null && response.success == true) {
        _hasNextPage = response.settings?.nextPage ?? false;
        emit(AdvertisementLoaded(response, _hasNextPage));
      } else {
        emit(AdvertisementFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(AdvertisementFailure(e.toString()));
    }
  }

  /// Load more advertisements (pagination)
  Future<void> getMoreAdvertisements(String type) async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    _currentPage++;

    emit(
      AdvertisementLoadingMore(advertisementModel, _hasNextPage),
    ); // Show loading indicator for more ads

    try {
      final newData = await advertisementRepo.getAdvertisements(
        _currentPage,
        type, // 👈 next page
      );

      if (newData != null && newData.data?.isNotEmpty == true) {
        // Combine the existing and new data (if needed, depending on response structure)
        final combinedData = List.from(advertisementModel.data ?? [])
          ..addAll(newData.data!);

        _hasNextPage = newData.settings?.nextPage ?? false;

        emit(AdvertisementLoaded(newData, _hasNextPage));
      }
    } catch (e) {
      print("Advertisements pagination error: $e");
    } finally {
      _isLoadingMore = false;
    }
  }
}

