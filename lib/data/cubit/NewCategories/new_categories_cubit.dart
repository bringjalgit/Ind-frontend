
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/NewCategories/new_categories_states.dart';

import '../Categories/categories_repository.dart';

class NewCategoriesCubit extends Cubit<NewCategoryStates> {
  CategoriesRepo categoriesRepo;
  NewCategoriesCubit(this.categoriesRepo) : super(NewCategoryInitially());

  Future<void> getNewCategories() async {
    emit(NewCategoryLoading());
    try {
      final response = await categoriesRepo.getNewCategories();
      if (response != null && response.success == true) {
        emit(NewCategoryLoaded(response));
      } else {
        emit(NewCategoryFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(NewCategoryFailure(e.toString()));
    }
  }
}