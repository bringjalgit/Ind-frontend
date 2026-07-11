import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class MobileAdRepository {
  Future<AdSuccessModel?> postMobileAd(Map<String, dynamic> data);
}

class MobileAdImpl implements MobileAdRepository {
  RemoteDataSource remoteDataSource;
  MobileAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postMobileAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postMobileAd(data);
  }
}
