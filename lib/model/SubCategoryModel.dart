class SubCategoryModel {
  bool? success;
  List<SubCategories>? subcategories;
  String? message;
  String? sub_category_banner;

  SubCategoryModel({
    this.success,
    this.subcategories,
    this.message,
    this.sub_category_banner,
  });

  SubCategoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      subcategories = <SubCategories>[];
      json['data'].forEach((v) {
        subcategories!.add(new SubCategories.fromJson(v));
      });
    }
    message = json['message'];
    sub_category_banner = json['sub_category_banner'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.subcategories != null) {
      data['data'] = this.subcategories!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    data['sub_category_banner'] = this.sub_category_banner;
    return data;
  }
}

class SubCategories {
  String? subCategoryId;
  String? name;
  String? path;
  String? image;
  String? description;
  int? noOfCounts;

  SubCategories({
    this.subCategoryId,
    this.name,
    this.image,
    this.noOfCounts,
    this.path,
    this.description,
  });

  SubCategories.fromJson(Map<String, dynamic> json) {
    subCategoryId = (json['sub_category_id'] ?? json['_id'])?.toString();
    name = json['name'];
    image = json['image'];
    path = json['path'];
    noOfCounts = json['no_of_counts'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sub_category_id'] = this.subCategoryId;
    data['name'] = this.name;
    data['image'] = this.image;
    data['path'] = this.path;
    data['no_of_counts'] = this.noOfCounts;
    data['description'] = this.description;
    return data;
  }
}
