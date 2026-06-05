// lib/repositories/subscription_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../model/PlanModel.dart';

class SubscriptionRepository {
  Future<void> sendPurchaseToServer(Map<String, dynamic> data) async {
    // Send POST request to your backend
    final response = await http.post(
      Uri.parse("https://yourserver.com/api/purchases"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save purchase');
    }
  }
}

