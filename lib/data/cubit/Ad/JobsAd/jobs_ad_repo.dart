import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class JobsAdRepository {
  Future<AdSuccessModel?> postJobsAd(Map<String, dynamic> data);
}

class JobsAdImpl implements JobsAdRepository {
  RemoteDataSource remoteDataSource;
  JobsAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postJobsAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postJobsAd(data);
  }
}
