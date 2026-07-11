import '../../../model/AdSuccessModel.dart';
import '../../remote_data_source.dart';

abstract class DeleteAccountRepo {
  Future<AdSuccessModel?> deleteAccount();
}

class DeleteAccountRepoImpl implements DeleteAccountRepo {
  RemoteDataSource remoteDataSource;
  DeleteAccountRepoImpl({required this.remoteDataSource});

  @override
  Future<AdSuccessModel?> deleteAccount() async {
    return await remoteDataSource.deleteAccount();
  }
}
