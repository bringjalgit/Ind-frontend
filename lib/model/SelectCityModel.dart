class SelectCityModel {
  bool? success;
  String? message;
  int? status;
  List<CityData>? data;
  Settings? settings;

  SelectCityModel({
    this.success,
    this.message,
    this.status,
    this.data,
    this.settings,
  });

  SelectCityModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    status = json['status'];

    if (json['data'] != null) {
      data = <CityData>[];
      json['data'].forEach((v) {
        data!.add(CityData.fromJson(v));
      });
    }

    settings =
    json['settings'] != null ? Settings.fromJson(json['settings']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['success'] = success;
    map['message'] = message;
    map['status'] = status;

    if (data != null) {
      map['data'] = data!.map((v) => v.toJson()).toList();
    }

    if (settings != null) {
      map['settings'] = settings!.toJson();
    }

    return map;
  }
}

class CityData {
  int? id;
  String? name;

  CityData({this.id, this.name});

  CityData.fromJson(Map<String, dynamic> json) {
    id = json['city_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['city_id'] = id;
    map['name'] = name;
    return map;
  }
}

class Settings {
  int? count;
  int? page;
  int? rowsPerPage;
  int? totalPages;
  bool? nextPage;
  bool? prevPage;

  Settings({
    this.count,
    this.page,
    this.rowsPerPage,
    this.totalPages,
    this.nextPage,
    this.prevPage,
  });

  Settings.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    page = json['page'];
    rowsPerPage = json['rows_per_page'];
    totalPages = json['total_pages'];
    nextPage = json['next_page'];
    prevPage = json['prev_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['count'] = count;
    map['page'] = page;
    map['rows_per_page'] = rowsPerPage;
    map['total_pages'] = totalPages;
    map['next_page'] = nextPage;
    map['prev_page'] = prevPage;
    return map;
  }
}
