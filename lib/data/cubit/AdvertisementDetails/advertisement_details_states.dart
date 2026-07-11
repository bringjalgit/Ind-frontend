import '../../../model/AdvertisementDetailsModel.dart';

abstract class AdvertisementDetailsStates {}

class AdvertisementDetailsInitially extends AdvertisementDetailsStates {}

class AdvertisementDetailsLoading extends AdvertisementDetailsStates {}

class AdvertisementDetailsLoaded extends AdvertisementDetailsStates {
  AdvertisementDetailsModel advertisementDetailsModel;
  AdvertisementDetailsLoaded(this.advertisementDetailsModel);
}

class AdvertisementDetailsFailure extends AdvertisementDetailsStates {
  String error;
  AdvertisementDetailsFailure(this.error);
}
