import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Profile/profile_repo.dart';
import 'package:classifieds/data/cubit/Profile/profile_states.dart';

import '../../../model/ProfileModel.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  ProfileRepo profileRepo;
  ProfileCubit(this.profileRepo) : super(ProfileInitially());

  Future<ProfileModel?> getProfileDetails() async {
    emit(ProfileLoading());
    try {
      final response = await profileRepo.getProfileDetails();
      if (response != null && response.success == true) {
        emit(ProfileLoaded(response));
        return response;
      } else {
        emit(ProfileFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }
}
