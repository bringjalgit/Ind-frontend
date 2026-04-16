import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/Packages/packages_repository.dart';
import 'package:classifieds/data/cubit/Packages/packages_states.dart';

class PackagesCubit extends Cubit<PackagesStates> {
  PackagesRepository packagesRepository;
  PackagesCubit(this.packagesRepository) : super(PackagesInitially());

  Future<void> getPackages(dynamic id) async {
    emit(PackagesLoading());
    try {
      final response = await packagesRepository.getPackages(id);
      if (response != null && response.success == true) {
        emit(PackagesLoaded(response));
      } else {
        emit(PackagesFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(PackagesFailure(e.toString()));
    }
  }
}
