import 'package:flutter_bloc/flutter_bloc.dart';
import 'education_ad_repo.dart';
import 'education_ad_states.dart';

class EducationAdCubit extends Cubit<EducationAdStates> {
  EducationAdRepository educationAdRepository;
  EducationAdCubit(this.educationAdRepository) : super(EducationAdInitially());

  Future<void> postEducationAd(Map<String, dynamic> data) async {
    emit(EducationAdLoading());
    try {
      final response = await educationAdRepository.postEducationAd(data);
      if (response != null && response.success == true) {
        emit(EducationAdSuccess(response));
      } else {
        emit(EducationAdFailure("${response?.message ?? ""}.${response?.error ?? ""}"));
      }
    } catch (e) {
      emit(EducationAdFailure(e.toString()));
    }
  }
}
