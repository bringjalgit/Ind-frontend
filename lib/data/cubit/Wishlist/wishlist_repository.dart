import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/AddToWishlistModel.dart';
import 'package:classifieds/model/SubcategoryProductsModel.dart';

import '../../../model/WishlistModel.dart';

abstract class WishlistRepository {
  Future<WishlistModel?> getWishlist(int page);
  Future<AddToWishlistModel?> addToWishlist(String product_id);
}

class WishlistRepositoryImpl implements WishlistRepository {
  RemoteDataSource remoteDataSource;
  WishlistRepositoryImpl({required this.remoteDataSource});

  @override
  Future<WishlistModel?> getWishlist(int page) async {
    return await remoteDataSource.getWishlistProducts(page);
  }

  @override
  Future<AddToWishlistModel?> addToWishlist(String product_id) async {
    return await remoteDataSource.addToWishlist(product_id);
  }
}
