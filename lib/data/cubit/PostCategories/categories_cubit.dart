import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Categories/categories_repository.dart';
import 'package:classifieds/data/cubit/Categories/categories_states.dart';

import 'categories_states.dart';

class PostCategoriesCubit extends Cubit<PostCategoriesStates> {
  CategoriesRepo categoriesRepo;
  PostCategoriesCubit(this.categoriesRepo) : super(PostCategoriesInitially());

  Future<void> getPostCategories() async {
    emit(PostCategoriesLoading());
    try {
      final response = await categoriesRepo.getPostCategories();
      if (response != null && response.success == true) {
        emit(PostCategoriesLoaded(response));
      } else {
        emit(PostCategoriesFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(PostCategoriesFailure(e.toString()));
    }
  }
}
