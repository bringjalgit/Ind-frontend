import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Wishlist/wishlist_repository.dart';
import 'package:classifieds/data/cubit/Wishlist/wishlist_states.dart';

import '../../../model/SubcategoryProductsModel.dart';
import '../../../model/WishlistModel.dart';

class WishlistCubit extends Cubit<WishlistStates> {
  final WishlistRepository wishlistRepository;
  WishlistCubit(this.wishlistRepository) : super(WishlistInitially());

  WishlistModel wishlistModel = WishlistModel();

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  /// Initial fetch (reset to page 1)
  Future<void> getWishlist() async {
    emit(WishlistLoading());
    _currentPage = 1;

    try {
      final response = await wishlistRepository.getWishlist(
        _currentPage, // 👈 pass page number
      );

      if (response != null && response.success == true) {
        wishlistModel = response;
        _hasNextPage = response.settings?.nextPage ?? false;

        emit(WishlistLoaded(wishlistModel, _hasNextPage));
      } else {
        emit(WishlistFailure(response?.message ?? "Failed to load wishlist"));
      }
    } catch (e) {
      emit(WishlistFailure(e.toString()));
    }
  }

  /// Load more wishlist items (pagination)
  Future<void> getMoreWishlist() async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    _currentPage++;

    emit(WishlistLoadingMore(wishlistModel, _hasNextPage));

    try {
      final newData = await wishlistRepository.getWishlist(
        _currentPage, // 👈 pass next page
      );

      if (newData != null && newData.productslist?.isNotEmpty == true) {
        final combinedData = List<Products>.from(
          wishlistModel.productslist ?? [],
        )..addAll(newData.productslist!);

        wishlistModel = WishlistModel(
          success: newData.success,
          message: newData.message,
          productslist: combinedData,
          settings: newData.settings,
        );

        _hasNextPage = newData.settings?.nextPage ?? false;

        emit(WishlistLoaded(wishlistModel, _hasNextPage));
      }
    } catch (e) {
      print("Wishlist pagination error: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  void updateWishlistStatus(String productId, bool isLiked) {
    // 👉 unfavorited → remove it from the list
    final updatedProducts = wishlistModel.productslist
        ?.where((p) => p.id != productId)
        .toList();

    wishlistModel = wishlistModel.copyWith(productslist: updatedProducts);

    emit(WishlistLoaded(wishlistModel, _hasNextPage));
  }
}
