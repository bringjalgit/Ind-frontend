import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Plans/plans_repository.dart';
import 'package:classifieds/data/cubit/UserActivePlans/user_active_plans_states.dart';
import 'package:classifieds/services/AuthService.dart';

import '../../../model/UserActivePlansModel.dart';

class UserActivePlanCubit extends Cubit<UserActivePlanStates> {
  PlansRepository plansRepository;
  UserActivePlanCubit(this.plansRepository) : super(UserActivePlanInitially());

  Future<UserActivePlansModel?> getUserActivePlansData() async {
    try {
      final response = await plansRepository.getUserActivePlans();
      if (response != null && response.success == true) {
        // Single source of truth for the "Subscribed User" badge. Whenever
        // active plans are (re)fetched — dashboard start, app resume, right
        // after a successful payment, or a post-ad flow — sync the badge flag.
        // Use the server's `has_active_subscription` (true whenever an active
        // paid purchase exists, even if listing quota is used up). Fall back to
        // plans-non-empty only when talking to an older backend that doesn't
        // send the field, so an app update can never regress the badge.
        // On a failed/null fetch we DON'T touch the flag (keeps the last known
        // value; no false "unsubscribed" flicker on a network blip).
        final subscribed = response.hasActiveSubscription ??
            ((response.plans?.length ?? 0) > 0);
        AuthService.setSubscribeStatus(subscribed ? "true" : "false");
        emit(UserActivePlanLoaded(response));
        return response;
      } else {
        emit(UserActivePlanFailure("Failed"));
        return null;
      }
    } catch (e) {
      emit(UserActivePlanFailure(e.toString()));
      return null;
    }
  }
}
