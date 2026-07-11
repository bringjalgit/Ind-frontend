import '../../../../model/getListingAdModel.dart';

abstract class GetListingAdState {}

class GetListingAdInitially extends GetListingAdState {}

class GetListingAdLoading extends GetListingAdState {}

class GetListingAdLoaded extends GetListingAdState {
  getListingAdModel getListingModel;
  GetListingAdLoaded(this.getListingModel);
}

class GetListingAdFailure extends GetListingAdState {
  String error;
  GetListingAdFailure(this.error);
}
