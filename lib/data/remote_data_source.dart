import 'dart:io';
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
import '../model/AadhaarStatusModel.dart';
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
  Future<ProductDetailsModel?> getProductDetails(String id);
  Future<WishlistModel?> getWishlistProducts(int page);
  Future<AddToWishlistModel?> addToWishlist(String product_id);
  Future<SelectStatesModel?> getStates(String search);
  Future<SelectCityModel?> getCity(int state_id, String search, int page);
  Future<PlansModel?> getPlans();
  Future<UserActivePlansModel?> getUserActivePlans();
  Future<PackagesModel?> getPackages(dynamic id);
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
  Future<MarkAsListingModel?> markAsSold(String id);
  Future<MarkAsListingModel?> deleteListingAd(String id);
  Future<AdSuccessModel?> updateListingAd(String id, Map<String, dynamic> data);
  Future<getListingAdModel?> getListingAd(String id);
  Future<AdSuccessModel?> removeImageOnListingAd(String imageUrl, String listingId);
  Future<AdSuccessModel?> register(Map<String, dynamic> data);
  Future<ChatUsersModel?> getChatUsers(String query, {int page = 1});
  Future<ChatMessagesModel?> getChatMessages(
    String user_id,
    String listingId,
    int page,
  );
  Future<TransectionHistoryModel?> getTransections(int page);
  Future<CategoryModel?> getPostCategories();
  Future<AdSuccessModel?> deleteAccount();
  Future<AdSuccessModel?> recoverAccount(String recoveryToken);
  Future<CreatePaymentModel?> boostAdCreatePayment(Map<String, dynamic> data);
  Future<AdSuccessModel?> boostAdVerifyPayment(Map<String, dynamic> data);
  Future<BoostAdModel?> getBoostAdInfoDetails();
  Future<AdSuccessModel?> reportAd(Map<String, dynamic> data);
  Future<SendOtpModel?> SendEmailOtp(Map<String, dynamic> data);
  Future<VerifyOtpModel?> verifyEmailOtp(Map<String, dynamic> data);
  Future<AdSuccessModel?> sendOTP(Map<String, dynamic> data);
  Future<AdSuccessModel?> verifyOTP(Map<String, dynamic> data);
  Future<ContactInfoModel?> getContactInfo();
  Future<AdSuccessModel?> chatUserPin(Map<String, dynamic> data);
  Future<FreeAdModel?> getFreeAd();
  Future<VerifyOtpModel?> googleAuth(Map<String, dynamic> data);

  // ── Aadhaar KYC ─────────────────────────────────────────────────────────
  Future<AadhaarStatusModel?> getAadhaarStatus();
  /// Returns {upload_url, file_url} map on success. Throws on failure
  /// (DioException or explicit backend error) — caller converts to state.
  Future<Map<String, String>> uploadAadhaarImage({
    required String side, // 'front' | 'back'
    required String localPath,
  });
  Future<AadhaarStatusModel?> submitAadhaar({
    required String frontUrl,
    required String backUrl,
  });
}

class RemoteDataSourceImpl implements RemoteDataSource {
  /// Uploads local image files to S3 via pre-signed URLs.
  /// [images] can be List<File> or List<String> (local paths).
  /// Returns list of S3 public URLs.
  /// Upload local image files to S3 via per-file presigned URLs.
  ///
  /// Throws `Exception` on the FIRST upload failure. The previous version
  /// silently caught per-file errors and returned whatever happened to
  /// succeed — which meant a user could pick 4 images, all 4 uploads
  /// could fail (e.g. auth issue, S3 misconfig, network blip), and the
  /// caller would receive an empty array. The caller would then send
  /// `images: []` to addListing and the backend would reject with
  /// MIN_IMAGES, which surfaced to the user as a generic "post failed"
  /// with no actionable info.
  ///
  /// Failing fast lets the caller (`_postAd`) report a real error to the
  /// UI and lets the user know whether the problem was image upload or
  /// the listing creation itself.
  Future<List<String>> _uploadImagesToS3(List<dynamic> images, {String? uploadEndpoint}) async {
    final List<String> s3Urls = [];
    final endpoint = uploadEndpoint ?? APIEndpointUrls.get_listing_image_upload_url;
    for (var i = 0; i < images.length; i++) {
      final img = images[i];
      try {
        final File file = img is File ? img : File(img as String);
        if (!await file.exists()) {
          throw Exception('Image ${i + 1} not found on device');
        }

        // Sanitize filename to match the backend's allowlist
        // (/^[A-Za-z0-9._-]+$/). Same rationale as profile image upload:
        // Android picker returns "WhatsApp Image 2024.jpg" with spaces,
        // and the listing endpoint replaces non-allowed chars with `_`
        // server-side anyway, but doing it client-side keeps the
        // returned file_url predictable.
        final rawName = file.path.split('/').last;
        final sanitized = rawName
            .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
            .replaceAll(RegExp(r'^\.+'), '')
            .replaceAll(RegExp(r'\.{2,}'), '.');
        final filename = sanitized.length > 128
            ? sanitized.substring(sanitized.length - 128)
            : sanitized;

        final ext = filename.split('.').last.toLowerCase();
        final contentType = (ext == 'png')
            ? 'image/png'
            : (ext == 'gif')
            ? 'image/gif'
            : (ext == 'webp')
            ? 'image/webp'
            : 'image/jpeg';

        // Step 1: Get presigned upload URL from backend
        Response urlResponse;
        try {
          urlResponse = await ApiClient.post(
            endpoint,
            data: {'filename': filename, 'content_type': contentType},
          );
        } on DioException catch (e) {
          // Surface the backend's error body if present
          final body = e.response?.data;
          final msg = (body is Map && body['message'] is String)
              ? body['message']
              : 'Failed to get upload URL for image ${i + 1}';
          throw Exception(msg);
        }

        if (urlResponse.statusCode != 200 || urlResponse.data['success'] != true) {
          final body = urlResponse.data;
          final msg = (body is Map && body['message'] is String)
              ? body['message']
              : 'Backend rejected upload URL for image ${i + 1}';
          throw Exception(msg);
        }

        final uploadUrl = urlResponse.data['upload_url'] as String;
        final fileUrl = urlResponse.data['file_url'] as String;

        // Step 2: PUT file directly to S3 (no auth headers, signed URL)
        try {
          final s3Dio = Dio();
          final fileBytes = await file.readAsBytes();
          await s3Dio.put(
            uploadUrl,
            data: fileBytes,
            options: Options(
              headers: {
                'Content-Type': contentType,
                'Content-Length': fileBytes.length,
              },
            ),
          );
        } catch (e) {
          throw Exception('S3 upload failed for image ${i + 1}: $e');
        }

        s3Urls.add(fileUrl);
      } catch (e) {
        AppLogger.error('S3 image upload failed (image ${i + 1}): $e');
        rethrow; // ← was `return s3Urls;` (silent). Now the caller knows.
      }
    }
    return s3Urls;
  }

  /// Unified post-ad method used by all 13 category cubits.
  /// Uploads images to S3, then POSTs as JSON to Lambda add-listing.
  ///
  /// Returns a populated AdSuccessModel even on backend failures (4xx) so
  /// the cubit can read `success`, `code`, and `message` and route the UI.
  /// Returns null only on hard exceptions (image upload failed, network
  /// down, Dio threw without a parseable body) — in which case the
  /// AppLogger error line shows what went wrong.
  ///
  /// The previous version had two silent-failure bugs:
  ///   1. _uploadImagesToS3 swallowed per-image errors and returned
  ///      partial results — so a complete upload failure produced
  ///      images:[] which then triggered backend MIN_IMAGES, surfacing
  ///      to the user as "post failed" with no actionable hint.
  ///   2. The Dio catch here threw away the response body, so backend
  ///      errors like INVALID_SUBCATEGORY / INVALID_PRICE / FREE_LISTING_USED
  ///      never reached the UI. Same anti-pattern as the OTP swallow.
  Future<AdSuccessModel?> _postAd(Map<String, dynamic> data) async {
    try {
      // Upload any local images to S3. _uploadImagesToS3 now throws on
      // failure instead of returning a partial list silently.
      final rawImages = data['images'];
      if (rawImages != null && rawImages is List && rawImages.isNotEmpty) {
        final s3Urls = await _uploadImagesToS3(rawImages.cast<dynamic>());
        data['images'] = s3Urls;
      } else {
        data['images'] = [];
      }

      Response response = await ApiClient.post(
        APIEndpointUrls.add_listing,
        data: data,
      );
      AppLogger.log('postAd: ${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } on DioException catch (e) {
      // Backend 4xx (MIN_IMAGES, INVALID_SUBCATEGORY, FREE_LISTING_USED,
      // PLAN_LIMIT_REACHED, MISSING_FIELDS, etc.) reaches here because
      // ApiClient's interceptor rejects with a DioException that carries
      // the response body. Parse it so the cubit can show the real message.
      AppLogger.error('postAd dio: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        try {
          return AdSuccessModel.fromJson(e.response!.data);
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      // Image upload failure or other non-Dio exception. Wrap it as a
      // failure-shaped AdSuccessModel so the cubit shows a real error
      // instead of a blank "Failed".
      AppLogger.error('postAd :: $e');
      return AdSuccessModel(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

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
    } on DioException catch (e) {
      AppLogger.error('verifyEmailOtp dio: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        try {
          return VerifyOtpModel.fromJson(e.response!.data);
        } catch (_) {
          return null;
        }
      }
      return null;
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
    } on DioException catch (e) {
      AppLogger.error('SendEmailOtp dio: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        try {
          return SendOtpModel.fromJson(e.response!.data);
        } catch (_) {
          return null;
        }
      }
      return null;
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
  Future<AdSuccessModel?> recoverAccount(String recoveryToken) async {
    try {
      // P0-profile-1: path param removed; recovery_token goes in the body.
      // The backend verifies it (short-lived signed JWT, aud=recovery) and
      // sources the userId from the token's sub claim, not from the client.
      Response response = await ApiClient.post(
        APIEndpointUrls.recovery_my_account,
        data: {"recovery_token": recoveryToken},
      );
      AppLogger.log('recoverAccount:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } on DioException catch (e) {
      // Preserve the backend's error body so the recovery screen can show
      // "recovery token expired / invalid" instead of a blank snackbar.
      AppLogger.error('recoverAccount dio: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        try {
          return AdSuccessModel.fromJson(e.response!.data);
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('recoverAccount :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> deleteAccount() async {
    try {
      Response response = await ApiClient.post(
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
  Future<ChatUsersModel?> getChatUsers(String query, {int page = 1}) async {
    try {
      Response response = await ApiClient.get(
        "${APIEndpointUrls.get_all_users_by_chat}?search=${query}&page=$page",
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
      Response response = await ApiClient.post(
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
      Response response = await ApiClient.post(
        "${APIEndpointUrls.get_transection_history}",
        data: {"page": page},
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
      // Upload image to S3 if it's a local file path
      final rawImage = data['image'];
      if (rawImage != null && rawImage is String && rawImage.isNotEmpty && !rawImage.startsWith('http')) {
        final urls = await _uploadImagesToS3(
          [rawImage],
          uploadEndpoint: APIEndpointUrls.get_advertisement_image_upload_url,
        );
        if (urls.isNotEmpty) data['image'] = urls.first;
      }

      Response response = await ApiClient.post(
        "${APIEndpointUrls.add_a_advertisement}",
        data: data,
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
        "${APIEndpointUrls.get_user_active_ad_plans}",
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
      Response response = await ApiClient.post(
        "${APIEndpointUrls.get_all_my_advertisements}",
        data: {"page": page, "status": type},
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
      String? uploadedImageUrl;

      // If a local image path is provided, upload to S3 first
      final localImagePath = data['image'];
      if (localImagePath != null &&
          localImagePath is String &&
          localImagePath.isNotEmpty &&
          !localImagePath.startsWith('http')) {
        final rawFilename = localImagePath.split('/').last;
        // P1-profile-4 (Flutter side): the backend strictly validates
        // filename via /^[A-Za-z0-9._-]+$/. Android ImagePicker returns
        // names like "WhatsApp Image 2024.jpg" with spaces, which the
        // backend rejects with 400. Pre-sanitize on the client side so
        // the strict server-side validation doesn't break the common
        // gallery-pick UX. Replace every invalid char with an
        // underscore; leading dots are stripped (no dotfiles).
        final sanitized = rawFilename
            .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
            .replaceAll(RegExp(r'^\.+'), '')
            .replaceAll(RegExp(r'\.{2,}'), '.');
        // Cap length at 128 to match backend.
        final filename = sanitized.length > 128
            ? sanitized.substring(sanitized.length - 128)
            : sanitized;
        final ext = filename.split('.').last.toLowerCase();
        final contentType = (ext == 'png')
            ? 'image/png'
            : (ext == 'gif')
            ? 'image/gif'
            : (ext == 'webp')
            ? 'image/webp'
            : 'image/jpeg';

        // Step 1: Get S3 pre-signed upload URL
        final urlResponse = await ApiClient.post(
          APIEndpointUrls.get_profile_image_upload_url,
          data: {'filename': filename, 'content_type': contentType},
        );

        if (urlResponse.statusCode == 200 &&
            urlResponse.data['success'] == true) {
          final uploadUrl = urlResponse.data['upload_url'] as String;
          final fileUrl = urlResponse.data['file_url'] as String;

          // Step 2: PUT file directly to S3 (no auth headers)
          final s3Dio = Dio();
          final fileBytes = await File(localImagePath).readAsBytes();
          await s3Dio.put(
            uploadUrl,
            data: fileBytes,
            options: Options(
              headers: {
                'Content-Type': contentType,
                'Content-Length': fileBytes.length,
              },
            ),
          );
          uploadedImageUrl = fileUrl;
        }
      }

      // Step 3: Build JSON body for profile update
      final body = <String, dynamic>{
        'name': data['name'],
        'email': data['email'],
        'mobile': data['mobile'],
        'state_id': data['state_id'],
        'city_id': data['city_id'],
        if (uploadedImageUrl != null) 'image_url': uploadedImageUrl,
      };

      Response response = await ApiClient.post(
        APIEndpointUrls.update_user_details_by_user,
        data: body,
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
      Response response = await ApiClient.post(
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
  Future<MarkAsListingModel?> markAsSold(String id) async {
    try {
      Response response = await ApiClient.post(
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
  Future<MarkAsListingModel?> deleteListingAd(String id) async {
    try {
      Response response = await ApiClient.post(
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
    try {
      // Upload any newly added local images to S3, then send as new_images
      final rawImages = data['images'];
      data.remove('images');
      if (rawImages != null && rawImages is List && rawImages.isNotEmpty) {
        final s3Urls = await _uploadImagesToS3(rawImages.cast<dynamic>());
        if (s3Urls.isNotEmpty) data['new_images'] = s3Urls;
      }

      Response response = await ApiClient.post(
        "${APIEndpointUrls.update_listing_ad}/${id}",
        data: data,
      );
      AppLogger.log('mark As update:${response.data}');
      return AdSuccessModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('mark As update :: $e');
      return null;
    }
  }

  @override
  Future<AdSuccessModel?> removeImageOnListingAd(String imageUrl, String listingId) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.remove_image_on_listing_ad}",
        data: {"listing_id": listingId, "image_url": imageUrl},
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
  Future<ProductDetailsModel?> getProductDetails(String id) async {
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
  Future<PackagesModel?> getPackages(dynamic id) async {
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
  Future<AddToWishlistModel?> addToWishlist(String product_id) async {
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
      Response response = await ApiClient.post(
        "${APIEndpointUrls.get_all_liked_listings}",
        data: {"page": page},
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

      Response response = await ApiClient.post(
        APIEndpointUrls.get_all_listings_with_pagination,
        data: queryParams,
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
    } on DioException catch (e) {
      // Backend 429 RATE_LIMITED and 500 SERVER_ERROR reach here; preserve
      // the body so the user sees the real reason instead of a blank snackbar.
      AppLogger.error('Send Mobile OTP dio: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        try {
          return SendOtpModel.fromJson(e.response!.data);
        } catch (_) {
          return null;
        }
      }
      return null;
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
    } on DioException catch (e) {
      // Preserve the backend's error body (code, message, recovery_token
      // on ACCOUNT_DELETED) so the cubit/UI can show the real reason.
      // Without this, wrong-OTP and rate-limit errors surface as blank
      // snackbars and the user has no clue what went wrong.
      AppLogger.error('verify Mobile OTP dio: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        try {
          return VerifyOtpModel.fromJson(e.response!.data);
        } catch (_) {
          return null;
        }
      }
      return null;
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
  Future<AdSuccessModel?> postCommonAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postMobileAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postPropertyAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postCarsAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postBikeAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postCommercialVehicleAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postPetsAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postJobsAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postEducationAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postAstrologyAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postCommunityAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postCityRentalsAd(Map<String, dynamic> data) => _postAd(data);

  @override
  Future<AdSuccessModel?> postCoWorkingAd(Map<String, dynamic> data) => _postAd(data);

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

  @override
  Future<VerifyOtpModel?> googleAuth(Map<String, dynamic> data) async {
    try {
      Response response = await ApiClient.post(
        "${APIEndpointUrls.lambda_google_auth}",
        data: data,
      );
      AppLogger.log('googleAuth:${response.data}');
      return VerifyOtpModel.fromJson(response.data);
    } on DioException catch (e) {
      // Preserve backend error body — especially ACCOUNT_DELETED (which
      // carries recovery_token) and EMAIL_IN_USE from P0-8 googleAuth.
      AppLogger.error('googleAuth dio: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        try {
          return VerifyOtpModel.fromJson(e.response!.data);
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('googleAuth :: $e');
      return null;
    }
  }

  // ── Aadhaar KYC ─────────────────────────────────────────────────────────
  // These intentionally surface DioException bodies instead of silently
  // returning null — the Aadhaar UI needs to distinguish "rate-limited"
  // from "wrong state" from "network dead". The cubit layer converts
  // thrown AadhaarException into a typed Failure state.

  @override
  Future<AadhaarStatusModel?> getAadhaarStatus() async {
    try {
      final response = await ApiClient.get(APIEndpointUrls.get_aadhaar_status);
      AppLogger.log('getAadhaarStatus :: ${response.data}');
      return AadhaarStatusModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Failed to load verification status';
      AppLogger.error('getAadhaarStatus :: $msg');
      throw AadhaarException(msg, code: (data is Map) ? data['code']?.toString() : null);
    }
  }

  @override
  Future<Map<String, String>> uploadAadhaarImage({
    required String side,
    required String localPath,
  }) async {
    // Mirror the filename sanitization + content-type detection used by
    // updateProfileDetails — backend enforces /^[A-Za-z0-9._-]+$/ and
    // 128-char cap. Keep client in lockstep so gallery picks with spaces
    // in the filename don't 400.
    final rawFilename = localPath.split(Platform.pathSeparator).last.split('/').last;
    final sanitized = rawFilename
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'^\.+'), '')
        .replaceAll(RegExp(r'\.{2,}'), '.');
    final filename = sanitized.length > 128
        ? sanitized.substring(sanitized.length - 128)
        : sanitized;
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    final contentType = (ext == 'png')
        ? 'image/png'
        : (ext == 'webp')
            ? 'image/webp'
            : 'image/jpeg';

    try {
      // Step 1: presigned URL from backend
      final urlResponse = await ApiClient.post(
        APIEndpointUrls.get_aadhaar_upload_url,
        data: {
          'side': side,
          'filename': filename,
          'content_type': contentType,
        },
      );
      if (urlResponse.statusCode != 200 || urlResponse.data['success'] != true) {
        final msg = (urlResponse.data is Map && urlResponse.data['message'] is String)
            ? urlResponse.data['message'] as String
            : 'Could not get upload URL';
        throw AadhaarException(msg,
            code: (urlResponse.data is Map) ? urlResponse.data['code']?.toString() : null);
      }
      final uploadUrl = urlResponse.data['upload_url'] as String;
      final fileUrl = urlResponse.data['file_url'] as String;

      // Step 2: direct S3 PUT with a fresh Dio (no auth interceptors —
      // presigned URL carries its own signature; attaching our Bearer
      // token breaks SigV4 canonicalization).
      final s3Dio = Dio();
      final fileBytes = await File(localPath).readAsBytes();
      await s3Dio.put(
        uploadUrl,
        data: fileBytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': fileBytes.length,
          },
        ),
      );
      return {'upload_url': uploadUrl, 'file_url': fileUrl};
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Upload failed. Please try again.';
      AppLogger.error('uploadAadhaarImage($side) :: $msg');
      throw AadhaarException(msg, code: (data is Map) ? data['code']?.toString() : null);
    }
  }

  @override
  Future<AadhaarStatusModel?> submitAadhaar({
    required String frontUrl,
    required String backUrl,
  }) async {
    try {
      final response = await ApiClient.post(
        APIEndpointUrls.submit_aadhaar_verification,
        data: {'front_url': frontUrl, 'back_url': backUrl},
      );
      AppLogger.log('submitAadhaar :: ${response.data}');
      return AadhaarStatusModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Submission failed. Please try again.';
      AppLogger.error('submitAadhaar :: $msg');
      throw AadhaarException(msg, code: (data is Map) ? data['code']?.toString() : null);
    }
  }
}

/// Thrown by the Aadhaar data-source methods so the cubit can render a
/// typed error state (message + optional backend code like
/// RATE_LIMITED / CONFLICT / VALIDATION_ERROR).
class AadhaarException implements Exception {
  final String message;
  final String? code;
  AadhaarException(this.message, {this.code});
  @override
  String toString() => 'AadhaarException($code): $message';
}
