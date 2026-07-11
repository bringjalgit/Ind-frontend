import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../model/SelectCityModel.dart';
import 'city_repository.dart';
import 'city_state.dart';

class SelectCityCubit extends Cubit<SelectCity> {
  final SelectCityRepository selectCityRepository;

  SelectCityCubit(this.selectCityRepository) : super(SelectCityInitially());

  SelectCityModel selectCityModel = SelectCityModel();

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  Future<void> getSelectCity(int stateId, String search) async {
    emit(SelectCityLoading());
    _currentPage = 1;

    try {
      final response = await selectCityRepository.getCity(
        stateId,
        search,
        _currentPage, // 👈 pass page
      );

      if (response != null && response.success == true) {
        selectCityModel = response;
        _hasNextPage = response.settings?.nextPage ?? false;

        emit(SelectCityLoaded(selectCityModel, _hasNextPage));
      } else {
        emit(SelectCityFailure(response?.message ?? "Failure To Load Data"));
      }
    } catch (e) {
      emit(SelectCityFailure(e.toString()));
    }
  }

  Future<void> getMoreCities(int stateId, String search) async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    _currentPage++;

    emit(SelectCityLoadingMore(selectCityModel, _hasNextPage));

    try {
      final newData = await selectCityRepository.getCity(
        stateId,
        search,
        _currentPage, // 👈 pass page for pagination
      );

      if (newData != null && newData.data?.isNotEmpty == true) {
        final combinedData = List<CityData>.from(selectCityModel.data ?? [])
          ..addAll(newData.data!);

        selectCityModel = SelectCityModel(
          success: newData.success,
          message: newData.message,
          status: newData.status,
          data: combinedData,
          settings: newData.settings,
        );

        _hasNextPage = newData.settings?.nextPage ?? false;

        emit(SelectCityLoaded(selectCityModel, _hasNextPage));
      }
    } catch (e) {
      print("City pagination error: $e");
    } finally {
      _isLoadingMore = false;
    }
  }
}

