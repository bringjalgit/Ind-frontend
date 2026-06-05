import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class PropertyAdRepository {
  Future<AdSuccessModel?> postPropertyAd(Map<String, dynamic> data);
}

class PropertyAdImpl implements PropertyAdRepository {
  RemoteDataSource remoteDataSource;
  PropertyAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postPropertyAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postPropertyAd(data);
  }
}
