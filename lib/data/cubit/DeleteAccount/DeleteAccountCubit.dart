import 'package:flutter_bloc/flutter_bloc.dart';

import 'DeleteAccountRepository.dart';
import 'DeleteAccountStates.dart';

class DeleteAccountCubit extends Cubit<DeleteAccountStates> {
  DeleteAccountRepo deleteAccountRepo;
  DeleteAccountCubit(this.deleteAccountRepo) : super(DeleteAccountInitially());

  Future<void> deleteAccount() async {
    emit(DeleteAccountLoading());
    try {
      final response = await deleteAccountRepo.deleteAccount();
      if (response != null && response.success == true) {
        emit(DeleteAccountLoaded(response));
      } else {
        // L6 — default to a user-readable fallback so empty backend
        // message doesn't surface as a blank snackbar.
        final msg = (response?.message?.trim().isNotEmpty == true)
            ? response!.message!
            : 'Could not delete account. Please try again.';
        emit(DeleteAccountFailure(msg));
      }
    } catch (_) {
      emit(DeleteAccountFailure('Could not delete account. Please try again.'));
    }
  }
}
