import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/AadhaarStatusModel.dart';

abstract class AadhaarRepo {
  Future<AadhaarStatusModel?> getStatus();
  Future<Map<String, String>> uploadImage({
    required String side,
    required String localPath,
  });
  Future<AadhaarStatusModel?> submit({
    required String frontUrl,
    required String backUrl,
  });
}

class AadhaarRepoImpl implements AadhaarRepo {
  final RemoteDataSource remoteDataSource;
  AadhaarRepoImpl({required this.remoteDataSource});

  @override
  Future<AadhaarStatusModel?> getStatus() =>
      remoteDataSource.getAadhaarStatus();

  @override
  Future<Map<String, String>> uploadImage({
    required String side,
    required String localPath,
  }) =>
      remoteDataSource.uploadAadhaarImage(side: side, localPath: localPath);

  @override
  Future<AadhaarStatusModel?> submit({
    required String frontUrl,
    required String backUrl,
  }) =>
      remoteDataSource.submitAadhaar(frontUrl: frontUrl, backUrl: backUrl);
}
