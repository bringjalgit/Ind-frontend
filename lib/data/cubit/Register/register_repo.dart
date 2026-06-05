import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/AdSuccessModel.dart';

abstract class RegisterRepo {
  Future<AdSuccessModel?> register(Map<String, dynamic> data);
}

class RegisterRepoImpl implements RegisterRepo {
  RemoteDataSource remoteDataSource;
  RegisterRepoImpl({required this.remoteDataSource});

  @override
  Future<AdSuccessModel?> register(Map<String, dynamic> data) async {
    return await remoteDataSource.register(data);
  }
}
