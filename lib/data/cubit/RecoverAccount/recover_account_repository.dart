import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/AdSuccessModel.dart';

abstract class RecoverAccountRepo {
  Future<AdSuccessModel?> recoverAccount(String recoveryToken);
}

class RecoverAccountRepoImpl implements RecoverAccountRepo {
  RemoteDataSource remoteDataSource;
  RecoverAccountRepoImpl({required this.remoteDataSource});

  @override
  Future<AdSuccessModel?> recoverAccount(String recoveryToken) async {
    return await remoteDataSource.recoverAccount(recoveryToken);
  }
}
