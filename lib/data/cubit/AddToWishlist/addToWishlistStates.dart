import 'package:classifieds/model/AddToWishlistModel.dart';

abstract class AddToWishlistStates {}

class AddToWishlistInitially extends AddToWishlistStates {}

class AddToWishlistLoading extends AddToWishlistStates {}

class AddToWishlistLoaded extends AddToWishlistStates {
  String product_id;
  AddToWishlistModel addToWishlistModel;
  AddToWishlistLoaded(this.addToWishlistModel,this.product_id);
}

class AddToWishlistFailure extends AddToWishlistStates {
  String error;
  AddToWishlistFailure(this.error);
}
