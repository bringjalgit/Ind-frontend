import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Register/register_repo.dart';
import 'package:classifieds/data/cubit/Register/register_states.dart';

class RegisterCubit extends Cubit<RegisterStates> {
  RegisterRepo registerRepo;
  RegisterCubit(this.registerRepo) : super(RegisterInitially());

  Future<void> register(Map<String, dynamic> data) async {
    emit(RegisterLoading());
    try {
      final response = await registerRepo.register(data);
      if (response != null && response.success == true) {
        emit(RegisterLoaded(response));
      } else {
        // Default to a user-readable message when the backend didn't send
        // one (e.g. response body couldn't be parsed). Empty strings used
        // to surface as blank snackbars with no explanation.
        emit(RegisterFailure(
          response?.message?.trim().isNotEmpty == true
              ? response!.message!
              : 'Something went wrong. Please try again.',
        ));
      }
    } catch (_) {
      // Never show raw stack-trace-like exception text to end users.
      emit(RegisterFailure('Something went wrong. Please try again.'));
    }
  }
}
