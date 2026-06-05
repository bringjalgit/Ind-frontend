import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/RecoverAccount/recover_account_repository.dart';
import 'package:classifieds/data/cubit/RecoverAccount/recover_account_states.dart';

class RecoverAccountCubit extends Cubit<RecoverAccountStates> {
  RecoverAccountRepo recoverAccountRepo;
  RecoverAccountCubit(this.recoverAccountRepo)
    : super(RecoverAccountInitially());

  Future<void> recoverAccount(String recoveryToken) async {
    emit(RecoverAccountLoading());
    try {
      final response = await recoverAccountRepo.recoverAccount(recoveryToken);
      if (response != null && response.success == true) {
        emit(RecoverAccountLoaded(response));
      } else {
        // Backend returns { success, code, message } — AdSuccessModel.error
        // is never populated (only .message is). Reading .error here caused
        // an empty error snackbar on every recovery failure.
        emit(RecoverAccountFailure(response?.message ?? "Account recovery failed"));
      }
    } catch (e) {
      emit(RecoverAccountFailure(e.toString()));
    }
  }
}
