import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Categories/categories_repository.dart';
import 'package:classifieds/data/cubit/Categories/categories_states.dart';

class CategoriesCubit extends Cubit<CategoriesStates> {
  CategoriesRepo categoriesRepo;
  CategoriesCubit(this.categoriesRepo) : super(CategoriesInitially());

  Future<void> getCategories() async {
    emit(CategoriesLoading());
    try {
      final response = await categoriesRepo.getCategories();
      if (response != null && response.success == true) {
        emit(CategoriesLoaded(response));
      } else {
        emit(CategoriesFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(CategoriesFailure(e.toString()));
    }
  }
}
