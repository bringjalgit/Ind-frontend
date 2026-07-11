import 'package:classifieds/model/SubcategoryProductsModel.dart';

import '../../../model/WishlistModel.dart';

abstract class WishlistStates {}

class WishlistInitially extends WishlistStates {}

class WishlistLoading extends WishlistStates {}

class WishlistLoadingMore extends WishlistStates {
  final WishlistModel wishlistModel;
  final bool hasNextPage;

  WishlistLoadingMore(this.wishlistModel, this.hasNextPage);
}

class WishlistLoaded extends WishlistStates {
  final WishlistModel wishlistModel;
  final bool hasNextPage;

  WishlistLoaded(this.wishlistModel, this.hasNextPage);
}

class WishlistFailure extends WishlistStates {
  final String error;
  WishlistFailure(this.error);
}
