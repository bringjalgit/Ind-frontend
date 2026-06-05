import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class CityRentalsAdRepository {
  Future<AdSuccessModel?> postCityRentalsAd(Map<String, dynamic> data);
}

class CityRentalsAdImpl implements CityRentalsAdRepository {
  RemoteDataSource remoteDataSource;
  CityRentalsAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postCityRentalsAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postCityRentalsAd(data);
  }
}
