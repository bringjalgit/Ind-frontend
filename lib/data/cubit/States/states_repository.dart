import '../../../model/SelectStatesModel.dart';
import '../../remote_data_source.dart';

abstract class SelectStateRepository {
  Future<SelectStatesModel?> getStates(String search);
}

class SelectStatesImpl implements SelectStateRepository {
  RemoteDataSource remoteDataSource;
  SelectStatesImpl({required this.remoteDataSource});
  @override
  Future<SelectStatesModel?> getStates(String search) async {
    return await remoteDataSource.getStates(search);
  }
}
