import 'package:classifieds/model/SubcategoryProductsModel.dart';

abstract class ProductsStates1 {}

class Products1Initially extends ProductsStates1 {}

class Products1Loading extends ProductsStates1 {}

class Products1LoadingMore extends ProductsStates1 {
  final SubcategoryProductsModel productsModel;
  final bool hasNextPage;

  Products1LoadingMore(this.productsModel, this.hasNextPage);
}

class Products1Loaded extends ProductsStates1 {
  final SubcategoryProductsModel productsModel;
  final bool hasNextPage;

  Products1Loaded(this.productsModel, this.hasNextPage);
}

class Products1Failure extends ProductsStates1 {
  final String error;
  Products1Failure(this.error);
}
