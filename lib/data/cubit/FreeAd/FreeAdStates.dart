import '../../../model/FreeAdModel.dart';

abstract class FreeAdStates {}

class FreeAdInitially extends FreeAdStates {}

class FreeAdLoading extends FreeAdStates {}

class FreeAdLoaded extends FreeAdStates {
  FreeAdModel freeAdModel;
  FreeAdLoaded(this.freeAdModel);
}

class FreeAdFailure extends FreeAdStates {
  String error;
  FreeAdFailure(this.error);
}