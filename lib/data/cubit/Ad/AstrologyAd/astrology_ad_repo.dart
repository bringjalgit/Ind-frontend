import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class AstrologyAdRepository {
  Future<AdSuccessModel?> postAstrologyAd(Map<String, dynamic> data);
}

class AstrologyAdImpl implements AstrologyAdRepository {
  RemoteDataSource remoteDataSource;
  AstrologyAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postAstrologyAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postAstrologyAd(data);
  }
}
