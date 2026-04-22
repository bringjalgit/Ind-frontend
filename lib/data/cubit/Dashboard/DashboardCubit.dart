import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Banners/banner_states.dart';
import 'package:classifieds/data/cubit/Categories/categories_cubit.dart';
import 'package:classifieds/data/cubit/NewCategories/new_categories_cubit.dart';
import 'package:classifieds/data/cubit/NewCategories/new_categories_states.dart';
import 'package:classifieds/data/cubit/Products/products_cubit.dart';
import 'package:classifieds/data/cubit/Products/products_states.dart';
import 'package:classifieds/model/BannersModel.dart';
import 'package:classifieds/model/SubcategoryProductsModel.dart';
import 'package:classifieds/services/SecureStorageService.dart';
import '../../../model/CategoryModel.dart';
import '../Banners/banner_cubit.dart';
import '../Categories/categories_states.dart';
import 'DashboardState.dart';

// LocationCubit persists the user's latlng at this key. We read directly
// from storage here (instead of subscribing to LocationCubit) because
// fetchDashboard() runs in initState.postFrameCallback, when LocationCubit
// may still be in Loading/Initial and GPS hasn't returned yet. Persisted
// value is stable and written by both the GPS success path and the manual
// location picker sheet.
const String _kDashboardLatLngKey = 'latlngs';

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
    emit(DashBoardLoading());

    // Read the current location (if any) before firing listing API so the
    // home shows listings near the user. Empty/missing → nationwide results
    // (fallback for fresh installs or permission-denied sessions).
    final savedLatLng = await SecureStorageService.instance
        .getString(_kDashboardLatLngKey);
    final locationKey = (savedLatLng != null && savedLatLng.isNotEmpty)
        ? savedLatLng
        : null;

    BannersModel? bannerModel;
    CategoryModel? categoryModel;
    CategoryModel? newcategoryModel;
    SubcategoryProductsModel? subcategoryProductsModel;

    try {
      try {
        await bannersCubit.getBanners();
        final s = bannersCubit.state;
        if (s is BannerLoaded) bannerModel = s.bannersModel;
      } catch (_) {}

      try {
        await categoryCubit.getCategories();
        final s = categoryCubit.state;
        if (s is CategoriesLoaded) categoryModel = s.categoryModel;
      } catch (_) {}

      try {
        await newCategoriesCubit.getNewCategories();
        final s = newCategoriesCubit.state;
        if (s is NewCategoryLoaded) newcategoryModel = s.NewcategoryModel;
      } catch (_) {}

      try {
        await productsCubit.getProducts(locationKey: locationKey);
        final s = productsCubit.state;
        if (s is ProductsLoaded) subcategoryProductsModel = s.productsModel;
      } catch (_) {}

      if (bannerModel != null || categoryModel != null) {
        emit(DashBoardLoaded(
          bannersModel: bannerModel,
          NewcategoryModel: newcategoryModel,
          categoryModel: categoryModel,
          subcategoryProductsModel: subcategoryProductsModel,
        ));
      } else {
        emit(DashBoardFailure('All API calls failed.'));
      }
    } catch (e) {
      emit(DashBoardFailure('Dashboard error: ${e.toString()}'));
    }
  }
}
