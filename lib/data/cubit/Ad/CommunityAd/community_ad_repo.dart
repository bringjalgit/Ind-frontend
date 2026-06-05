import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class CommunityAdRepository {
  Future<AdSuccessModel?> postCommunityAd(Map<String, dynamic> data);
}

class CommunityAdImpl implements CommunityAdRepository {
  RemoteDataSource remoteDataSource;
  CommunityAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postCommunityAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postCommunityAd(data);
  }
}
