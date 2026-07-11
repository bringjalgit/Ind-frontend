class MyAdsModel {
  bool? success;
  String? message;
  List<Data>? data;
  Settings? settings;

  MyAdsModel({this.success, this.message, this.data, this.settings});

  MyAdsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    settings = json['settings'] != null
        ? new Settings.fromJson(json['settings'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.settings != null) {
      data['settings'] = this.settings!.toJson();
    }
    return data;
  }
}

class Data {
  String? id;
  String? title;
  String? description;
  String? price;
  String? location;
  String? categoryId;
  String? subCategoryId;
  bool? featuredStatus;
  String? status;
  bool? sold;
  // ISO timestamp of when the listing was marked sold (null if unsold or sold
  // before the backend started recording it). Drives the "Sold on <date>" line
  // on the My Ads card in place of the posted-ago time.
  String? soldAt;
  String? createdAt;
  State? state;
  State? city;
  Category? category;
  State? subCategory;
  String? postedAt;
  int? totalLikes;
  String? image;

  // Smart Assist (Sell-with-AI) flags surfaced by the backend so the
  // My Ads card can render the active / try-it strip without another
  // round-trip. `swaActive` comes directly from
  // sell_with_ai_config.is_active; `swaEligible` is derived client-side
  // (approved + not sold) — the wizard-entry strip only shows for
  // listings that CAN be activated.
  bool swaActive = false;
  String? swaExpiresAt;
  // True when this listing has been activated at SWA at least once
  // before (server-side check: stored `expected_price > 0`). Drives the
  // listing-card SWA strip: when SWA is off but the seller has already
  // configured it once, the strip flips to "Smart Assist Deactivated —
  // Tap to activate" with a one-tap reactivate using the stored config.
  // For listings that were never activated this stays false and the
  // strip remains the first-time "Try Smart Assist" wizard opener.
  bool swaPreviouslyActivated = false;
  // Category-level SWA gate. False for Find Investor / Events / Films /
  // Community — those listings aren't tradable goods so SWA doesn't
  // make sense. ANDed into `swaEligible` so every SWA chrome (Try /
  // Deactivated strips, wizard entry) is hidden for these categories.
  // Defaults true so older backend responses without the field don't
  // silently kill SWA on existing eligible listings.
  bool swaCategoryEligible = true;
  // ISO timestamp for the listing's own expiry (driven by the plan/
  // package the seller purchased). Used by the SWA activation wizard to
  // cap the availability_window picker — offering 60 / 90 days on a
  // 30-day listing is pointless because SWA can't outlive its listing.
  String? expiresListDate;
  /// Plan tier code stamped on this listing's purchase
  /// (`"essential"` / `"power"` / `"pro"`), or null on free posts.
  /// Drives the listing card's tier badge in the corner.
  String? planTier;

  bool get swaEligible =>
      (status ?? '').toLowerCase() == 'approved' &&
      sold != true &&
      swaCategoryEligible;

  Data(
      {this.id,
        this.title,
        this.description,
        this.price,
        this.location,
        this.categoryId,
        this.subCategoryId,
        this.featuredStatus,
        this.status,
        this.sold,
        this.createdAt,
        this.state,
        this.city,
        this.category,
        this.subCategory,
        this.postedAt,
        this.totalLikes,
        this.image,
        this.swaActive = false,
        this.swaExpiresAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    title = json['title'];
    description = json['description'];
    price = json['price']?.toString();
    location = json['location'];
    // Lambda list returns nested objects, not top-level IDs — extract from them
    categoryId = (json['category']?['_id'] ?? json['category_id'])?.toString();
    subCategoryId = (json['sub_category']?['_id'] ?? json['sub_category_id'])?.toString();
    featuredStatus = json['featured_status'];
    status = json['status'];
    sold = json['sold'];
    soldAt = json['sold_at']?.toString();
    createdAt = json['created_at'];
    // Lambda returns flat state_name/city_name strings
    state = json['state_name'] != null ? State(name: json['state_name']) : null;
    city = json['city_name'] != null ? State(name: json['city_name']) : null;
    // Lambda returns lowercase 'category' and 'sub_category' keys
    category = json['category'] != null
        ? new Category.fromJson(json['category'])
        : null;
    subCategory = json['sub_category'] != null
        ? new State.fromJson(json['sub_category'])
        : null;
    postedAt = json['posted_at'];
    totalLikes = json['total_likes'];
    image = json['image'];
    swaActive = json['swa_active'] == true;
    swaExpiresAt = json['swa_expires_at']?.toString();
    swaPreviouslyActivated = json['swa_previously_activated'] == true;
    // Default true — older responses without this field don't get
    // their SWA chrome silently nuked. Backend explicitly sets false
    // for the four blocked categories.
    swaCategoryEligible = json['swa_category_eligible'] != false;
    expiresListDate = json['expires_list_date']?.toString();
    planTier = json['plan_tier']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['price'] = this.price;
    data['location'] = this.location;
    data['category_id'] = this.categoryId;
    data['sub_category_id'] = this.subCategoryId;
    data['featured_status'] = this.featuredStatus;
    data['status'] = this.status;
    data['sold'] = this.sold;
    data['sold_at'] = this.soldAt;
    data['created_at'] = this.createdAt;
    if (this.state != null) {
      data['state'] = this.state!.toJson();
    }
    if (this.city != null) {
      data['city'] = this.city!.toJson();
    }
    if (this.category != null) {
      data['Category'] = this.category!.toJson();
    }
    if (this.subCategory != null) {
      data['SubCategory'] = this.subCategory!.toJson();
    }
    data['posted_at'] = this.postedAt;
    data['total_likes'] = this.totalLikes;
    data['image'] = this.image;
    return data;
  }
}

class State {
  String? id;
  String? name;

  State({this.id, this.name});

  State.fromJson(Map<String, dynamic> json) {
    id = (json['_id'] ?? json['id'])?.toString();
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}

class Category {
  String? id;
  String? name;
  String? path;

  Category({this.id, this.name, this.path});

  Category.fromJson(Map<String, dynamic> json) {
    id = (json['_id'] ?? json['id'])?.toString();
    name = json['name'];
    path = json['path'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['path'] = this.path;
    return data;
  }
}

class Settings {
  int? status;
  int? count;
  int? page;
  int? rowsPerPage;
  bool? nextPage;
  bool? prevPage;

  Settings(
      {this.status,
        this.count,
        this.page,
        this.rowsPerPage,
        this.nextPage,
        this.prevPage});

  Settings.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    count = json['count'];
    page = json['page'];
    rowsPerPage = json['rows_per_page'];
    nextPage = json['next_page'];
    prevPage = json['prev_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['count'] = this.count;
    data['page'] = this.page;
    data['rows_per_page'] = this.rowsPerPage;
    data['next_page'] = this.nextPage;
    data['prev_page'] = this.prevPage;
    return data;
  }
}
