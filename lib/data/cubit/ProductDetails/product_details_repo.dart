import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/ProductDetailsModel.dart';

abstract class ProductDetailsRepo {
  Future<ProductDetailsModel?> getProductDetails(String id);
}

class ProductDetailsRepoImpl implements ProductDetailsRepo {
  RemoteDataSource remoteDataSource;
  ProductDetailsRepoImpl({required this.remoteDataSource});
  @override
  Future<ProductDetailsModel?> getProductDetails(String id) async {
    return await remoteDataSource.getProductDetails(id);
  }
}
