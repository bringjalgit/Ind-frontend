// lib/models/plan_model.dart
class PlanModel {
  final String productId;
  final String title;
  final String description;
  final int durationDays; // duration in days
  final int adsCount; // number of ads user can post

  PlanModel({
    required this.productId,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.adsCount,
  });
}

