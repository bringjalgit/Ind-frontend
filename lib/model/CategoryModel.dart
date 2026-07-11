class CategoryModel {
  bool? success;
  List<CategoriesList>? categoriesList;
  String? message;

  CategoryModel({this.success, this.categoriesList, this.message});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      categoriesList = <CategoriesList>[];
      json['data'].forEach((v) {
        categoriesList!.add(new CategoriesList.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.categoriesList != null) {
      data['data'] = this.categoriesList!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class CategoriesList {
  String? categoryId;
  String? name;
  String? image;
  int? noOfCounts;

  CategoriesList({this.categoryId, this.name, this.image, this.noOfCounts});

  CategoriesList.fromJson(Map<String, dynamic> json) {
    categoryId = json['category_id']?.toString();
    name = json['name'];
    image = json['image'];
    noOfCounts = json['no_of_counts'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['category_id'] = this.categoryId;
    data['name'] = this.name;
    data['image'] = this.image;
    data['no_of_counts'] = this.noOfCounts;
    return data;
  }
}
