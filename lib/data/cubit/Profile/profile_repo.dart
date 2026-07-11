import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/AdSuccessModel.dart';
import 'package:classifieds/model/ProfileModel.dart';

abstract class ProfileRepo {
  Future<ProfileModel?> getProfileDetails();
  Future<AdSuccessModel?> updateProfileDetails(Map<String, dynamic> data);
}

class ProfileRepoImpl implements ProfileRepo {
  RemoteDataSource remoteDataSource;
  ProfileRepoImpl({required this.remoteDataSource});

  @override
  Future<ProfileModel?> getProfileDetails() async {
    return await remoteDataSource.getProfileDetails();
  }

  @override
  Future<AdSuccessModel?> updateProfileDetails(
    Map<String, dynamic> data,
  ) async {
    return await remoteDataSource.updateProfileDetails(data);
  }
}
