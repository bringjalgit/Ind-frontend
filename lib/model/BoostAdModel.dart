class BoostAdModel {
  bool? success;
  String? message;
  Data? data;

  BoostAdModel({this.success, this.message, this.data});

  BoostAdModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? amount;
  String? description;
  String? name;
  String? id;
  int? days;
  String? status;

  Data({this.amount, this.description, this.name, this.id, this.days, this.status});

  Data.fromJson(Map<String, dynamic> json) {
    amount = json['amount']?.toString();
    description = json['description']?.toString();
    name = json['name']?.toString();
    id = (json['id'] ?? json['_id'])?.toString();
    days = json['days'] is int ? json['days'] : int.tryParse(json['days']?.toString() ?? '');
    status = json['status']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount'] = this.amount;
    data['description'] = this.description;
    data['name'] = this.name;
    data['id'] = this.id;
    data['days'] = this.days;
    data['status'] = this.status;
    return data;
  }
}
