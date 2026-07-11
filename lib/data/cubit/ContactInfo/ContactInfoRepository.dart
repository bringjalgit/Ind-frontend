
// repository
import '../../../model/ContactInfoModel.dart';
import '../../remote_data_source.dart';

abstract class ContactInfoRepository {
  Future<ContactInfoModel?> getContactInfo();
}

class ContactInfoRepositoryImpl implements ContactInfoRepository {
  RemoteDataSource remoteDataSource;
  ContactInfoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ContactInfoModel?> getContactInfo() async {
    return await remoteDataSource.getContactInfo();
  }
}