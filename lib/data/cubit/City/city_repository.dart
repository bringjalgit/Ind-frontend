import 'package:classifieds/model/SelectCityModel.dart';
import '../../remote_data_source.dart';

abstract class SelectCityRepository {
  Future<SelectCityModel?> getCity(int state_id, String search, int page);
}

class SelectCityImpl implements SelectCityRepository {
  RemoteDataSource remoteDataSource;
  SelectCityImpl({required this.remoteDataSource});
  @override
  Future<SelectCityModel?> getCity(
    int state_id,
    String search,
    int page,
  ) async {
    return await remoteDataSource.getCity(state_id, search, page);
  }
}
