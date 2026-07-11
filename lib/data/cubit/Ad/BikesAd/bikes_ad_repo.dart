import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class BikeAdRepository {
  Future<AdSuccessModel?> postBikeAd(Map<String, dynamic> data);
}

class BikeAdImpl implements BikeAdRepository {
  RemoteDataSource remoteDataSource;
  BikeAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postBikeAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postBikeAd(data);
  }
}
