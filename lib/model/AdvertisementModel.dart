class AdvertisementModel {
  bool? success;
  String? message;
  int? status;
  List<Data>? data;
  Settings? settings;

  AdvertisementModel(
      {this.success, this.message, this.status, this.data, this.settings});

  AdvertisementModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    status = json['status'];
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
    data['status'] = this.status;
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
  String? userId;
  String? name;
  String? image;
  String? link;
  String? status;
  String? planId;
  String? packageId;
  String? createdAt;
  String? updatedAt;
  Plan? plan;
  PlansPackage? plansPackage;

  Data(
      {this.id,
        this.userId,
        this.name,
        this.image,
        this.link,
        this.status,
        this.planId,
        this.packageId,
        this.createdAt,
        this.updatedAt,
        this.plan,
        this.plansPackage});

  Data.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    userId = json['user_id']?.toString();
    name = json['name'];
    image = json['image'];
    link = json['link'];
    status = json['status'];
    planId = json['plan_id']?.toString();
    packageId = json['package_id']?.toString();
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    plan = json['Plan'] != null
        ? new Plan.fromJson(json['Plan'])
        : (json['plan_name'] != null ? Plan(name: json['plan_name']) : null);
    plansPackage = json['PlansPackage'] != null
        ? new PlansPackage.fromJson(json['PlansPackage'])
        : (json['package_name'] != null
            ? PlansPackage(name: json['package_name'], adsCount: json['ads_count'])
            : null);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['name'] = this.name;
    data['image'] = this.image;
    data['link'] = this.link;
    data['status'] = this.status;
    data['plan_id'] = this.planId;
    data['package_id'] = this.packageId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.plan != null) {
      data['Plan'] = this.plan!.toJson();
    }
    if (this.plansPackage != null) {
      data['PlansPackage'] = this.plansPackage!.toJson();
    }
    return data;
  }
}

class Plan {
  String? id;
  String? name;

  Plan({this.id, this.name});

  Plan.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}

class PlansPackage {
  String? id;
  String? name;
  int? adsCount;

  PlansPackage({this.id, this.name, this.adsCount});

  PlansPackage.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    name = json['name'];
    adsCount = json['ads_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['ads_count'] = this.adsCount;
    return data;
  }
}

class Settings {
  int? count;
  int? page;
  int? rowsPerPage;
  int? totalPages;
  bool? nextPage;
  bool? prevPage;

  Settings(
      {this.count,
        this.page,
        this.rowsPerPage,
        this.totalPages,
        this.nextPage,
        this.prevPage});

  Settings.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    page = json['page'];
    rowsPerPage = json['rows_per_page'];
    totalPages = json['total_pages'];
    nextPage = json['next_page'];
    prevPage = json['prev_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['count'] = this.count;
    data['page'] = this.page;
    data['rows_per_page'] = this.rowsPerPage;
    data['total_pages'] = this.totalPages;
    data['next_page'] = this.nextPage;
    data['prev_page'] = this.prevPage;
    return data;
  }
}
