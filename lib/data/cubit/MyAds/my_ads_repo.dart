import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../model/MarkAsListingModel.dart';
import '../../../model/MyAdsModel.dart';
import '../../../model/getListingAdModel.dart';

abstract class MyAdsRepo {
  Future<MyAdsModel?> getMyAds(String type,int page);
  Future<MarkAsListingModel?> markAsSold(String id);
  Future<MarkAsListingModel?> markAsDelete(String id);
  Future<AdSuccessModel?> markAsUpdate(String id,Map<String,dynamic> data);
  Future<getListingAdModel?> markAsgetListingAD(String id);
  Future<AdSuccessModel?> removeImageOnListingAD(String imageUrl, String listingId);
}

class MyAdsRepoImpl implements MyAdsRepo {
  RemoteDataSource remoteDataSource;
  MyAdsRepoImpl({required this.remoteDataSource});

  @override
  Future<MyAdsModel?> getMyAds(String type,int page) async {
    return await remoteDataSource.getMyAds(type,page);
  }

  @override
  Future<MarkAsListingModel?> markAsSold(String id) async {
    return await remoteDataSource.markAsSold(id);
  }

  @override
  Future<MarkAsListingModel?> markAsDelete(String id) async {
    return await remoteDataSource.deleteListingAd(id);
  }
  @override
  Future<AdSuccessModel?> markAsUpdate(String id,Map<String,dynamic> data) async {
    return await remoteDataSource.updateListingAd(id,data);
  }

  @override
  Future<getListingAdModel?> markAsgetListingAD(String id) async {
    return await remoteDataSource.getListingAd(id);
  }
  @override
  Future<AdSuccessModel?> removeImageOnListingAD(String imageUrl, String listingId) async {
    return await remoteDataSource.removeImageOnListingAd(imageUrl, listingId);
  }
}
