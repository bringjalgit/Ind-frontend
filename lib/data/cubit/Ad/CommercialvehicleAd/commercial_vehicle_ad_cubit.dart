import 'package:flutter_bloc/flutter_bloc.dart';
import 'commercial_vehicle_ad_repo.dart';
import 'commercial_vehicle_ad_states.dart';

class CommercialVehileAdCubit extends Cubit<CommercialVehileAdStates> {
  CommercialVehileAdRepository propertyAdRepository;
  CommercialVehileAdCubit(this.propertyAdRepository) : super(CommercialVehileAdInitially());

  Future<void> postCommercialVehicleAd(Map<String, dynamic> data) async {
    emit(CommercialVehileAdLoading());
    try {
      final response = await propertyAdRepository.postCommercialVehileAd(data);
      if (response != null && response.success == true) {
        emit(CommercialVehileAdSuccess(response));
      } else {
        emit(CommercialVehileAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(CommercialVehileAdFailure(e.toString()));
    }
  }
}
