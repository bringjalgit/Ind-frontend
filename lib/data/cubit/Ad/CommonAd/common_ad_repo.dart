import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class CommonAdRepository {
  Future<AdSuccessModel?> postCommonAd(Map<String, dynamic> data);
}

class CommonAdImpl implements CommonAdRepository {
  RemoteDataSource remoteDataSource;
  CommonAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postCommonAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postCommonAd(data);
  }
}
