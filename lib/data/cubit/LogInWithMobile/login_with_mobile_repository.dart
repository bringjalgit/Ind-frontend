import 'package:classifieds/model/SendOtpModel.dart';
import 'package:classifieds/model/VerifyOtpModel.dart';
import '../../remote_data_source.dart';

abstract class LogInWithMobileRepository {
  Future<SendOtpModel?> SendMobileOtp(Map<String, dynamic> data);
  Future<VerifyOtpModel?> verifyMobileOtp(Map<String, dynamic> data);

  Future<SendOtpModel?> SendEmailOtp(Map<String, dynamic> data);
  Future<VerifyOtpModel?> verifyEmailOtp(Map<String, dynamic> data);
}

class LogInMobileRepositoryImpl implements LogInWithMobileRepository {
  final RemoteDataSource remoteDataSource;
  LogInMobileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SendOtpModel?> SendMobileOtp(Map<String, dynamic> data) async {
    return await remoteDataSource.sendMobileOTP(data);
  }

  Future<VerifyOtpModel?> verifyMobileOtp(Map<String, dynamic> data) async {
    return await remoteDataSource.verifyMobileOTP(data);
  }

  @override
  Future<SendOtpModel?> SendEmailOtp(Map<String, dynamic> data) async {
    return await remoteDataSource.SendEmailOtp(data);
  }

  Future<VerifyOtpModel?> verifyEmailOtp(Map<String, dynamic> data) async {
    return await remoteDataSource.verifyEmailOtp(data);
  }
}
