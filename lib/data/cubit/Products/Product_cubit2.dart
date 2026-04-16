import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Products/products_repository.dart';
import 'package:classifieds/data/cubit/Products/products_state2.dart';
import '../../../model/SubcategoryProductsModel.dart';

class ProductsCubit2 extends Cubit<ProductsStates2> {
  final ProductsRepo productsRepo;
  ProductsCubit2(this.productsRepo) : super(Products2Initially());

  SubcategoryProductsModel productsModel = SubcategoryProductsModel();

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  // store last applied filters
  String? _categoryId;
  String? _subCategoryId;
  String? _search;
  String? _stateId;
  String? _cityId;
  String? _sortBy;
  String? _minPrice;
  String? _maxPrice;
  String? _locationKey;

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
    emit(Products2Loading());
    _currentPage = 1;

    // 👇 Save filters for pagination
    _categoryId = categoryId;
    _subCategoryId = subCategoryId;
    _search = search;
    _stateId = state_id;
    _cityId = city_id;
    _sortBy = sort_by;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _locationKey = locationKey;

    try {
      final response = await productsRepo.getProducts(
        categoryId: _categoryId,
        subCategoryId: _subCategoryId,
        search: _search,
        state_id: _stateId,
        city_id: _cityId,
        sort_by: _sortBy,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        locationKey: _locationKey,
        page: _currentPage,
      );

      if (response != null && response.success == true) {
        productsModel = response;
        _hasNextPage = response.settings?.nextPage ?? false;
        emit(Products2Loaded(productsModel, _hasNextPage));
      } else {
        emit(Products2Failure(response?.message ?? "Failed to load products"));
      }
    } catch (e) {
      emit(Products2Failure(e.toString()));
    }
  }

  Future<void> getMoreProducts() async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    _currentPage++;

    emit(Products2LoadingMore(productsModel, _hasNextPage));

    try {
      final newData = await productsRepo.getProducts(
        categoryId: _categoryId,
        subCategoryId: _subCategoryId,
        search: _search,
        state_id: _stateId,
        city_id: _cityId,
        sort_by: _sortBy,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        locationKey: _locationKey,
        page: _currentPage,
      );

      if (newData != null && newData.products?.isNotEmpty == true) {
        final combinedData = List<Products>.from(productsModel.products ?? [])
          ..addAll(newData.products!);

        productsModel = productsModel.copyWith(
          products: combinedData,
          settings: newData.settings,
        );

        _hasNextPage = newData.settings?.nextPage ?? false;

        emit(Products2Loaded(productsModel, _hasNextPage));
      }
    } catch (e) {
      print("Products pagination error: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  void updateWishlistStatus(String productId, bool isLiked) {
    final updatedProducts = productsModel.products?.map((p) {
      if (p.id == productId) {
        return p.copyWith(isFavorited: isLiked);
      }
      return p;
    }).toList();
    productsModel = productsModel.copyWith(products: updatedProducts);
    emit(Products2Loaded(productsModel, _hasNextPage));
  }
}
