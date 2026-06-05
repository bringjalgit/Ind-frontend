import 'package:classifieds/model/SubcategoryProductsModel.dart';

abstract class ProductsStates {}

class ProductsInitially extends ProductsStates {}

class ProductsLoading extends ProductsStates {}

class ProductsLoadingMore extends ProductsStates {
  final SubcategoryProductsModel productsModel;
  final bool hasNextPage;

  ProductsLoadingMore(this.productsModel, this.hasNextPage);
}

class ProductsLoaded extends ProductsStates {
  final SubcategoryProductsModel productsModel;
  final bool hasNextPage;

  ProductsLoaded(this.productsModel, this.hasNextPage);
}

class ProductsFailure extends ProductsStates {
  final String error;
  ProductsFailure(this.error);
}
