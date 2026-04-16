import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Products/products_repository.dart';
import 'package:classifieds/data/cubit/Products/products_states.dart';

import '../../../model/SubcategoryProductsModel.dart';

class ProductsCubit extends Cubit<ProductsStates> {
  final ProductsRepo productsRepo;

  ProductsCubit(this.productsRepo) : super(ProductsInitially());

  SubcategoryProductsModel productsModel = SubcategoryProductsModel();

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  // ✅ Store last used filters for pagination reuse
  String? _lastCategoryId;
  String? _lastSubCategoryId;
  String? _lastSearch;
  String? _lastStateId;
  String? _lastCityId;
  String? _lastSortBy;
  String? _lastMinPrice;
  String? _lastMaxPrice;
  String? _lastLocationKey;

  // ==========================================================
  // 🔹 INITIAL LOAD / REFRESH
  // ==========================================================
  Future<void> getProducts({
    String? categoryId,
    String? subCategoryId,
    String? search,
    String? state_id,
    String? city_id,
    String? sort_by,
    String? minPrice,
    String? maxPrice,
    String? locationKey,
  }) async {
    // ✅ Save filters for later pagination reuse
    _lastCategoryId = categoryId;
    _lastSubCategoryId = subCategoryId;
    _lastSearch = search;
    _lastStateId = state_id;
    _lastCityId = city_id;
    _lastSortBy = sort_by;
    _lastMinPrice = minPrice;
    _lastMaxPrice = maxPrice;
    _lastLocationKey = locationKey;

    emit(ProductsLoading());

    _currentPage = 1;
    _hasNextPage = true;
    _isLoadingMore = false;
    productsModel = SubcategoryProductsModel();

    try {
      final response = await productsRepo.getProducts(
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        search: search,
        state_id: state_id,
        city_id: city_id,
        sort_by: sort_by,
        minPrice: minPrice,
        maxPrice: maxPrice,
        page: _currentPage,
        locationKey: locationKey,
      );

      if (response != null && response.success == true) {
        productsModel = response;
        _hasNextPage = response.settings?.nextPage ?? false;

        emit(ProductsLoaded(productsModel, _hasNextPage));
      } else {
        emit(ProductsFailure(response?.message ?? "Failed to load products"));
      }
    } catch (e) {
      emit(ProductsFailure(e.toString()));
    }
  }

  // ==========================================================
  // 🔹 PAGINATION
  // ==========================================================
  Future<void> getMoreProducts() async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    _currentPage++;

    emit(ProductsLoadingMore(productsModel, _hasNextPage));

    try {
      final newData = await productsRepo.getProducts(
        categoryId: _lastCategoryId,
        subCategoryId: _lastSubCategoryId,
        search: _lastSearch,
        state_id: _lastStateId,
        city_id: _lastCityId,
        sort_by: _lastSortBy,
        minPrice: _lastMinPrice,
        maxPrice: _lastMaxPrice,
        page: _currentPage,
        locationKey: _lastLocationKey,
      );

      if (newData != null && newData.products?.isNotEmpty == true) {
        final combinedData = List<Products>.from(productsModel.products ?? [])
          ..addAll(newData.products!);

        productsModel = SubcategoryProductsModel(
          success: newData.success,
          message: newData.message,
          products: combinedData,
          settings: newData.settings,
        );

        _hasNextPage = newData.settings?.nextPage ?? false;

        emit(ProductsLoaded(productsModel, _hasNextPage));
      }
    } catch (e) {
      emit(ProductsFailure(e.toString()));
    } finally {
      _isLoadingMore = false;
    }
  }

  // ==========================================================
  // 🔹 LOCATION UPDATE (Optional Cleaner Method)
  // ==========================================================
  Future<void> updateLocation(String locationKey) async {
    await getProducts(
      categoryId: _lastCategoryId,
      subCategoryId: _lastSubCategoryId,
      search: _lastSearch,
      state_id: _lastStateId,
      city_id: _lastCityId,
      sort_by: _lastSortBy,
      minPrice: _lastMinPrice,
      maxPrice: _lastMaxPrice,
      locationKey: locationKey,
    );
  }

  // ==========================================================
  // 🔹 WISHLIST UPDATE
  // ==========================================================
  void updateWishlistStatus(String productId, bool isLiked) {
    final updatedProducts = productsModel.products?.map((p) {
      if (p.id == productId) {
        return p.copyWith(isFavorited: isLiked);
      }
      return p;
    }).toList();

    productsModel = productsModel.copyWith(products: updatedProducts);

    emit(ProductsLoaded(productsModel, _hasNextPage));
  }
}
