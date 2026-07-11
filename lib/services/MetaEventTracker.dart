import 'package:facebook_app_events/facebook_app_events.dart';

import 'package:facebook_app_events/facebook_app_events.dart';

/// 🧠 Global Meta (Facebook) App Event Tracker
/// For OLX-type marketplace apps — buyers, sellers, chat, payments, etc.
class MetaEventTracker {
  static final FacebookAppEvents _fb = FacebookAppEvents();

  static Future<void> initialize() async {
    print('Facebook App Events initialized');
  }

  /// 🔹 Generic logger
  static Future<void> log(String name, {Map<String, dynamic>? params}) async {
    await _fb.logEvent(name: name, parameters: params);
  }

  // ────────────────────────────────
  // 🧍 USER LIFECYCLE EVENTS
  // ────────────────────────────────
  static Future<void> appOpen() => log('app_open');
  static Future<void> login({String method = 'email'}) =>
      log('login', params: {'method': method});
  static Future<void> signup({String method = 'email'}) =>
      log('complete_registration', params: {'method': method});
  static Future<void> logout() => log('logout');

  // ────────────────────────────────
  // 🔍 BROWSING / DISCOVERY EVENTS
  // ────────────────────────────────
  static Future<void> viewHome() => log('view_home');
  static Future<void> search(String query) =>
      log('search', params: {'query': query});
  static Future<void> viewItem({
    required String itemId,
    required String itemName,
    String? category,
    double? price,
  }) => log(
    'view_item',
    params: {
      'item_id': itemId,
      'item_name': itemName,
      if (category != null) 'category': category,
      if (price != null) 'price': price,
    },
  );
  static Future<void> addToWishlist(String itemId) =>
      log('add_to_wishlist', params: {'item_id': itemId});

  // ────────────────────────────────
  // 🧾 SELLER / LISTING EVENTS
  // ────────────────────────────────
  static Future<void> initiateListing() => log('initiate_listing');
  static Future<void> addListingPhoto() => log('add_listing_photo');
  static Future<void> publishListing({
    required String category,
    String? itemId,
    double? price,
  }) => log(
    'publish_listing',
    params: {
      'category': category,
      if (itemId != null) 'item_id': itemId,
      if (price != null) 'price': price,
    },
  );
  static Future<void> editListing(String itemId) =>
      log('edit_listing', params: {'item_id': itemId});
  static Future<void> deleteListing(String itemId) =>
      log('delete_listing', params: {'item_id': itemId});

  // ────────────────────────────────
  // 💰 BUYER / TRANSACTION EVENTS
  // ────────────────────────────────
  static Future<void> addToCart({
    required String itemId,
    required double price,
    String currency = 'INR',
  }) => log(
    'add_to_cart',
    params: {'item_id': itemId, 'price': price, 'currency': currency},
  );
  static Future<void> initiateCheckout({
    required double totalValue,
    String currency = 'INR',
  }) => log(
    'initiate_checkout',
    params: {'value': totalValue, 'currency': currency},
  );
  static Future<void> purchase({
    required String itemId,
    required double price,
    String currency = 'INR',
  }) => log(
    'purchase',
    params: {'item_id': itemId, 'value': price, 'currency': currency},
  );
  static Future<void> paymentFailed({String? reason}) =>
      log('payment_failed', params: {'reason': reason ?? 'unknown'});

  // ────────────────────────────────
  // 💬 USER ENGAGEMENT EVENTS
  // ────────────────────────────────
  static Future<void> messageSeller(String itemId) =>
      log('message_seller', params: {'item_id': itemId});
  static Future<void> callSeller(String itemId) =>
      log('call_seller', params: {'item_id': itemId});
  static Future<void> shareItem(String itemId) =>
      log('share', params: {'item_id': itemId});
  static Future<void> reportListing(String itemId, {String? reason}) => log(
    'report_listing',
    params: {'item_id': itemId, if (reason != null) 'reason': reason},
  );

  // ────────────────────────────────
  // 🌟 RETENTION / MONETIZATION EVENTS
  // ────────────────────────────────
  static Future<void> subscribePremium({
    required String plan,
    required String price,
    String currency = 'INR',
  }) => log(
    'subscribe_premium',
    params: {'plan': plan, 'value': price, 'currency': currency},
  );
  static Future<void> adClick(String adType) =>
      log('ad_click', params: {'ad_type': adType});
  static Future<void> sessionDuration(int seconds) =>
      log('session_duration', params: {'seconds': seconds});
}
