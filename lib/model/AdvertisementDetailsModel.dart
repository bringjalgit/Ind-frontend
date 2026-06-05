class AdvertisementDetailsModel {
  bool? success;
  List<Plans>? plans;
  bool? goToPlansPage;

  AdvertisementDetailsModel({this.success, this.plans, this.goToPlansPage});

  AdvertisementDetailsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    final list = json['data'] ?? json['plans'];
    if (list != null) {
      plans = <Plans>[];
      list.forEach((v) {
        plans!.add(new Plans.fromJson(v));
      });
    }
    goToPlansPage = json['go_to_plans_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.plans != null) {
      data['plans'] = this.plans!.map((v) => v.toJson()).toList();
    }
    data['go_to_plans_page'] = this.goToPlansPage;
    return data;
  }
}

class Plans {
  String? planId;
  String? packageId;
  String? planName;
  String? packageName;
  int? used;
  int? remaining;
  String? startDate;
  String? endDate;

  Plans(
      {this.planId,
        this.packageId,
        this.planName,
        this.packageName,
        this.used,
        this.remaining,
        this.startDate,
        this.endDate});

  Plans.fromJson(Map<String, dynamic> json) {
    planId = json['plan_id']?.toString();
    packageId = json['package_id']?.toString();
    planName = json['plan_name'];
    packageName = json['package_name'];
    used = json['used'];
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
    data['used'] = this.used;
    data['remaining'] = this.remaining;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    return data;
  }
}
