import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/CategoryModel.dart';

abstract class CategoriesRepo {
  Future<CategoryModel?> getCategories();
  Future<CategoryModel?> getNewCategories();
  Future<CategoryModel?> getPostCategories();
}

class CategoriesRepoImpl implements CategoriesRepo {
  RemoteDataSource remoteDataSource;
  CategoriesRepoImpl({required this.remoteDataSource});

  @override
  Future<CategoryModel?> getCategories() async {
    return await remoteDataSource.getCategory();
  }

  @override
  Future<CategoryModel?> getNewCategories() async {
    return await remoteDataSource.getNewCategory();
  }

  @override
  Future<CategoryModel?> getPostCategories() async{
    return await remoteDataSource.getPostCategories();
  }
}
