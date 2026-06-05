class UserActivePlansModel {
  bool? success;
  bool? isFree;
  List<Plans>? plans;
  bool? goToPlansPage;

  UserActivePlansModel(
      {this.success, this.isFree, this.plans, this.goToPlansPage});

  UserActivePlansModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    isFree = json['is_free'];
    if (json['plans'] != null) {
      plans = <Plans>[];
      json['plans'].forEach((v) {
        plans!.add(new Plans.fromJson(v));
      });
    }
    goToPlansPage = json['go_to_plans_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['is_free'] = this.isFree;
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
