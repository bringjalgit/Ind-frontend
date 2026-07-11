import 'package:flutter_bloc/flutter_bloc.dart';
import 'property_ad_repo.dart';
import 'property_ad_states.dart';

class PropertyAdCubit extends Cubit<PropertyAdStates> {
  PropertyAdRepository propertyAdRepository;
  PropertyAdCubit(this.propertyAdRepository) : super(PropertyAdInitially());

  Future<void> postPropertyAd(Map<String, dynamic> data) async {
    emit(PropertyAdLoading());
    try {
      final response = await propertyAdRepository.postPropertyAd(data);
      if (response != null && response.success == true) {
        emit(PropertyAdSuccess(response));
      } else {
        emit(
          PropertyAdFailure(
            "${response?.message ?? ""}.${response?.error ?? ""}",
          ),
        );
      }
    } catch (e) {
      emit(PropertyAdFailure(e.toString()));
    }
  }
}
