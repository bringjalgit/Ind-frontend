// states
import '../../../model/ContactInfoModel.dart';

abstract class ContactInfoStates {}

class ContactInfoInitially extends ContactInfoStates {}

class ContactInfoLoading extends ContactInfoStates {}

class ContactInfoLoaded extends ContactInfoStates {
  ContactInfoModel contactInfoModel;
  ContactInfoLoaded(this.contactInfoModel);
}

class ContactInfoFailure extends ContactInfoStates {
  String error;
  ContactInfoFailure(this.error);
}