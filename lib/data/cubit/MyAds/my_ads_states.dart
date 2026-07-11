import 'package:classifieds/model/MyAdsModel.dart';

abstract class MyAdsStates {}

class MyAdsInitially extends MyAdsStates {}

class MyAdsLoading extends MyAdsStates {}

class MyAdsLoadingMore extends MyAdsStates {
  final MyAdsModel myAdsModel;
  final bool hasNextPage;

  MyAdsLoadingMore(this.myAdsModel, this.hasNextPage);
}

class MyAdsLoaded extends MyAdsStates {
  final MyAdsModel myAdsModel;
  final bool hasNextPage;

  MyAdsLoaded(this.myAdsModel, this.hasNextPage);
}

class MyAdsFailure extends MyAdsStates {
  final String error;
  MyAdsFailure(this.error);
}
