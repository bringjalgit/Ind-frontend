class AddToWishlistModel {
  bool? success;
  bool? liked;
  String? message;

  AddToWishlistModel({this.success, this.liked, this.message});

  AddToWishlistModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    liked = json['liked'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['liked'] = this.liked;
    data['message'] = this.message;
    return data;
  }
}
