import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class PetsAdRepository {
  Future<AdSuccessModel?> postPetsAd(Map<String, dynamic> data);
}

class PetsAdImpl implements PetsAdRepository {
  RemoteDataSource remoteDataSource;
  PetsAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postPetsAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postPetsAd(data);
  }
}
