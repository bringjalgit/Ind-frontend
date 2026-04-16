import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/GoogleAuth/google_auth_repo.dart';
import 'package:classifieds/data/cubit/GoogleAuth/google_auth_states.dart';

class GoogleAuthCubit extends Cubit<GoogleAuthStates> {
  final GoogleAuthRepo googleAuthRepo;
  GoogleAuthCubit(this.googleAuthRepo) : super(GoogleAuthInitial());

  Future<void> googleAuth(Map<String, dynamic> data) async {
    emit(GoogleAuthLoading());
    try {
      final response = await googleAuthRepo.googleAuth(data);
      if (response != null && response.success == true) {
        emit(GoogleAuthSuccess(response));
      } else {
        // Preserve the backend error code and user id so the UI can route
        // ACCOUNT_DELETED to /recover_account and ACCOUNT_BLOCKED to /blocked_account.
        emit(GoogleAuthFailure(
          response?.message ?? "Google authentication failed",
          code: response?.code,
          userId: response?.id,
          recoveryToken: response?.recoveryToken,
        ));
      }
    } catch (e) {
      emit(GoogleAuthFailure(e.toString()));
    }
  }
}
