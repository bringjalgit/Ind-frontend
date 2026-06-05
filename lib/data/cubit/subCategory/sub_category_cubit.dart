import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/subCategory/sub_category_repository.dart';

import 'sub_category_state.dart';

class SubCategoryCubit extends Cubit<SubCategoryStates> {
  SubCategoryRepository subCategoryRepository;
  SubCategoryCubit(this.subCategoryRepository) : super(SubCategoryInitially());

  Future<void> getSubCategory(String categoryId) async {
    emit(SubCategoryLoading());
    try {
      final response = await subCategoryRepository.getSubCategory(categoryId);
      if (response != null && response.success == true) {
        emit(SubCategoryLoaded(response));
      } else {
        emit(SubCategoryFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(SubCategoryFailure(e.toString()));
    }
  }
}
