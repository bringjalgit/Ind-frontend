import 'package:classifieds/model/ProductDetailsModel.dart';

abstract class ProductDetailsStates {}

class ProductDetailsInitially extends ProductDetailsStates {}

class ProductDetailsLoading extends ProductDetailsStates {}

class ProductDetailsLoaded extends ProductDetailsStates {
  ProductDetailsModel productDetailsModel;
  ProductDetailsLoaded(this.productDetailsModel);
}

class ProductDetailsFailure extends ProductDetailsStates {
  String error;
  ProductDetailsFailure(this.error);
}
