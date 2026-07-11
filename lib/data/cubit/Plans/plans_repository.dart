import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/PlansModel.dart';
import 'package:classifieds/model/UserActivePlansModel.dart';

abstract class PlansRepository {
  Future<PlansModel?> getPlans();
  Future<UserActivePlansModel?> getUserActivePlans();
}

class PlansRepositoryImpl implements PlansRepository {
  RemoteDataSource remoteDataSource;
  PlansRepositoryImpl({required this.remoteDataSource});
  @override
  Future<PlansModel?> getPlans() async {
    return await remoteDataSource.getPlans();
  }

  @override
  Future<UserActivePlansModel?> getUserActivePlans() async{
    return await remoteDataSource.getUserActivePlans();
  }
}
