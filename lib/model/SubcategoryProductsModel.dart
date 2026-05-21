class SubcategoryProductsModel {
  bool? success;
  String? message;
  List<Products>? products;
  Settings? settings;
  LocationMeta? locationMeta;

  SubcategoryProductsModel({
    this.success,
    this.message,
    this.products,
    this.settings,
    this.locationMeta,
  });

  SubcategoryProductsModel copyWith({
    bool? success,
    String? message,
    List<Products>? products,
    Settings? settings,
    LocationMeta? locationMeta,
  }) {
    return SubcategoryProductsModel(
      success: success ?? this.success,
      message: message ?? this.message,
      products: products ?? this.products,
      settings: settings ?? this.settings,
      locationMeta: locationMeta ?? this.locationMeta,
    );
  }

  SubcategoryProductsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      products = <Products>[];
      json['data'].forEach((v) {
        products!.add(Products.fromJson(v));
      });
    }
    settings = json['settings'] != null
        ? Settings.fromJson(json['settings'])
        : null;
    locationMeta = json['location_meta'] != null
        ? LocationMeta.fromJson(json['location_meta'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['success'] = success;
    data['message'] = message;
    if (products != null) {
      data['data'] = products!.map((v) => v.toJson()).toList();
    }
    if (settings != null) {
      data['settings'] = settings!.toJson();
    }
    if (locationMeta != null) {
      data['location_meta'] = locationMeta!.toJson();
    }
    return data;
  }
}

class LocationMeta {
  bool? radiusApplied;
  int? radiusKm;
  bool? fellBackToNationwide;

  LocationMeta({this.radiusApplied, this.radiusKm, this.fellBackToNationwide});

  LocationMeta.fromJson(Map<String, dynamic> json) {
    radiusApplied = json['radius_applied'];
    radiusKm = json['radius_km'];
    fellBackToNationwide = json['fell_back_to_nationwide'];
  }

  Map<String, dynamic> toJson() => {
        'radius_applied': radiusApplied,
        'radius_km': radiusKm,
        'fell_back_to_nationwide': fellBackToNationwide,
      };
}

class Products {
  String? id;
  String? userId;
  String? title;
  String? description;
  String? price;
  String? location;
  String? fullName;
  String? image;
  String? mobileNumber;
  String? status;
  bool? sold;
  bool? featured_status;
  int? stateId;
  int? cityId;
  String? createdAt;
  Category? category;
  SubCategory? subCategory;
  SubCategory? user;
  SubCategory? state;
  SubCategory? city;
  String? postedAt;
  bool? isFavorited;
  /// Plan tier of the seller's active subscription stamped on this
  /// listing (`"essential"` / `"power"` / `"pro"`). Null on free posts.
  /// Drives the small tier badge on the listing card.
  String? planTier;

  Products({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.price,
    this.location,
    this.fullName,
    this.image,
    this.mobileNumber,
    this.status,
    this.sold,
    this.featured_status,
    this.stateId,
    this.cityId,
    this.createdAt,
    this.category,
    this.subCategory,
    this.user,
    this.state,
    this.city,
    this.postedAt,
    this.isFavorited,
    this.planTier,
  });

  Products copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? price,
    String? location,
    String? fullName,
    String? image,
    String? mobileNumber,
    String? status,
    bool? sold,
    bool? featured_status,
    int? stateId,
    int? cityId,
    String? createdAt,
    Category? category,
    SubCategory? subCategory,
    SubCategory? user,
    SubCategory? state,
    SubCategory? city,
    String? postedAt,
    bool? isFavorited,
  }) {
    return Products(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      fullName: fullName ?? this.fullName,
      image: image ?? this.image,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      status: status ?? this.status,
      sold: sold ?? this.sold,
      featured_status: featured_status ?? this.featured_status,
      stateId: stateId ?? this.stateId,
      cityId: cityId ?? this.cityId,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      user: user ?? this.user,
      state: state ?? this.state,
      city: city ?? this.city,
      postedAt: postedAt ?? this.postedAt,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  Products.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    userId = json['user_id']?.toString();
    title = json['title'];
    description = json['description'];
    price = json['price']?.toString();
    location = json['location'];
    fullName = json['full_name'];
    image = json['image'];
    mobileNumber = json['mobile_number'];
    status = json['status'];
    sold = json['sold'];
    featured_status = json['featured_status'];
    stateId = json['state_id'];
    cityId = json['city_id'];
    createdAt = json['created_at']?.toString();
    // Lambda returns lowercase keys: 'category', 'sub_category', 'user'
    final catJson = json['category'] ?? json['Category'];
    category = catJson != null ? Category.fromJson(catJson) : null;
    final subCatJson = json['sub_category'] ?? json['SubCategory'];
    subCategory = subCatJson != null ? SubCategory.fromJson(subCatJson) : null;
    final userJson = json['user'] ?? json['User'];
    user = userJson != null ? SubCategory.fromJson(userJson) : null;
    // Lambda returns flat state_name / city_name strings (not nested objects)
    final stateName = json['state_name'];
    state = stateName != null ? SubCategory(name: stateName.toString()) : null;
    final cityName = json['city_name'];
    city = cityName != null ? SubCategory(name: cityName.toString()) : null;
    postedAt = json['posted_at'];
    isFavorited = json['is_favorited'];
    planTier = json['plan_tier']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['user_id'] = userId;
    data['title'] = title;
    data['description'] = description;
    data['price'] = price;
    data['location'] = location;
    data['full_name'] = fullName;
    data['image'] = image;
    data['mobile_number'] = mobileNumber;
    data['status'] = status;
    data['sold'] = sold;
    data['featured_status'] = featured_status;
    data['state_id'] = stateId;
    data['city_id'] = cityId;
    data['created_at'] = createdAt;
    if (category != null) data['Category'] = category!.toJson();
    if (subCategory != null) data['SubCategory'] = subCategory!.toJson();
    if (user != null) data['User'] = user!.toJson();
    if (state != null) data['state'] = state!.toJson();
    if (city != null) data['city'] = city!.toJson();
    data['posted_at'] = postedAt;
    data['is_favorited'] = isFavorited;
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

class SubCategory {
  String? id;
  String? name;

  SubCategory({this.id, this.name});

  SubCategory.fromJson(Map<String, dynamic> json) {
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

class Settings {
  int? status;
  int? count;
  int? page;
  int? rowsPerPage;
  bool? nextPage;
  bool? prevPage;

  Settings({
    this.status,
    this.count,
    this.page,
    this.rowsPerPage,
    this.nextPage,
    this.prevPage,
  });

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
