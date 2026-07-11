import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Profile/profile_repo.dart';
import 'package:classifieds/data/cubit/UpdateProfile/update_profile_states.dart';

class UpdateProfileCubit extends Cubit<UpdateProfileStates> {
  ProfileRepo profileRepo;
  UpdateProfileCubit(this.profileRepo) : super(UpdateProfileInitially());

  Future<void> updateProfileDetails(Map<String, dynamic> data) async {
    emit(UpdateProfileLoading());
    try {
      final response = await profileRepo.updateProfileDetails(data);
      if (response != null && response.success == true) {
        emit(UpdateProfileSuccess(response));
      } else {
        emit(UpdateProfileFailure(response?.message ?? response?.error ?? "Update failed"));
      }
    } catch (e) {
      emit(UpdateProfileFailure(e.toString()));
    }
  }
}
