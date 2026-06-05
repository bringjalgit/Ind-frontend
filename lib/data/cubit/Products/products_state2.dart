import 'package:classifieds/model/SubcategoryProductsModel.dart';

abstract class ProductsStates2 {}

class Products2Initially extends ProductsStates2 {}

class Products2Loading extends ProductsStates2 {}

class Products2LoadingMore extends ProductsStates2 {
  final SubcategoryProductsModel productsModel;
  final bool hasNextPage;

  Products2LoadingMore(this.productsModel, this.hasNextPage);
}

class Products2Loaded extends ProductsStates2 {
  final SubcategoryProductsModel productsModel;
  final bool hasNextPage;

  Products2Loaded(this.productsModel, this.hasNextPage);
}

class Products2Failure extends ProductsStates2 {
  final String error;
  Products2Failure(this.error);
}
