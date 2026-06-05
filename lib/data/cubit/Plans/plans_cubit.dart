import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Plans/plans_repository.dart';
import 'package:classifieds/data/cubit/Plans/plans_states.dart';

class PlansCubit extends Cubit<PlansStates> {
  PlansRepository plansRepository;
  PlansCubit(this.plansRepository) : super(PlansInitially());

  Future<void> getPlans() async {
    emit(PlansLoading());
    try {
      final response = await plansRepository.getPlans();
      if (response != null && response.success == true) {
        emit(PlansLoaded(response));
      } else {
        emit(PlansFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(PlansFailure(e.toString()));
    }
  }
}
