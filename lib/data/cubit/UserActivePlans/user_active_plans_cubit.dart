import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Plans/plans_repository.dart';
import 'package:classifieds/data/cubit/UserActivePlans/user_active_plans_states.dart';

import '../../../model/UserActivePlansModel.dart';

class UserActivePlanCubit extends Cubit<UserActivePlanStates> {
  PlansRepository plansRepository;
  UserActivePlanCubit(this.plansRepository) : super(UserActivePlanInitially());

  Future<UserActivePlansModel?> getUserActivePlansData() async {
    try {
      final response = await plansRepository.getUserActivePlans();
      if (response != null && response.success == true) {
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
