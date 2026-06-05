import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/States/states_repository.dart';
import 'package:classifieds/data/cubit/subCategory/sub_category_repository.dart';

import 'states_state.dart';

class SelectStatesCubit extends Cubit<SelectStates> {
  SelectStateRepository selectStateRepository;
  SelectStatesCubit(this.selectStateRepository)
    : super(SelectStatesInitially());

  Future<void> getSelectStates(String search) async {
    emit(SelectStatesLoading());
    try {
      final response = await selectStateRepository.getStates(search);
      if (response != null && response.success == true) {
        emit(SelectStatesLoaded(response));
      } else {
        emit(SelectStatesFailure("Failure To Load Data"));
      }
    } catch (e) {
      emit(SelectStatesFailure(e.toString()));
    }
  }
}
