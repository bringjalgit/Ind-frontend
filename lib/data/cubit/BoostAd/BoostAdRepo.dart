import '../../../model/AdSuccessModel.dart';
import '../../../model/CreatePaymentModel.dart';
import '../../remote_data_source.dart';

abstract class BoostAdRepository {
  Future<CreatePaymentModel?> boostAdCreatePayment(Map<String, dynamic> data);
  Future<AdSuccessModel?> boostAdVerifyPayment(Map<String, dynamic> data);
}

class BoostAdRepositoryImpl implements BoostAdRepository {
  RemoteDataSource remoteDataSource;
  BoostAdRepositoryImpl({required this.remoteDataSource});
  @override
  Future<CreatePaymentModel?> boostAdCreatePayment(
    Map<String, dynamic> data,
  ) async {
    return await remoteDataSource.boostAdCreatePayment(data);
  }

  @override
  Future<AdSuccessModel?> boostAdVerifyPayment(
    Map<String, dynamic> data,
  ) async {
    return await remoteDataSource.boostAdVerifyPayment(data);
  }
}
