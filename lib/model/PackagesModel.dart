class PackagesModel {
  bool? success;
  String? message;
  Plan? plan;
  List<Data>? data;

  PackagesModel({this.success, this.message, this.plan, this.data});

  PackagesModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    plan = json['plan'] != null ? new Plan.fromJson(json['plan']) : null;
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.plan != null) {
      data['plan'] = this.plan!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Plan {
  String? name;
  int? durationDays;

  Plan({this.name, this.durationDays});

  Plan.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    durationDays = json['duration_days'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['duration_days'] = this.durationDays;
    return data;
  }
}

class Data {
  String? id;
  String? planId;
  String? name;
  int? listingsCount;
  int? adsCount;
  int? pinnedCount;
  int? spotlightCount;
  String? price;
  String? normalPrice;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? durationDays;

  Data(
      {this.id,
        this.planId,
        this.name,
        this.listingsCount,
        this.adsCount,
        this.pinnedCount,
        this.spotlightCount,
        this.price,
        this.normalPrice,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.durationDays});

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  Data.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    planId = json['plan_id']?.toString();
    name = json['name'];
    listingsCount = _parseInt(json['listings_count']);
    adsCount = _parseInt(json['ads_count']);
    pinnedCount = _parseInt(json['pinned_count']);
    spotlightCount = _parseInt(json['spotlight_count']);
    price = json['price']?.toString();
    normalPrice = json['normal_price']?.toString();
    status = json['status'];
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    durationDays = _parseInt(json['duration_days']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['plan_id'] = this.planId;
    data['name'] = this.name;
    data['listings_count'] = this.listingsCount;
    data['ads_count'] = this.adsCount;
    data['pinned_count'] = this.pinnedCount;
    data['spotlight_count'] = this.spotlightCount;
    data['price'] = this.price;
    data['normal_price'] = this.normalPrice;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['duration_days'] = this.durationDays;
    return data;
  }
}
