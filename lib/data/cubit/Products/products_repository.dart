import 'package:classifieds/data/remote_data_source.dart';

import '../../../model/SubcategoryProductsModel.dart';

abstract class ProductsRepo {
  Future<SubcategoryProductsModel?> getProducts({
    required int page,
    String? categoryId,
    String? subCategoryId,
    String? search,
    String? state_id,
    String? city_id,
    String? sort_by,
    String? minPrice,
    String? maxPrice,
    String? locationKey,
    bool? expand,
  });
}

class ProductsRepoImpl implements ProductsRepo {
  final RemoteDataSource remoteDataSource;

  ProductsRepoImpl({required this.remoteDataSource});

  @override
  Future<SubcategoryProductsModel?> getProducts({
    required int page,
    String? categoryId,
    String? subCategoryId,
    String? search,
    String? state_id,
    String? city_id,
    String? sort_by,
    String? minPrice,
    String? maxPrice,
    String? locationKey,
    bool? expand,
  }) async {
    return await remoteDataSource.getProducts(
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      search: search,
      state_id: state_id,
      city_id: city_id,
      sort_by: sort_by,
      minPrice: minPrice,
      maxPrice: maxPrice,
      page: page,
      locationKey: locationKey,
      expand: expand,
    );
  }
}
