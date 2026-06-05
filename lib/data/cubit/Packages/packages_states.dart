import 'package:classifieds/model/PackagesModel.dart';

abstract class PackagesStates {}

class PackagesInitially extends PackagesStates {}

class PackagesLoading extends PackagesStates {}

class PackagesLoaded extends PackagesStates {
  PackagesModel packagesModel;
  PackagesLoaded(this.packagesModel);
}

class PackagesFailure extends PackagesStates {
  String error;
  PackagesFailure(this.error);
}
