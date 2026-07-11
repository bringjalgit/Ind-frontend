import 'package:flutter_bloc/flutter_bloc.dart';
import 'jobs_ad_repo.dart';
import 'jobs_ad_states.dart';

class JobsAdCubit extends Cubit<JobsAdStates> {
  JobsAdRepository jobsAdRepository;
  JobsAdCubit(this.jobsAdRepository) : super(JobsAdInitially());

  Future<void> postjobsAd(Map<String, dynamic> data) async {
    emit(JobsAdLoading());
    try {
      final response = await jobsAdRepository.postJobsAd(data);
      if (response != null && response.success == true) {
        emit(JobsAdSuccess(response));
      } else {
        emit(JobsAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(JobsAdFailure(e.toString()));
    }
  }
}
