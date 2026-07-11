import 'package:classifieds/model/BoostAdModel.dart';

import '../../remote_data_source.dart';

abstract class BoostAdInfoRepo {
  Future<BoostAdModel?> getBoostAdInfoDetails();
}

class BoostAdInfoRepoImpl implements BoostAdInfoRepo {
  final RemoteDataSource remoteDataSource;

  BoostAdInfoRepoImpl({required this.remoteDataSource});

  @override
  Future<BoostAdModel?> getBoostAdInfoDetails() async {
    return await remoteDataSource.getBoostAdInfoDetails();
  }

}
