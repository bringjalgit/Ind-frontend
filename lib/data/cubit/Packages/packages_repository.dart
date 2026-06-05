
import 'package:classifieds/model/PackagesModel.dart';

import '../../remote_data_source.dart';

abstract class PackagesRepository {
  Future<PackagesModel?> getPackages(dynamic id);
}

class PackagesRepositoryImpl implements PackagesRepository {
  RemoteDataSource remoteDataSource;
  PackagesRepositoryImpl({required this.remoteDataSource});
  @override
  Future<PackagesModel?> getPackages(dynamic id) async {
    return await remoteDataSource.getPackages(id);
  }
}
