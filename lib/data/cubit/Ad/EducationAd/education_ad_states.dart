import '../../../../model/AdSuccessModel.dart';


abstract class EducationAdStates {}

class EducationAdInitially extends EducationAdStates {}

class EducationAdLoading extends EducationAdStates {}

class EducationAdSuccess extends EducationAdStates {
  AdSuccessModel adSuccessModel;
  EducationAdSuccess(this.adSuccessModel);
}

class EducationAdFailure extends EducationAdStates {
  String error;
  EducationAdFailure(this.error);
}
