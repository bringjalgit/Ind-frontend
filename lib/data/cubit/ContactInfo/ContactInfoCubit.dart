// cubit
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ContactInfoRepository.dart';
import 'ContactInfoStates.dart';

class ContactInfoCubit extends Cubit<ContactInfoStates> {
  ContactInfoRepository contactInfoRepository;
  ContactInfoCubit(this.contactInfoRepository) : super(ContactInfoInitially());

  Future<void> getContactInfo() async {
    emit(ContactInfoLoading());
    try {
      final response = await contactInfoRepository.getContactInfo();
      if (response != null && response.success == true) {
        emit(ContactInfoLoaded(response));
      } else {
        emit(ContactInfoFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(ContactInfoFailure(e.toString()));
    }
  }
}