class UserActivePlansModel {
  bool? success;
  bool? isFree;
  // How many free listings the user can post right now: their one-time free
  // (if unused) plus any redeemed 150-point credits. Drives the "Remaining
  // Ads" count on the free-ad plan card. Null on an older backend that doesn't
  // send it — callers fall back to 1 (the historical hardcoded value).
  int? freeAdsRemaining;
  List<Plans>? plans;
  bool? goToPlansPage;
  // Drives the "Subscribed User" badge. TRUE whenever the user has an active,
  // successfully-paid purchase — independent of `plans` (which the backend
  // filters to remaining>0). Null when talking to an older backend that
  // doesn't send the field; callers fall back to plans-non-empty in that case.
  bool? hasActiveSubscription;

  UserActivePlansModel(
      {this.success,
      this.isFree,
      this.freeAdsRemaining,
      this.plans,
      this.goToPlansPage,
      this.hasActiveSubscription});

  UserActivePlansModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    isFree = json['is_free'];
    freeAdsRemaining = json['free_ads_remaining'];
    if (json['plans'] != null) {
      plans = <Plans>[];
      json['plans'].forEach((v) {
        plans!.add(new Plans.fromJson(v));
      });
    }
    goToPlansPage = json['go_to_plans_page'];
    hasActiveSubscription = json['has_active_subscription'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['is_free'] = this.isFree;
    data['free_ads_remaining'] = this.freeAdsRemaining;
    if (this.plans != null) {
      data['plans'] = this.plans!.map((v) => v.toJson()).toList();
    }
    data['go_to_plans_page'] = this.goToPlansPage;
    data['has_active_subscription'] = this.hasActiveSubscription;
    return data;
  }
}

class Plans {
  String? planId;
  String? packageId;
  String? planName;
  String? packageName;
  int? remaining;
  String? startDate;
  String? endDate;

  Plans(
      {this.planId,
        this.packageId,
        this.planName,
        this.packageName,
        this.remaining,
        this.startDate,
        this.endDate});

  Plans.fromJson(Map<String, dynamic> json) {
    planId = json['plan_id']?.toString();
    packageId = json['package_id']?.toString();
    planName = json['plan_name'];
    packageName = json['package_name'];
    remaining = json['remaining'];
    startDate = json['start_date'];
    endDate = json['end_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['plan_id'] = this.planId;
    data['package_id'] = this.packageId;
    data['plan_name'] = this.planName;
    data['package_name'] = this.packageName;
    data['remaining'] = this.remaining;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    return data;
  }
}
