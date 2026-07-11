import 'package:classifieds/model/CategoryModel.dart';

abstract class CategoriesStates {}

class CategoriesInitially extends CategoriesStates {}

class CategoriesLoading extends CategoriesStates {}

class CategoriesLoaded extends CategoriesStates {
  CategoryModel categoryModel;
  CategoriesLoaded(this.categoryModel);
}

class CategoriesFailure extends CategoriesStates {
  String error;
  CategoriesFailure(this.error);
}
