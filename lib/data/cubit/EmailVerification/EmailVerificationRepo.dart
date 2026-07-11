import '../../../model/AdSuccessModel.dart';
import '../../remote_data_source.dart';

abstract class EmailVerificationRepo {
  Future<AdSuccessModel?> sendOTP(Map<String, dynamic> data);
  Future<AdSuccessModel?> verifyOTP(Map<String, dynamic> data);
}

class EmailVerificationRepoImpl implements EmailVerificationRepo {
  final RemoteDataSource remoteDataSource;

  EmailVerificationRepoImpl({required this.remoteDataSource});

  @override
  Future<AdSuccessModel?> sendOTP(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.sendOTP(data);
    } catch (e) {
      throw Exception('Failed to send OTP');
    }
  }

  @override
  Future<AdSuccessModel?> verifyOTP(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.verifyOTP(data);
    } catch (e) {
      throw Exception('Failed to verify OTP');
    }
  }
}
