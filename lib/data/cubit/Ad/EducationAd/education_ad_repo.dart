import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class EducationAdRepository {
  Future<AdSuccessModel?> postEducationAd(Map<String, dynamic> data);
}

class EducationAdImpl implements EducationAdRepository {
  RemoteDataSource remoteDataSource;
  EducationAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postEducationAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postEducationAd(data);
  }
}
