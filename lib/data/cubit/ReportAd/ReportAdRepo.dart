
import '../../../model/AdSuccessModel.dart';
import '../../remote_data_source.dart';

abstract class ReportAdRepo {
  Future<AdSuccessModel?> reportAd(Map<String, dynamic> data);
}

class ReportAdRepoImpl implements ReportAdRepo {
  final RemoteDataSource remoteDataSource; // keep your existing data source type

  ReportAdRepoImpl({required this.remoteDataSource});

  @override
  Future<AdSuccessModel?> reportAd(Map<String, dynamic> data) async {
    return await remoteDataSource.reportAd(data);
  }
}


