class CreatePaymentModel {
  bool? success;
  String? message;
  String? orderId;
  int? amount;
  String? currency;
  String? razorpayKey;

  CreatePaymentModel(
      {this.success,
        this.message,
        this.orderId,
        this.amount,
        this.currency,
        this.razorpayKey});

  CreatePaymentModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    orderId = json['orderId'];
    amount = json['amount'];
    currency = json['currency'];
    razorpayKey = json['razorpay_key'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    data['orderId'] = this.orderId;
    data['amount'] = this.amount;
    data['currency'] = this.currency;
    data['razorpay_key'] = this.razorpayKey;
    return data;
  }
}
