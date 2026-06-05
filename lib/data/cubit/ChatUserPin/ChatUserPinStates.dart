import 'package:classifieds/model/AdSuccessModel.dart';

abstract class ChatUserPinStates {}

class ChatUserPinInitially extends ChatUserPinStates {}

class ChatUserPinLoading extends ChatUserPinStates {}

class ChatUserPinLoaded extends ChatUserPinStates {
  AdSuccessModel adSuccessModel;
  ChatUserPinLoaded(this.adSuccessModel);
}

class ChatUserPinFailure extends ChatUserPinStates {
  String error;
  ChatUserPinFailure(this.error);
}
