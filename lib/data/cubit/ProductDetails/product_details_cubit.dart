import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/ProductDetails/product_details_repo.dart';
import 'package:classifieds/data/cubit/ProductDetails/product_details_states.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsStates> {
  ProductDetailsRepo productDetailsRepo;
  ProductDetailsCubit(this.productDetailsRepo)
    : super(ProductDetailsInitially());

  Future<void> getProductDetails(String id) async {
    emit(ProductDetailsLoading());
    try {
      final response = await productDetailsRepo.getProductDetails(id);
      if (response != null && response.success == true) {
        emit(ProductDetailsLoaded(response));
      } else {
        emit(ProductDetailsFailure("Product Details failed loading!"));
      }
    } catch (e) {
      emit(ProductDetailsFailure(e.toString()));
    }
  }
}
