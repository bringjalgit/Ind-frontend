import 'package:classifieds/model/AdvertisementModel.dart';

abstract class AdvertisementStates {}

class AdvertisementInitially extends AdvertisementStates {}

class AdvertisementLoading extends AdvertisementStates {}

class AdvertisementLoadingMore extends AdvertisementStates {
  final AdvertisementModel advertisementModel;
  final bool hasNextPage;

  AdvertisementLoadingMore(this.advertisementModel, this.hasNextPage);
}

class AdvertisementLoaded extends AdvertisementStates {
  final AdvertisementModel advertisementModel;
  final bool hasNextPage;

  AdvertisementLoaded(this.advertisementModel, this.hasNextPage);
}

class AdvertisementFailure extends AdvertisementStates {
  final String error;

  AdvertisementFailure(this.error);
}
