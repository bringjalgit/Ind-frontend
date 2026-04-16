import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Products/products_repository.dart';
import 'package:classifieds/data/cubit/Products/products_state1.dart';

import '../../../model/SubcategoryProductsModel.dart';

class ProductsCubit1 extends Cubit<ProductsStates1> {
  final ProductsRepo productsRepo;
  ProductsCubit1(this.productsRepo) : super(Products1Initially());

  SubcategoryProductsModel productsModel = SubcategoryProductsModel();

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  Future<void> getProducts({
    String? categoryId,
    String? subCategoryId,
    String? search,
    String? state_id,
    String? city_id,
    String? sort_by,
    String? minPrice,
    String? maxPrice,

  }) async {
    emit(Products1Loading());
    _currentPage = 1;
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
      );

      if (response != null && response.success == true) {
        productsModel = response;
        _hasNextPage = response.settings?.nextPage ?? false;

        emit(Products1Loaded(productsModel, _hasNextPage));
      } else {
        emit(Products1Failure(response?.message ?? "Failed to load products"));
      }
    } catch (e) {
      emit(Products1Failure(e.toString()));
    }
  }


  Future<void> getMoreProducts(String subCategoryId) async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    _currentPage++;

    emit(Products1LoadingMore(productsModel, _hasNextPage));

    try {
      final newData = await productsRepo.getProducts(
        subCategoryId: subCategoryId,
        page: _currentPage, // 👈 pass next page
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

        emit(Products1Loaded(productsModel, _hasNextPage));
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
    emit(Products1Loaded(productsModel, _hasNextPage));
  }
}

