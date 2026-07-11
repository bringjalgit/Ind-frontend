import '../../../model/PlansModel.dart';

abstract class PlansStates {}

class PlansInitially extends PlansStates {}

class PlansLoading extends PlansStates {}

class PlansLoaded extends PlansStates {
  PlansModel plansModel;
  PlansLoaded(this.plansModel);
}

class PlansFailure extends PlansStates {
  String error;
  PlansFailure(this.error);
}
