import 'package:classifieds/model/BannersModel.dart';
import 'package:classifieds/model/SubcategoryProductsModel.dart';

import '../../../model/CategoryModel.dart';

abstract class DashBoardState {}

class DashBoardInitially extends DashBoardState {}

class DashBoardLoading extends DashBoardState {}

class DashBoardLoaded extends DashBoardState {
  final BannersModel? bannersModel;
  final CategoryModel? categoryModel;
  final CategoryModel? NewcategoryModel;
  final SubcategoryProductsModel? subcategoryProductsModel;

  DashBoardLoaded({
    this.bannersModel,
    this.categoryModel,
    this.NewcategoryModel,
    this.subcategoryProductsModel,
  });
}

class DashBoardFailure extends DashBoardState {
  final String error;
  DashBoardFailure(this.error);
}
