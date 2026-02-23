import '../../../model/FreeAdModel.dart';
import '../../remote_data_source.dart';

abstract class FreeAdRepository {
  Future<FreeAdModel?> getFreeAd();
}

class FreeAdRepositoryImpl implements FreeAdRepository {
  RemoteDataSource remoteDataSource;

  FreeAdRepositoryImpl({required this.remoteDataSource});

  @override
  Future<FreeAdModel?> getFreeAd() async {
    return await remoteDataSource.getFreeAd();
  }
}