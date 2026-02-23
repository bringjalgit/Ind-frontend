import 'package:dio/dio.dart';
import 'package:classifieds/model/AddToWishlistModel.dart';
import 'package:classifieds/model/CategoryModel.dart';
import 'package:classifieds/utils/AppLogger.dart';
import '../model/AdSuccessModel.dart';
import '../model/AdvertisementDetailsModel.dart';
import '../model/AdvertisementModel.dart';
import '../model/BannersModel.dart';
import '../model/BoostAdModel.dart';
import '../model/ChatMessagesModel.dart';
import '../model/ChatUsersModel.dart';
import '../model/ContactInfoModel.dart';
import '../model/CreatePaymentModel.dart';
import '../model/FreeAdModel.dart';
import '../model/MarkAsListingModel.dart';
import '../model/MyAdsModel.dart';
import '../model/PackagesModel.dart';
import '../model/PlansModel.dart';
import '../model/ProductDetailsModel.dart';
import '../model/ProfileModel.dart';
import '../model/SelectCityModel.dart';
import '../model/SelectStatesModel.dart';
import '../model/SendOtpModel.dart';
import '../model/SubCategoryModel.dart';
import '../model/SubcategoryProductsModel.dart';
import '../model/TransectionHistoryModel.dart';
import '../model/UserActivePlansModel.dart';
import '../model/VerifyOtpModel.dart';
import '../model/WishlistModel.dart';
import '../model/getListingAdModel.dart';
import '../services/ApiClient.dart';
import '../services/api_endpoint_urls.dart';

abstract class RemoteDataSource {
  Future<SendOtpModel?> sendMobileOTP(Map<String, dynamic> data);
  Future<VerifyOtpModel?> verifyMobileOTP(Map<String, dynamic> data);
  Future<ProfileModel?> getProfileDetails();
  Future<AdSuccessModel?> updateProfileDetails(Map<String, dynamic> data);
  Future<CategoryModel?> getCategory();
  Future<CategoryModel?> getNewCategory();
  Future<BannersModel?> getBanners();
  Future<SubCategoryModel?> getSubCategory(String categoryId);
  Future<SubcategoryProductsModel?> getProducts({
    required int page,
    String? categoryId,
    String? subCategoryId,
    String? search,
    String? state_id,
    String? city_id,
    String? sort_by,
    String? minPrice,
    String? maxPrice,
    String? locationKey,
  });
  Future<ProductDetailsModel?> getProductDetails(int id);
  Future<WishlistModel?> getWishlistProducts(int page);
  Future<AddToWishlistModel?> addToWishlist(int product_id);
  Future<SelectStatesModel?> getStates(String search);
  Future<SelectCityModel?> getCity(int state_id, String search, int page);
  Future<PlansModel?> getPlans();
  Future<UserActivePlansModel?> getUserActivePlans();
  Future<PackagesModel?> getPackages(int id);
  Future<AdvertisementModel?> getAdvertisements(int page, String type);
  Future<AdSuccessModel?> postAdvertisement(Map<String, dynamic> data);
  Future<AdvertisementDetailsModel?> getAdvertisementDetails();
  Future<MyAdsModel?> getMyAds(String type, int page);
  Future<AdSuccessModel?> postCommonAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postCoWorkingAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postCityRentalsAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postCommunityAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postAstrologyAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postEducationAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postJobsAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postPetsAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postCommercialVehicleAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postBikeAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postCarsAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postPropertyAd(Map<String, dynamic> data);
  Future<AdSuccessModel?> postMobileAd(Map<String, dynamic> data);
  Future<CreatePaymentModel?> createPayment(Map<String, dynamic> data);
  Future<AdSuccessModel?> verifyPayment(Map<String, dynamic> data);
  Future<MarkAsListingModel?> markAsSold(int id);
  Future<MarkAsListingModel?> deleteListingAd(int id);
  Future<AdSuccessModel?> updateListingAd(String id, Map<String, dynamic> data);
  Future<getListingAdModel?> getListingAd(String id);
  Future<AdSuccessModel?> removeImageOnListingAd(int id);
  Future<AdSuccessModel?> register(Map<String, dynamic> data);
  Future<ChatUsersModel?> getChatUsers(String query);
  Future<ChatMessagesModel?> getChatMessages(
    String user_id,
    String listingId,
    int page,
  );
  Future<TransectionHistoryModel?> getTransections(int page);
  Future<CategoryModel?> getPostCategories();
  Future<AdSuccessModel?> deleteAccount();
  Future<AdSuccessModel?> recoverAccount(String id);
  Future<CreatePaymentModel?> boostAdCreatePayment(Map<String, dynamic> data);
  Future<AdSuccessModel?> boostAdVerifyPayment(Map<String, dynamic> data);
  Future<BoostAdModel?> getBoostAdInfoDetails();
  Future<AdSuccessModel?> reportAd(Map<String, dynamic> data);
  Future<SendOtpModel?> SendEmailOtp(Map<String, dynamic> data);
  Future<VerifyOtpModel?> verifyEmailOtp(Map<String, dynamic> data);
  Future<AdSuccessModel?> sendOTP(Map<String, dynamic> data);
  Future<AdSuccessModel?> verifyOTP(Map<String, dynamic> data);
  Future<VerifyOtpModel?> byPassLogin(Map<String, dynamic> data);
  Future<ContactInfoModel?> getContactInfo();
  Future<AdSuccessModel?> chatUserPin(Map<String, dynamic> data);
  Future<FreeAdModel?> getFreeAd();
}

class RemoteDataSourceImpl implements RemoteDataSource {
  Future<FormData> buildFormData(Map<String, dynamic> data) async {
    final formMap = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) continue;
      if (value is List) {
        formMap[key] = [
          for (final v in value)
            if (v is String && v.contains('/'))
              await MultipartFile.fromFile(v, filename: v.split('/').last)
            else
              v,
        ];
      } else if (value is String &&
          value.contains('/') &&
          (key.contains('images') ||
              key.contains('signature') ||
              (key.contains('image')))) {
        formMap[key] = await MultipartFile.fromFile(
          value,
          filename: value.split('/').last,
        );
      }
      // Normal fields
      else {
        formMap[key] = value;
      }
    }
    return FormData.fromMap(formMap);
  }

  @override
  Future<FreeAdModel?> getFreeAd() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_free_ad_info}",
      );
      AppLogger.log('getFreeAd:${response.data}');
      return FreeAdModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getFreeAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> chatUserPin(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.toggle_pin_user}",
        data: data,
      );
      AppLogger.log('chatUserPin:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('chatUserPin :: $e');
      return null;
    }
  }

  @override
  Future<ContactInfoModel?> getContactInfo() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.all_contact_info}",
      );
      AppLogger.log('getContactInfo:${response.data}');
      return ContactInfoModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getContactInfo :: $e');
      return null;
    }
  }

  @override
  Future<VerifyOtpModel?> byPassLogin(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.bypass_login}",
        data: data,
      );
      AppLogger.log('byPassLogin:${response.data}');
      return VerifyOtpModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('byPassLogin :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> verifyOTP(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.verify_email_otp_for_verification}",
        data: data,
      );
      AppLogger.log('verifyOTP:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('verifyOTP :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> sendOTP(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.send_otp_email_for_verify}",
        data: data,
      );
      AppLogger.log('sendOTP:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('sendOTP :: $e');
      return null;
    }
  }

  @override
  Future<VerifyOtpModel?> verifyEmailOtp(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.verify_email_otp}",
        data: data,
      );
      AppLogger.log('verifyEmailOtp:${response.data}');
      return VerifyOtpModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('verifyEmailOtp :: $e');
      return null;
    }
  }

  @override
  Future<SendOtpModel?> SendEmailOtp(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.send_otp_email}",
        data: data,
      );
      AppLogger.log('SendEmailOtp:${response.data}');
      return SendOtpModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('SendEmailOtp :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> reportAd(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.report}",
        data: data,
      );
      AppLogger.log('reportAd:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('reportAd :: $e');
      return null;
    }
  }

  @override
  Future<BoostAdModel?> getBoostAdInfoDetails() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_featured_content}",
      );
      AppLogger.log('getBoostAdInfoDetails:${response.data}');
      return BoostAdModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getBoostAdInfoDetails :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> boostAdVerifyPayment(
    Map<String, dynamic> data,
  ) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.verify_payment_for_boost}",
        data: data,
      );
      AppLogger.log('boostAdVerifyPayment:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('boostAdVerifyPayment :: $e');
      return null;
    }
  }

  @override
  Future<CreatePaymentModel?> boostAdCreatePayment(
    Map<String, dynamic> data,
  ) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.create_payment_order_for_boost}",
        data: data,
      );
      AppLogger.log('boostAdCreatePayment:${response.data}');
      return CreatePaymentModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('boostAdCreatePayment :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> recoverAccount(String id) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.recovery_my_account}/$id",
      );
      AppLogger.log('recoverAccount:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('recoverAccount :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> deleteAccount() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.delete_my_account}",
      );
      AppLogger.log('deleteAccount:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('deleteAccount :: $e');
      return null;
    }
  }

  @override
  Future<CategoryModel?> getPostCategories() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_all_categories_for_post}",
      );
      AppLogger.log('getPostCategories:${response.data}');
      return CategoryModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getPostCategories :: $e');
      return null;
    }
  }

  @override
  Future<ChatMessagesModel?> getChatMessages(
    String user_id,
    String listingId,
    int page,
  ) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_my_friend_messages}?listingId=${listingId}&friendId=${user_id}&page=${page}&limit=10",
      );
      AppLogger.log('getChatMessages:${response.data}');
      return ChatMessagesModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getChatMessages :: $e');
      return null;
    }
  }

  @override
  Future<ChatUsersModel?> getChatUsers(String query) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_all_users_by_chat}?search=${query}",
      );
      AppLogger.log('getChatUsers:${response.data}');
      return ChatUsersModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getChatUsers :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> register(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.put(
        "${APIEndpointUrls.register_user_details}",
        data: data,
      );
      AppLogger.log('register:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('register :: $e');
      return null;
    }
  }

  @override
  Future<UserActivePlansModel?> getUserActivePlans() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_user_active_plans}",
      );
      AppLogger.log('getUserActivePlans:${response.data}');
      return UserActivePlansModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getUserActivePlans :: $e');
      return null;
    }
  }

  @override
  Future<TransectionHistoryModel?> getTransections(int page) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_transection_history}?page=$page",
      );
      AppLogger.log('getTransections :${response.data}');
      return TransectionHistoryModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getTransections :: $e');
      return null;
    }
  }

  @override
  Future<BannersModel?> getBanners() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_all_carousels}",
      );
      AppLogger.log('getBanners:${response.data}');
      return BannersModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getBanners :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postAdvertisement(Map<String, dynamic> data) async {
    try {
      final formdata = await buildFormData(data);
      Response response = await ApiClient.post(
        "${APIEndpointUrls.add_a_advertisement}",
        data: formdata,
      );
      AppLogger.log('postAdvertisement:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('postAdvertisement :: $e');
      return null;
    }
  }

  @override
  Future<AdvertisementDetailsModel?> getAdvertisementDetails() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_active_adversments_details}",
      );
      AppLogger.log('getAdvertisementDetails:${response.data}');
      return AdvertisementDetailsModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getAdvertisementDetails :: $e');
      return null;
    }
  }

  @override
  Future<AdvertisementModel?> getAdvertisements(int page, String type) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_all_my_advertisements}?page=${page}&status=${type}",
      );
      AppLogger.log('getAdvertisements:${response.data}');
      return AdvertisementModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getAdvertisements :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> updateProfileDetails(
    Map<String, dynamic> data,
  ) async {
    try {
      final formdata = await buildFormData(data);
      Response response = await ApiClient.put(
        "${APIEndpointUrls.update_user_details_by_user}",
        data: formdata,
      );
      AppLogger.log('updateProfileDetails:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('updateProfileDetails :: $e');
      return null;
    }
  }

  @override
  Future<ProfileModel?> getProfileDetails() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_my_profile_details}",
      );
      AppLogger.log('getProfileDetails:${response.data}');
      return ProfileModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getProfileDetails :: $e');
      return null;
    }
  }

  @override
  Future<MyAdsModel?> getMyAds(String type, int page) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_my_listings_list}?status=${type}&page=$page",
      );
      AppLogger.log('getMyAds:${response.data}');
      return MyAdsModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getMyAds :: $e');
      return null;
    }
  }

  @override
  Future<MarkAsListingModel?> markAsSold(int id) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.change_status_to_sold}/${id}",
      );
      AppLogger.log('mark As Sold:${response.data}');
      return MarkAsListingModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('mark As Sold :: $e');
      return null;
    }
  }

  @override
  Future<MarkAsListingModel?> deleteListingAd(int id) async {
    try {
      Response response = await ApiClient.delete(
        "${APIEndpointUrls.delete_listing_ad}/${id}",
      );
      AppLogger.log('mark As delete:${response.data}');
      return MarkAsListingModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('mark As delete :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> updateListingAd(
    String id,
    Map<String, dynamic> data,
  ) async {
    final formdata = await buildFormData(data);
    formdata.fields.forEach((field) {
      print('${field.key}: ${field.value}');
    });
    try {
      Response response = await ApiClient.put(
        "${APIEndpointUrls.update_listing_ad}/${id}",
        data: formdata,
      );
      AppLogger.log('mark As update:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('mark As update :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> removeImageOnListingAd(int id) async {
    try {
      Response response = await ApiClient.delete(
        "${APIEndpointUrls.remove_image_on_listing_ad}/${id}",
      );
      AppLogger.log('removeImage On Listing Ad:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('removeImage On Listing Ad :: $e');
      return null;
    }
  }

  @override
  Future<getListingAdModel?> getListingAd(String id) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_listing_ad}/${id}",
      );
      AppLogger.log('Get Listing ID:${response.data}');
      return getListingAdModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('Listing ID :: $e');
      return null;
    }
  }

  @override
  Future<ProductDetailsModel?> getProductDetails(int id) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_single_listing_details}/${id}",
      );
      AppLogger.log('getProductDetails:${response.data}');
      return ProductDetailsModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getProductDetails :: $e');
      return null;
    }
  }

  @override
  Future<PackagesModel?> getPackages(int id) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_all_packages_by_plan}/${id}",
      );
      AppLogger.log('getPackages:${response.data}');
      return PackagesModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getPackages :: $e');
      return null;
    }
  }

  @override
  Future<PlansModel?> getPlans() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_all_active_plans}",
      );
      AppLogger.log('getPlans:${response.data}');
      return PlansModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getPlans :: $e');
      return null;
    }
  }

  @override
  Future<AddToWishlistModel?> addToWishlist(int product_id) async {
    try {
      Map<String, dynamic> data = {"listingId": product_id};
      Response response = await ApiClient.post(
        "${APIEndpointUrls.like_toggle_to_product}",
        data: data,
      );
      AppLogger.log('addToWishlist:${response.data}');
      return AddToWishlistModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('addToWishlist :: $e');
      return null;
    }
  }

  @override
  Future<WishlistModel?> getWishlistProducts(int page) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_all_liked_listings}?page=${page}",
      );
      AppLogger.log('getWishlistProducts:${response.data}');
      return WishlistModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getWishlistProducts:: $e');
      return null;
    }
  }

  @override
  Future<SubcategoryProductsModel?> getProducts({
    String? categoryId,
    String? subCategoryId,
    String? search,
    String? state_id,
    String? city_id,
    String? sort_by,
    String? minPrice,
    String? maxPrice,
    String? locationKey,
    required int page,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        "page": page,
        if (categoryId != null && categoryId.isNotEmpty)
          "category_id": categoryId,
        if (subCategoryId != null && subCategoryId.isNotEmpty)
          "sub_category_id": subCategoryId,
        if (search != null && search.isNotEmpty) "search": search,
        if (sort_by != null && sort_by.isNotEmpty) "sort_by": sort_by,
        if (minPrice != null && minPrice.isNotEmpty) "min_price": minPrice,
        if (maxPrice != null && maxPrice.isNotEmpty) "max_price": maxPrice,
        if (state_id != null && state_id.isNotEmpty) "state_id": state_id,
        if (city_id != null && city_id.isNotEmpty) "city_id": city_id,
        if (locationKey != null && locationKey.isNotEmpty)
          "location_key": locationKey,
      };

      Response response = await ApiClient.get(
        APIEndpointUrls.get_all_listings_with_pagination,
        queryParameters: queryParams,
      );

      AppLogger.log('getProducts request: ${response.realUri}');
      AppLogger.log('getProducts response: ${response.data}');

      return SubcategoryProductsModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getProducts error: $e');
      return null;
    }
  }

  @override
  Future<SendOtpModel?> sendMobileOTP(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.send_login_otp}",
        data: data,
      );
      AppLogger.log('Send Mobile OTP :${response.data}');
      return SendOtpModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('Send Mobile OTP :: $e');
      return null;
    }
  }

  @override
  Future<VerifyOtpModel?> verifyMobileOTP(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.verify_login_otp}",
        data: data,
      );
      AppLogger.log('verify Mobile OTP :${response.data}');
      return VerifyOtpModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('verify Mobile OTP :: $e');
      return null;
    }
  }

  @override
  Future<CategoryModel?> getNewCategory() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_category}?featured_category=true",
      );
      AppLogger.log('getNewCategory :${response.data}');
      return CategoryModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getNewCategory :: $e');
      return null;
    }
  }

  @override
  Future<CategoryModel?> getCategory() async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_category}?featured_category=false",
      );
      AppLogger.log('get Category :${response.data}');
      return CategoryModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get Category :: $e');
      return null;
    }
  }

  @override
  Future<SubCategoryModel?> getSubCategory(String categoryId) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_sub_category}/${categoryId}",
      );
      AppLogger.log('get Sub Category :${response.data}');
      return SubCategoryModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get Sub Category :: $e');
      return null;
    }
  }

  @override
  Future<SelectStatesModel?> getStates(String search) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_states}?search=${search}",
      );
      AppLogger.log('get States :${response.data}');
      return SelectStatesModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get States:: $e');
      return null;
    }
  }

  @override
  Future<SelectCityModel?> getCity(
    int state_id,
    String search,
    int page,
  ) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_city}?state_id=${state_id}&search=${search}&page=${page}",
      );
      AppLogger.log('get City :${response.data}');
      return SelectCityModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get City :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postCommonAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_common_ad}",
        data: formData,
      );
      AppLogger.log('get CommonAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get CommonAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postMobileAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_mobile_ad}",
        data: formData,
      );
      AppLogger.log('get MobileAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get MobileAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postPropertyAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_property_ad}",
        data: formData,
      );
      AppLogger.log('get PropertyAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get PropertyAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postCarsAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    AppLogger.log(' cars :${formData}');
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_cars_ad}",
        data: formData,
      );
      AppLogger.log(' CarsAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error(' CarsAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postBikeAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    AppLogger.log(' AstrologyAd formData :${formData}');
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_bikes_ad}",
        data: formData,
      );
      AppLogger.log('get BikesAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get BikesAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postCommercialVehicleAd(
    Map<String, dynamic> data,
  ) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_commercial_vehicle_ad}",
        data: formData,
      );
      AppLogger.log('get CommercialVehicleAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get CommercialVehicleAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postPetsAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_pets_ad}",
        data: formData,
      );
      AppLogger.log('get PetsAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get PetsAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postJobsAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    AppLogger.log('JobsAd :${data}');
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_jobs_ad}",
        data: formData,
      );
      AppLogger.log('get JobsAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get JobsAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postEducationAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_education_ad}",
        data: formData,
      );
      AppLogger.log('get EducationAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get EducationAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postAstrologyAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    AppLogger.log(' AstrologyAd formData :${formData}');
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_astrology_ad}",
        data: formData,
      );
      AppLogger.log('AstrologyAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error(' AstrologyAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postCommunityAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_community_ad}",
        data: formData,
      );
      AppLogger.log('get CommunityAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get CommunityAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postCityRentalsAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_city_rentals_ad}",
        data: formData,
      );
      AppLogger.log('get CityRentalsAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get CityRentalsAd :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> postCoWorkingAd(Map<String, dynamic> data) async {
    final formData = await buildFormData(data);
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.post_co_working_ad}",
        data: formData,
      );
      AppLogger.log('get CoWorkingAd :${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('get CoWorkingAd :: $e');
      return null;
    }
  }

  @override
  Future<CreatePaymentModel?> createPayment(Map<String, dynamic> data) async {
    try {
      Response res = await ApiClient.post(
        "${APIEndpointUrls.create_payment_order}",
        data: data,
      );
      AppLogger.log('create Payment ::${res.data}');
      return CreatePaymentModel.fromJson(res.data);
    } catch (e) {
      AppLogger.error('create Payment  ::${e}');

      return null;
    }
  }

  @override
  Future<AdSuccessModel?> verifyPayment(Map<String, dynamic> data) async {
    try {
      Response res = await ApiClient.post(
        "${APIEndpointUrls.verify_payment_order}",
        data: data,
      );
      AppLogger.log('verify Payment ::${res.data}');
      return AdSuccessModel.fromJson(res.data);
    } catch (e) {
      AppLogger.error('verify Payment  ::${e}');

      return null;
    }
  }
}
