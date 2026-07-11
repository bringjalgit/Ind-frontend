
import '../../../model/SubCategoryModel.dart';

abstract class SubCategoryStates {}

class SubCategoryInitially extends SubCategoryStates {}

class SubCategoryLoading extends SubCategoryStates {}

class SubCategoryLoaded extends SubCategoryStates {
  SubCategoryModel subCategoryModel;
  SubCategoryLoaded(this.subCategoryModel);
}

class SubCategoryFailure extends SubCategoryStates {
  String error;
  SubCategoryFailure(this.error);
}
