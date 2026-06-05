class MarkAsListingModel {
  bool? success;
  String? message;
  Data? data;
  String? error;

  MarkAsListingModel({this.success, this.message, this.data});

  MarkAsListingModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    error = json['error'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    data['error'] = this.error;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? id;
  bool? sold;

  Data({this.id, this.sold});

  Data.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    sold = json['sold'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['sold'] = this.sold;
    return data;
  }
}
