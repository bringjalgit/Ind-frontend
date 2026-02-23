class APIEndpointUrls {
  // static const String baseUrl = 'http://192.168.80.176:8081/';
  // static const String socket_url = 'http://192.168.80.176:8081';

  static const String baseUrl = 'https://api.indclassifieds.in/';
  static const String socket_url = 'https://api.indclassifieds.in';
  static const String apiUrl = 'api/app/';

  /// Authentiocation Urls
  static const String register = '${apiUrl}Register';
  static const String refreshtoken = '${apiUrl}refresh-access-token';
  static const String send_login_otp = '${apiUrl}send-otp';
  static const String resend_login_otp = '${apiUrl}resend-login-otp';
  static const String verify_login_otp = '${apiUrl}verify-otp';
  static const String send_otp_email = '${apiUrl}send-otp-email';
  static const String verify_email_otp = '${apiUrl}verify-email-otp';
  static const String send_otp_email_for_verify =
      '${apiUrl}send-otp-email-for-verify';
  static const String verify_email_otp_for_verification =
      '${apiUrl}verify-email-otp-for-verification';
  static const String bypass_login = '${apiUrl}bypass-login';
  static const String get_my_profile_details =
      '${apiUrl}get-my-profile-details';
  static const String update_user_details_by_user =
      '${apiUrl}update-user-details-by-user';
  static const String get_category = '${apiUrl}get-all-categories';
  static const String get_sub_category = '${apiUrl}get-all-sub-categories';
  static const String get_listings_by_sub_category =
      '${apiUrl}get-listings-by-sub-category';
  static const String get_all_listings_with_pagination =
      '${apiUrl}get-all-listings-with-pagination';
  static const String get_all_liked_listings =
      '${apiUrl}get-all-liked-listings';
  static const String like_toggle_to_product =
      '${apiUrl}like-toggle-to-product';
  static const String get_states = '${apiUrl}get-all-states';
  static const String get_city = '${apiUrl}get-all-cities';
  static const String get_all_active_plans = '${apiUrl}get-all-active-plans';
  static const String get_all_packages_by_plan =
      '${apiUrl}get-all-packages-by-plan';
  static const String get_single_listing_details =
      '${apiUrl}get-single-listing-details';
  static const String get_my_listings_list = '${apiUrl}get-my-listings-list';
  static const String change_status_to_sold =
      '${apiUrl}change-sold-status-to-listing';
  static const String delete_listing_ad = '${apiUrl}delete-listing';
  static const String update_listing_ad = '${apiUrl}edit-listing-by-user';
  static const String get_listing_ad = '${apiUrl}get-single-listing-for-update';
  static const String remove_image_on_listing_ad =
      '${apiUrl}delete-image-by-user';
  static const String get_all_my_advertisements =
      '${apiUrl}get-all-my-advertisements';
  static const String add_a_advertisement = '${apiUrl}add-a-advertisement';
  static const String get_active_adversments_details =
      '${apiUrl}get-active-adversments-details';
  static const String get_all_carousels = '${apiUrl}get-all-carousels';
  static const String get_user_active_plans = '${apiUrl}get-user-active-plans';
  static const String recovery_my_account = '${apiUrl}recovery-my-account';
  static const String delete_my_account = '${apiUrl}delete-my-account';

  static const String post_common_ad = '${apiUrl}add-common-list-to-listings';
  static const String post_mobile_ad = '${apiUrl}add-mobile-to-listings';
  static const String post_property_ad = '${apiUrl}add-property-to-listings';
  static const String post_cars_ad = '${apiUrl}add-car-to-listings';
  static const String post_bikes_ad = '${apiUrl}add-bike-to-listings';
  static const String post_commercial_vehicle_ad =
      '${apiUrl}add-commercial-vehicle-to-listings';
  static const String post_pets_ad = '${apiUrl}add-pets-to-listings';
  static const String post_jobs_ad = '${apiUrl}add-jobs-to-listings';
  static const String post_education_ad = '${apiUrl}add-education-to-listings';
  static const String post_astrology_ad = '${apiUrl}add-astrology-to-listings';
  static const String post_community_ad = '${apiUrl}add-community-to-listings';
  static const String post_city_rentals_ad =
      '${apiUrl}add-city-rentals-to-listings';
  static const String post_co_working_ad =
      '${apiUrl}add-co-working-to-listings';
  static const String create_payment_order = '${apiUrl}create-payment-order';
  static const String verify_payment_order = '${apiUrl}verify-payment';
  static const String register_user_details = '${apiUrl}register-user-details';
  static const String get_all_users_by_chat = '${apiUrl}get-all-users-by-chat';
  static const String get_all_categories_for_post =
      '${apiUrl}get-all-categories-for-post';
  static const String get_my_friend_messages =
      '${apiUrl}get-my-friend-messages';
  static const String get_transection_history =
      '${apiUrl}get-payments-transactions';

  static const String create_payment_order_for_boost =
      '${apiUrl}create-payment-order-for-boost';

  static const String verify_payment_for_boost =
      '${apiUrl}verify-payment-for-boost';

  static const String get_featured_content = '${apiUrl}get-featured-content';
  static const String report = '${apiUrl}report';
  static const String all_contact_info = '${apiUrl}all-contact-info';
  static const String toggle_pin_user = '${apiUrl}toggle-pin-user';
}
