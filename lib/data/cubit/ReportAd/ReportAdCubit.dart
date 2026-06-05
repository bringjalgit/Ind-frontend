import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../model/AdSuccessModel.dart';
import 'ReportAdRepo.dart';
import 'ReportAdStates.dart';

class ReportAdCubit extends Cubit<ReportAdStates> {
  final ReportAdRepo reportAdRepo;

  ReportAdCubit(this.reportAdRepo) : super(ReportAdInitial());

  Future<void> reportAd(Map<String, dynamic> data) async {
    emit(ReportAdLoading());
    try {
      final AdSuccessModel? response = await reportAdRepo.reportAd(data);
      if (response != null && (response.success == true)) {
        emit(ReportAdSuccess(response));
      } else {
        emit(ReportAdFailure(response?.message ?? "Something went wrong"));
      }
    } catch (e) {
      emit(
        ReportAdFailure("Error occurred while reporting ad: ${e.toString()}"),
      );
    }
  }
}
