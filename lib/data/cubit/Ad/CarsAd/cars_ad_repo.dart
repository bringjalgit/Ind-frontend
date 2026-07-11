import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class CarsAdRepository {
  Future<AdSuccessModel?> postCarsAd(Map<String, dynamic> data);
}

class CarsAdImpl implements CarsAdRepository {
  RemoteDataSource remoteDataSource;
  CarsAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postCarsAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postCarsAd(data);
  }
}
