import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class CoWorkingAdRepository {
  Future<AdSuccessModel?> postCoWorkingAd(Map<String, dynamic> data);
}

class CoWorkingAdImpl implements CoWorkingAdRepository {
  RemoteDataSource remoteDataSource;
  CoWorkingAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postCoWorkingAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postCoWorkingAd(data);
  }
}
