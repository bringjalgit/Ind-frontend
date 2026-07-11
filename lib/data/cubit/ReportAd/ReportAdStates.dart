

// STATES
import '../../../model/AdSuccessModel.dart';

abstract class ReportAdStates {}

class ReportAdInitial extends ReportAdStates {}

class ReportAdLoading extends ReportAdStates {}

class ReportAdSuccess extends ReportAdStates {
  final AdSuccessModel result;

  ReportAdSuccess(this.result);
}

class ReportAdFailure extends ReportAdStates {
  final String error;

  ReportAdFailure(this.error);
}