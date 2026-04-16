import 'package:classifieds/services/BackendResolver.dart';

/// API endpoint URLs.
///
/// ⚠️ DUAL-BACKEND ROUTING — read this before adding a new endpoint.
///
/// There are TWO classes of endpoints in this app:
///
///   1. Main-stack endpoints (onboarding, profile, listing, payments, misc,
///      app-config-via-EC2): these are mirrored on both Lambda main stack
///      and the EC2 server. Exactly one is active at a time, controlled by
///      the `active_backend` flag in MongoDB AppConfig.
///
///      → Declare these as `static String get name => '${BackendResolver.currentBaseUrl}...'`
///      → They MUST be getters (not const) so they pick up the resolved
///        backend at call time.
///      → BackendResolver is initialized in main.dart before runApp.
///      → On 503 BACKEND_DORMANT, ApiClient auto-retries once after
///        BackendResolver.reresolve().
///
///   2. Chat-stack endpoints (chat REST + WebSocket + app-config + delete/
///      recovery account): these live ONLY on Lambda. The chat stack is
///      unguarded and always serves traffic.
///
///      → Declare these as `static const String name = '${chatLambdaUrl}...'`
///      → They stay on Lambda forever — never resolved.
///      → Note: app-config + delete/recovery historically live in the chat
///        stack for stack-grouping reasons. EC2 has parity wiring for them
///        but Flutter does not call EC2 for these.
///
/// Adding a new endpoint?
///   - If it's wired in serverless.yml / serverless.profile.yml /
///     serverless.listing.yml / serverless.payments.yml → main stack → getter
///   - If it's wired in serverless.chat.yml → chat stack → const
class APIEndpointUrls {
  // Old Express server base URL — kept for ApiClient.dart Dio base URL (legacy, not used for API calls)
  static const String baseUrl = 'https://api.indclassifieds.in/';

  // Main Lambda stack base — kept as a const ALIAS so any legacy reference
  // still resolves. Prefer BackendResolver.currentBaseUrl for new code; this
  // alias is only here so callers that want the literal Lambda URL (e.g.
  // logging, debugging) can still get it.
  static const String lambdaUrl =
      'https://tn7v9gtczd.execute-api.ap-south-1.amazonaws.com/dev/app/';

  // ── Authentication (main stack) ──────────────────────────────────────────
  static String get refreshtoken => '${BackendResolver.currentBaseUrl}refresh-token-for-user';
  static String get send_login_otp => '${BackendResolver.currentBaseUrl}send-otp';
  static String get verify_login_otp => '${BackendResolver.currentBaseUrl}verify-otp';
  static String get send_otp_email => '${BackendResolver.currentBaseUrl}send-otp-email';
  static String get verify_email_otp => '${BackendResolver.currentBaseUrl}verify-email-otp';
  static String get send_otp_email_for_verify => '${BackendResolver.currentBaseUrl}send-otp-email-for-verify';
  static String get verify_email_otp_for_verification => '${BackendResolver.currentBaseUrl}verify-email-otp-for-verification';
  // recovery_my_account + delete_my_account live on the chat stack — always Lambda
  static const String recovery_my_account = '${chatLambdaUrl}recovery-my-account';
  static const String delete_my_account = '${chatLambdaUrl}delete-my-account';
  static String get lambda_google_auth => '${BackendResolver.currentBaseUrl}google-auth';
  static String get register_user_details => '${BackendResolver.currentBaseUrl}register-user-details';

  // ── Profile (main stack) ─────────────────────────────────────────────────
  static String get get_my_profile_details => '${BackendResolver.currentBaseUrl}get-my-profile-details';
  static String get update_user_details_by_user => '${BackendResolver.currentBaseUrl}update-user-details-by-user';
  static String get get_profile_image_upload_url => '${BackendResolver.currentBaseUrl}get-profile-image-upload-url';

  // ── Aadhaar KYC (main stack) ─────────────────────────────────────────────
  static String get get_aadhaar_upload_url => '${BackendResolver.currentBaseUrl}get-aadhaar-image-upload-url';
  static String get submit_aadhaar_verification => '${BackendResolver.currentBaseUrl}submit-aadhaar-verification';
  static String get get_aadhaar_status => '${BackendResolver.currentBaseUrl}get-aadhaar-status';

  // ── Location (main stack) ────────────────────────────────────────────────
  static String get get_states => '${BackendResolver.currentBaseUrl}get-all-states';
  static String get get_city => '${BackendResolver.currentBaseUrl}get-all-cities';

  // ── Transactions (main stack) ────────────────────────────────────────────
  static String get get_transection_history => '${BackendResolver.currentBaseUrl}get-payments-transactions';

  // ── A: Categories (main stack) ───────────────────────────────────────────
  static String get get_category => '${BackendResolver.currentBaseUrl}get-all-categories-for-creating-list';
  static String get get_all_categories_for_post => '${BackendResolver.currentBaseUrl}get-categories-for-post';
  static String get get_sub_category => '${BackendResolver.currentBaseUrl}get-all-sub-categories';
  static String get get_all_carousels => '${BackendResolver.currentBaseUrl}get-all-active-carousels';
  static String get get_production_stats => '${BackendResolver.currentBaseUrl}get-production-stats';

  // ── B: Plans (main stack) ────────────────────────────────────────────────
  static String get get_user_active_plans => '${BackendResolver.currentBaseUrl}get-user-active-plans';
  static String get get_user_active_ad_plans => '${BackendResolver.currentBaseUrl}get-user-active-ad-plans';

  // ── C: Add Listing (main stack) ──────────────────────────────────────────
  static String get add_listing => '${BackendResolver.currentBaseUrl}add-listing';
  // Deprecated aliases kept temporarily so existing cubits compile
  static String get post_common_ad => add_listing;
  static String get post_mobile_ad => add_listing;
  static String get post_property_ad => add_listing;
  static String get post_cars_ad => add_listing;
  static String get post_bikes_ad => add_listing;
  static String get post_commercial_vehicle_ad => add_listing;
  static String get post_pets_ad => add_listing;
  static String get post_jobs_ad => add_listing;
  static String get post_education_ad => add_listing;
  static String get post_astrology_ad => add_listing;
  static String get post_community_ad => add_listing;
  static String get post_city_rentals_ad => add_listing;
  static String get post_co_working_ad => add_listing;

  // ── D: My Listings Management (main stack) ───────────────────────────────
  static String get get_listing_ad => '${BackendResolver.currentBaseUrl}get-single-listing-for-update';
  static String get update_listing_ad => '${BackendResolver.currentBaseUrl}edit-listing';
  static String get remove_image_on_listing_ad => '${BackendResolver.currentBaseUrl}delete-listing-image';
  static String get delete_listing_ad => '${BackendResolver.currentBaseUrl}delete-listing';

  // ── E: Browse / Discovery (main stack) ───────────────────────────────────
  static String get get_all_listings_with_pagination => '${BackendResolver.currentBaseUrl}get-all-listings-with-pagination';
  static String get global_search => '${BackendResolver.currentBaseUrl}global-search';
  static String get get_listings_by_category => '${BackendResolver.currentBaseUrl}get-listings-by-categories';
  static String get get_listings_by_sub_category => '${BackendResolver.currentBaseUrl}get-listings-by-sub-category';
  static String get get_single_listing_details => '${BackendResolver.currentBaseUrl}get-single-listing-details';

  // ── F: My Listings (main stack) ──────────────────────────────────────────
  static String get get_my_listings_list => '${BackendResolver.currentBaseUrl}get-my-listings-list';
  static String get change_status_to_sold => '${BackendResolver.currentBaseUrl}change-sold-status-to-listing';

  // ── G: Wishlist / Likes (main stack) ─────────────────────────────────────
  static String get like_toggle_to_product => '${BackendResolver.currentBaseUrl}toggle-listing-like';
  static String get get_all_liked_listings => '${BackendResolver.currentBaseUrl}get-liked-listings';

  // ── H: Advertisements (main stack) ───────────────────────────────────────
  static String get add_a_advertisement => '${BackendResolver.currentBaseUrl}add-advertisement';
  static String get get_all_my_advertisements => '${BackendResolver.currentBaseUrl}get-all-advertisements';
  static String get get_active_adversments_details => '${BackendResolver.currentBaseUrl}get-single-advertisement';
  static String get update_advertisement => '${BackendResolver.currentBaseUrl}update-advertisement';
  static String get delete_advertisement => '${BackendResolver.currentBaseUrl}delete-advertisement';

  // ── I: S3 Upload URLs (main stack) ───────────────────────────────────────
  static String get get_listing_image_upload_url => '${BackendResolver.currentBaseUrl}get-listing-image-upload-url';
  static String get get_advertisement_image_upload_url => '${BackendResolver.currentBaseUrl}get-advertisement-image-upload-url';

  // Sell with AI was removed from the frontend. Backend endpoints still
  // exist on the chat stack (serverless.chat.yml) in case the feature is
  // ever re-enabled in a future Flutter build.

  // ── Plans, Packages, Payments (main stack) ───────────────────────────────
  static String get get_all_active_plans => '${BackendResolver.currentBaseUrl}get-all-active-plans';
  static String get get_all_packages_by_plan => '${BackendResolver.currentBaseUrl}get-all-packages-by-plan';
  static String get create_payment_order => '${BackendResolver.currentBaseUrl}create-payment-order';
  static String get verify_payment_order => '${BackendResolver.currentBaseUrl}verify-payment';
  static String get create_payment_order_for_boost => '${BackendResolver.currentBaseUrl}create-payment-order-for-boost';
  static String get verify_payment_for_boost => '${BackendResolver.currentBaseUrl}verify-payment-for-boost';
  static String get verify_apple_payment => '${BackendResolver.currentBaseUrl}verify-apple-payment';

  // ── Misc (main stack) ────────────────────────────────────────────────────
  static String get get_featured_content => '${BackendResolver.currentBaseUrl}get-featured-content';
  static String get report => '${BackendResolver.currentBaseUrl}report';
  static String get all_contact_info => '${BackendResolver.currentBaseUrl}all-contact-info';
  static String get get_free_ad_info => '${BackendResolver.currentBaseUrl}get-free-ad-info';

  // ── Chat (chat stack — Lambda only, never resolved) ──────────────────────
  static const String chatLambdaUrl =
      'https://qwpymyp0pf.execute-api.ap-south-1.amazonaws.com/dev/app/';
  static const String chatWebSocketUrl =
      'wss://dogn6yxiv8.execute-api.ap-south-1.amazonaws.com/dev';

  static const String get_all_users_by_chat = '${chatLambdaUrl}get-all-users-by-chat';
  static const String get_my_friend_messages = '${chatLambdaUrl}get-my-friend-messages';
  static const String toggle_pin_user = '${chatLambdaUrl}toggle-pin-user';
  static const String toggle_pin_message = '${chatLambdaUrl}toggle-pin-message';
}
