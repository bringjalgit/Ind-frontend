import '../../../model/SubCategoryModel.dart';
import '../../remote_data_source.dart';

abstract class SubCategoryRepository {
  Future<SubCategoryModel?> getSubCategory(String categoryId);
}

class SubCategoryRepositoryImpl implements SubCategoryRepository {
  RemoteDataSource remoteDataSource;
  SubCategoryRepositoryImpl({required this.remoteDataSource});
  @override
  Future<SubCategoryModel?> getSubCategory(String categoryId) async {
    return await remoteDataSource.getSubCategory(categoryId);
  }
}
