import 'package:classifieds/model/AdSuccessModel.dart';
import '../../../../model/MarkAsListingModel.dart';

abstract class MarkAsListingState {}

class MarkAsListingInitially extends MarkAsListingState {}

class MarkAsListingLoading extends MarkAsListingState {}
class MarkAsListingUpdateLoading extends MarkAsListingState {}

class MarkAsListingSuccess extends MarkAsListingState {
  MarkAsListingModel markAsListingModel;
  MarkAsListingSuccess(this.markAsListingModel);
}
class MarkAsListingDeleted extends MarkAsListingState {
  MarkAsListingModel markAsListingModel;
  MarkAsListingDeleted(this.markAsListingModel);
}
class MarkAsListingUpdateSuccess extends MarkAsListingState {
  AdSuccessModel adSuccessModel;
  MarkAsListingUpdateSuccess(this.adSuccessModel);
}
class MarkAsListingImageDelete extends MarkAsListingState {
  AdSuccessModel adSuccessModel;
  MarkAsListingImageDelete(this.adSuccessModel);
}

class MarkAsListingFailure extends MarkAsListingState {
  String error;
  MarkAsListingFailure(this.error);
}
