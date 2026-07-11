import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/services/ReferralService.dart';
import 'package:classifieds/model/ReferralModels.dart';
import 'referral_state.dart';

class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit() : super(ReferralInitial());

  Future<void> load() async {
    emit(ReferralLoading());
    try {
      final info = await ReferralService.getInfo();
      if (!info.enabled) {
        emit(ReferralDisabled());
        return;
      }
      // The list is best-effort; a failure there shouldn't blank the screen.
      List<ReferredFriend> friends = const [];
      try {
        friends = await ReferralService.getList();
      } catch (_) {}
      emit(ReferralLoaded(info, friends));
    } catch (e) {
      emit(ReferralError('Could not load Refer & Earn. Pull to retry.'));
    }
  }

  /// Redeem 150 points for a free listing, then refresh the screen so the new
  /// balance + credit show. Returns the server result for a snackbar.
  Future<ApplyReferralResult> redeemFreeListing() async {
    final result = await ReferralService.redeemFreeListing();
    if (result.success) {
      await load();
    }
    return result;
  }
}
