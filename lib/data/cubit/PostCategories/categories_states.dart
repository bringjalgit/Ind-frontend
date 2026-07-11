import 'package:classifieds/model/CategoryModel.dart';

abstract class PostCategoriesStates {}

class PostCategoriesInitially extends PostCategoriesStates {}

class PostCategoriesLoading extends PostCategoriesStates {}

class PostCategoriesLoaded extends PostCategoriesStates {
  CategoryModel categoryModel;
  PostCategoriesLoaded(this.categoryModel);
}

class PostCategoriesFailure extends PostCategoriesStates {
  String error;
  PostCategoriesFailure(this.error);
}
