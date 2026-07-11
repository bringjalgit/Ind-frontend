import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../remote_data_source.dart';

abstract class CommercialVehileAdRepository {
  Future<AdSuccessModel?> postCommercialVehileAd(Map<String, dynamic> data);
}

class CommercialVehileAdImpl implements CommercialVehileAdRepository {
  RemoteDataSource remoteDataSource;
  CommercialVehileAdImpl({required this.remoteDataSource});
  @override
  Future<AdSuccessModel?> postCommercialVehileAd(Map<String, dynamic> data) async {
    return await remoteDataSource.postCommercialVehicleAd(data);
  }
}
