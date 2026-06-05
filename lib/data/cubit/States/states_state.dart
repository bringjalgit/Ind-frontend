
import '../../../model/SelectStatesModel.dart';


abstract class SelectStates {}

class SelectStatesInitially extends SelectStates {}

class SelectStatesLoading extends SelectStates {}

class SelectStatesLoaded extends SelectStates {
  SelectStatesModel selectStatesModel;
  SelectStatesLoaded(this.selectStatesModel);
}

class SelectStatesFailure extends SelectStates {
  String error;
  SelectStatesFailure(this.error);
}
