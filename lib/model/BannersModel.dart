class BannersModel {
  bool? success;
  String? message;
  List<Data>? data;

  BannersModel({this.success, this.message, this.data});

  BannersModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
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
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? id;
  String? title;
  String? description;
  String? image;
  String? linkUrl;

  Data({this.id, this.title, this.description, this.image, this.linkUrl});

  Data.fromJson(Map<String, dynamic> json) {
    id = (json['_id'] ?? json['id'])?.toString();
    title = json['title'];
    description = json['description'];
    image = json['image'];
    linkUrl = json['link_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['image'] = this.image;
    data['link_url'] = this.linkUrl;
    return data;
  }
}
