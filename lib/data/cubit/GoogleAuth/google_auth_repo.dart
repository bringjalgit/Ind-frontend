import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/VerifyOtpModel.dart';

abstract class GoogleAuthRepo {
  Future<VerifyOtpModel?> googleAuth(Map<String, dynamic> data);
}

class GoogleAuthRepoImpl implements GoogleAuthRepo {
  final RemoteDataSource remoteDataSource;
  GoogleAuthRepoImpl({required this.remoteDataSource});

  @override
  Future<VerifyOtpModel?> googleAuth(Map<String, dynamic> data) async {
    return await remoteDataSource.googleAuth(data);
  }
}
