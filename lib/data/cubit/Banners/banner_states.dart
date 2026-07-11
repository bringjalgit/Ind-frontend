import 'package:classifieds/model/BannersModel.dart';

abstract class BannerStates {}

class BannerInitially extends BannerStates {}

class BannerLoading extends BannerStates {}

class BannerLoaded extends BannerStates {
  BannersModel bannersModel;
  BannerLoaded(this.bannersModel);
}

class BannerFailure extends BannerStates {
  String error;
  BannerFailure(this.error);
}
