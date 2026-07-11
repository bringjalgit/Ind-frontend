import 'package:flutter_bloc/flutter_bloc.dart';
import 'community_ad_repo.dart';
import 'community_ad_states.dart';

class CommunityAdCubit extends Cubit<CommunityAdStates> {
  CommunityAdRepository communityAdRepository;
  CommunityAdCubit(this.communityAdRepository) : super(CommunityAdInitially());

  Future<void> postAstrologyAd(Map<String, dynamic> data) async {
    emit(CommunityAdLoading());
    try {
      final response = await communityAdRepository.postCommunityAd(data);
      if (response != null && response.success == true) {
        emit(CommunityAdSuccess(response));
      } else {
        emit(CommunityAdFailure(response?.message ?? ""));
      }
    } catch (e) {
      emit(CommunityAdFailure(e.toString()));
    }
  }
}
