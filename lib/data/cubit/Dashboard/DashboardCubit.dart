import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Banners/banner_states.dart';
import 'package:classifieds/data/cubit/Categories/categories_cubit.dart';
import 'package:classifieds/data/cubit/NewCategories/new_categories_cubit.dart';
import 'package:classifieds/data/cubit/NewCategories/new_categories_states.dart';
import 'package:classifieds/data/cubit/Products/products_cubit.dart';
import 'package:classifieds/data/cubit/Products/products_states.dart';
import 'package:classifieds/model/BannersModel.dart';
import 'package:classifieds/model/SubcategoryProductsModel.dart';
import 'package:classifieds/services/DashboardCacheService.dart';
import '../../../model/CategoryModel.dart';
import '../Banners/banner_cubit.dart';
import '../Categories/categories_states.dart';
import 'DashboardState.dart';

class DashboardCubit extends Cubit<DashBoardState> {
  final BannerCubit bannersCubit;
  final CategoriesCubit categoryCubit;
  final NewCategoriesCubit newCategoriesCubit;
  final ProductsCubit productsCubit;

  DashboardCubit({
    required this.bannersCubit,
    required this.categoryCubit,
    required this.productsCubit,
    required this.newCategoriesCubit,
  }) : super(DashBoardInitially());

  Future<void> fetchDashboard() async {
    // ── Step 1: Show cached data instantly (if available) ──────────────
    final hasCache = await DashboardCacheService.hasCache();
    if (hasCache) {
      try {
        final cachedBanners = await DashboardCacheService.getBanners();
        final cachedCategories = await DashboardCacheService.getCategories();
        final cachedNewCategories = await DashboardCacheService.getNewCategories();
        final cachedProducts = await DashboardCacheService.getProducts();

        emit(DashBoardLoaded(
          bannersModel: cachedBanners != null ? BannersModel.fromJson(cachedBanners) : null,
          categoryModel: cachedCategories != null ? CategoryModel.fromJson(cachedCategories) : null,
          NewcategoryModel: cachedNewCategories != null ? CategoryModel.fromJson(cachedNewCategories) : null,
          subcategoryProductsModel: cachedProducts != null ? SubcategoryProductsModel.fromJson(cachedProducts) : null,
        ));
      } catch (_) {
        // Cache corrupted — show loading and fetch fresh
        emit(DashBoardLoading());
      }
    } else {
      emit(DashBoardLoading());
    }

    // ── Step 2: Fetch fresh data from API (background refresh) ────────
    await _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    BannersModel? bannerModel;
    CategoryModel? categoryModel;
    CategoryModel? newcategoryModel;
    SubcategoryProductsModel? subcategoryProductsModel;

    try {
      try {
        await bannersCubit.getBanners();
        final state = bannersCubit.state;
        if (state is BannerLoaded) {
          bannerModel = state.bannersModel;
        }
      } catch (e) {}

      try {
        await categoryCubit.getCategories();
        final state = categoryCubit.state;
        if (state is CategoriesLoaded) {
          categoryModel = state.categoryModel;
        }
      } catch (e) {}

      try {
        await newCategoriesCubit.getNewCategories();
        final state = newCategoriesCubit.state;
        if (state is NewCategoryLoaded) {
          newcategoryModel = state.NewcategoryModel;
        }
      } catch (e) {}

      try {
        await productsCubit.getProducts();
        final state = productsCubit.state;
        if (state is ProductsLoaded) {
          subcategoryProductsModel = state.productsModel;
        }
      } catch (e) {}

      if (bannerModel != null || categoryModel != null) {
        // ── Step 3: Update UI with fresh data ───────────────────────────
        emit(DashBoardLoaded(
          bannersModel: bannerModel,
          NewcategoryModel: newcategoryModel,
          categoryModel: categoryModel,
          subcategoryProductsModel: subcategoryProductsModel,
        ));

        // ── Step 4: Save fresh data to cache ────────────────────────────
        await DashboardCacheService.saveAll(
          banners: bannerModel?.toJson(),
          categories: categoryModel?.toJson(),
          newCategories: newcategoryModel?.toJson(),
          products: subcategoryProductsModel?.toJson(),
        );
      } else if (!(state is DashBoardLoaded)) {
        // Only emit failure if we don't already have cached data showing
        emit(DashBoardFailure('All API calls failed.'));
      }
    } catch (e) {
      if (!(state is DashBoardLoaded)) {
        emit(DashBoardFailure('Dashboard error: ${e.toString()}'));
      }
    }
  }
}
