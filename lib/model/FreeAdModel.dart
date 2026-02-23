class FreeAdModel {
  final bool success;
  final FreeAdData? data;

  FreeAdModel({required this.success, this.data});

  factory FreeAdModel.fromJson(Map<String, dynamic> json) {
    return FreeAdModel(
      success: json['success'] ?? false,
      data: json['data'] != null ? FreeAdData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data?.toJson()};
  }
}

class FreeAdData {
  final String amount;
  final int days;
  final String status;
  final DateTime expiryDate;

  FreeAdData({
    required this.amount,
    required this.days,
    required this.status,
    required this.expiryDate,
  });

  factory FreeAdData.fromJson(Map<String, dynamic> json) {
    return FreeAdData(
      amount: json['amount'] ?? "0.00",
      days: json['days'] ?? 0,
      status: json['status'] ?? "",
      expiryDate: DateTime.parse(json['expiry_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'days': days,
      'status': status,
      'expiry_date': expiryDate.toIso8601String(),
    };
  }
}
