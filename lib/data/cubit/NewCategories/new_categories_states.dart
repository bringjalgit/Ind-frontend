import 'package:classifieds/model/CategoryModel.dart';

abstract class NewCategoryStates {}

class NewCategoryInitially extends NewCategoryStates {}

class NewCategoryLoading extends NewCategoryStates {}

class NewCategoryLoaded extends NewCategoryStates {
  CategoryModel NewcategoryModel;
  NewCategoryLoaded(this.NewcategoryModel);
}

class NewCategoryFailure extends NewCategoryStates {
  String error;
  NewCategoryFailure(this.error);
}
