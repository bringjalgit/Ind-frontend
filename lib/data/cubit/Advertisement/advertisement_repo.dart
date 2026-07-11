import 'package:classifieds/model/AdvertisementDetailsModel.dart';
import 'package:classifieds/model/AdvertisementModel.dart';

import '../../../model/AdSuccessModel.dart';
import '../../remote_data_source.dart';

abstract class AdvertisementRepo {
  Future<AdvertisementModel?> getAdvertisements(int page,String type);
  Future<AdvertisementDetailsModel?> getAdvertisementDetails();
  Future<AdSuccessModel?> postAdvertisement(Map<String, dynamic> data);
}

class AdvertisementRepoImpl implements AdvertisementRepo {
  RemoteDataSource remoteDataSource;
  AdvertisementRepoImpl({required this.remoteDataSource});

  @override
  Future<AdvertisementModel?> getAdvertisements(int page,String type) async {
    return await remoteDataSource.getAdvertisements(page,type);
  }

  @override
  Future<AdSuccessModel?> postAdvertisement(Map<String, dynamic> data) async {
    return await remoteDataSource.postAdvertisement(data);
  }

  @override
  Future<AdvertisementDetailsModel?> getAdvertisementDetails() async{
    return await remoteDataSource.getAdvertisementDetails();
  }
}
