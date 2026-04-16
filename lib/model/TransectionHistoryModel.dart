/// Response shape for POST /app/get-payments-transactions.
/// Backend returns purchase + boost transactions via $unionWith aggregation.
/// Dead fields (id, userName, mobile, email) removed during profile cleanup —
/// the backend still sends them (leftover from an admin view in the old
/// Express codebase), but the user-facing TransactionsScreen never reads them.
class TransectionHistoryModel {
  bool? success;
  String? message;
  Data? data;
  Settings? settings;

  TransectionHistoryModel({this.success, this.message, this.data, this.settings});

  TransectionHistoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    settings = json['settings'] != null ? Settings.fromJson(json['settings']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (settings != null) {
      data['settings'] = settings!.toJson();
    }
    return data;
  }
}

class Data {
  int? totalPayments;
  int? totalSuccess;
  List<FormattedRows>? formattedRows;

  Data({this.totalPayments, this.totalSuccess, this.formattedRows});

  Data.fromJson(Map<String, dynamic> json) {
    totalPayments = json['total_payments'];
    totalSuccess = json['total_success'];
    if (json['formattedRows'] != null) {
      formattedRows = <FormattedRows>[];
      json['formattedRows'].forEach((v) {
        formattedRows!.add(FormattedRows.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_payments'] = totalPayments;
    data['total_success'] = totalSuccess;
    if (formattedRows != null) {
      data['formattedRows'] = formattedRows!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// One transaction row — package purchase or listing boost.
/// Only fields rendered by TransactionsScreen are kept.
class FormattedRows {
  String? type;           // 'package' | 'boost' — branch label for the row
  String? listingTitle;   // displayed when type == 'boost'
  String? planName;       // displayed when type == 'package'
  String? packageName;    // displayed when type == 'package'
  String? amountPaid;     // string, 2 decimal places
  String? paymentStatus;  // 'success' | 'failed' | 'pending'
  String? paidOn;         // ISO date string
  String? startDate;      // nullable, only for package type
  String? endDate;        // nullable, only for package type

  FormattedRows({
    this.type,
    this.listingTitle,
    this.planName,
    this.packageName,
    this.amountPaid,
    this.paymentStatus,
    this.paidOn,
    this.startDate,
    this.endDate,
  });

  FormattedRows.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    listingTitle = json['listing_title'];
    planName = json['plan_name'];
    packageName = json['package_name'];
    amountPaid = json['amount_paid'];
    paymentStatus = json['payment_status'];
    paidOn = json['paid_on'];
    startDate = json['start_date'];
    endDate = json['end_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['listing_title'] = listingTitle;
    data['plan_name'] = planName;
    data['package_name'] = packageName;
    data['amount_paid'] = amountPaid;
    data['payment_status'] = paymentStatus;
    data['paid_on'] = paidOn;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    return data;
  }
}

class Settings {
  int? status;
  int? count;
  int? page;
  int? rowsPerPage;
  int? totalPages;
  bool? nextPage;
  bool? prevPage;

  Settings({
    this.status,
    this.count,
    this.page,
    this.rowsPerPage,
    this.totalPages,
    this.nextPage,
    this.prevPage,
  });

  Settings.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    count = json['count'];
    page = json['page'];
    rowsPerPage = json['rows_per_page'];
    totalPages = json['total_pages'];
    nextPage = json['next_page'];
    prevPage = json['prev_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['count'] = count;
    data['page'] = page;
    data['rows_per_page'] = rowsPerPage;
    data['total_pages'] = totalPages;
    data['next_page'] = nextPage;
    data['prev_page'] = prevPage;
    return data;
  }
}
