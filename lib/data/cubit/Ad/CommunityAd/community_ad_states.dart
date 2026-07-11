import '../../../../model/AdSuccessModel.dart';


abstract class CommunityAdStates {}

class CommunityAdInitially extends CommunityAdStates {}

class CommunityAdLoading extends CommunityAdStates {}

class CommunityAdSuccess extends CommunityAdStates {
  AdSuccessModel adSuccessModel;
  CommunityAdSuccess(this.adSuccessModel);
}

class CommunityAdFailure extends CommunityAdStates {
  String error;
  CommunityAdFailure(this.error);
}
