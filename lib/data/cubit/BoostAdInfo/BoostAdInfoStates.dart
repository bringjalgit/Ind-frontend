import 'package:classifieds/model/BoostAdModel.dart';

abstract class BoostAdInfoStates {}

class BoostAdInfoInitially extends BoostAdInfoStates {}

class BoostAdInfoLoading extends BoostAdInfoStates {}

class BoostAdInfoLoaded extends BoostAdInfoStates {
  final BoostAdModel boostAdModel;
  BoostAdInfoLoaded(this.boostAdModel);
}

class BoostAdInfoFailure extends BoostAdInfoStates {
  final String error;
  BoostAdInfoFailure(this.error);
}
