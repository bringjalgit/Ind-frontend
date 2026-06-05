class getListingAdModel {
  bool? success;
  String? message;
  Data? data;

  getListingAdModel({this.success, this.message, this.data});

  getListingAdModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Listing? listing;

  Data({this.listing});

  Data.fromJson(Map<String, dynamic> json) {
    listing = json['listing'] != null
        ? new Listing.fromJson(json['listing'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.listing != null) {
      data['listing'] = this.listing!.toJson();
    }
    return data;
  }
}

class Listing {
  String? id;
  String? title;
  String? description;
  String? categoryId;
  String? price;
  String? location;
  String? fullName;
  String? mobileNumber;
  String? brand;
  String? breedType;
  String? vechileNumber;
  String? areaSize;
  String? rentalDuration;
  int? floorNo;
  String? listedBy;
  String? furnishingStatus;
  String? projectStatus;
  String? facingDirection;
  int? noOfParking;
  String? bhkType;
  int? noOfBathRooms;
  int? roomNo;
  String? age;
  String? storage;
  String? ram;
  String? salaryRange;
  String? instuteName;
  String? seatType;
  int? deskCapacity;
  int? availableSeats;
  int? stateId;
  String? playerSlots;
  String? stateName;
  String? cityName;
  int? cityId;
  int? yearOfManufacturing;
  int? kmsRun;
  String? ownership;
  String? transmission;
  String? fuelType;
  String? createdAt;
  List<Images>? images;
  String? languagesSpoken;
  String? locationKey;
  String? currentAddress;
  String? currentAddressKey;
  // Category-level SWA gate. False for Find Investor / Events / Films /
  // Community. ProductDetailsScreen reads this to hide the SWAEnableCard
  // for non-tradable categories. Defaults true so older responses
  // without the field keep the existing behaviour.
  bool swaCategoryEligible = true;

  Listing({
    this.id,
    this.title,
    this.description,
    this.categoryId,
    this.price,
    this.location,
    this.fullName,
    this.mobileNumber,
    this.brand,
    this.vechileNumber,
    this.rentalDuration,
    this.floorNo,
    this.listedBy,
    this.projectStatus,
    this.furnishingStatus,
    this.facingDirection,
    this.noOfParking,
    this.bhkType,
    this.noOfBathRooms,
    this.roomNo,
    this.breedType,
    this.age,
    this.storage,
    this.ram,
    this.salaryRange,
    this.instuteName,
    this.seatType,
    this.deskCapacity,
    this.availableSeats,
    this.areaSize,
    this.playerSlots,
    this.stateId,
    this.stateName,
    this.cityName,
    this.cityId,
    this.yearOfManufacturing,
    this.languagesSpoken,
    this.kmsRun,
    this.ownership,
    this.transmission,
    this.fuelType,
    this.createdAt,
    this.images,
    this.locationKey,
    this.currentAddress,
    this.currentAddressKey,
  });

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  Listing.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    title = json['title'];
    description = json['description'];
    categoryId = json['category_id']?.toString();
    price = json['price']?.toString();
    location = json['location'];
    fullName = json['full_name'];
    mobileNumber = json['mobile_number'];
    stateId = _parseInt(json['state_id']);
    stateName = json['state_name'];
    cityName = json['city_name'];
    vechileNumber = json['vehicle_number'];
    cityId = _parseInt(json['city_id']);
    languagesSpoken = json['languages_spoken'];
    brand = json['brand'];
    yearOfManufacturing = _parseInt(json['year_of_manufacturing']);
    kmsRun = _parseInt(json['kms_run']);
    ownership = json['ownership'];
    breedType = json['pet_type'];
    rentalDuration = json['rental_duration'];
    floorNo = _parseInt(json['floor_number']);
    listedBy = json['listed_by'];
    projectStatus = json['project_status'];
    facingDirection = json['facing_direction'];
    furnishingStatus = json['furnishing_status'];
    noOfParking = _parseInt(json['no_of_carparking_spaces']);
    bhkType = json['bhk_type'];
    noOfBathRooms = _parseInt(json['no_of_bathrooms']);
    roomNo = _parseInt(json['room_no']);
    age = json['age'];
    storage = json['storage'];
    ram = json['ram'];
    salaryRange = json['salary_range'];
    instuteName = json['institute_name'];
    availableSeats = _parseInt(json['available_seats']);
    seatType = json['seat_type'];
    deskCapacity = _parseInt(json['desk_capacity']);
    areaSize = json['area_size'];
    playerSlots = json['player_slots'];
    transmission = json['transmission'];
    fuelType = json['fuel_type'];
    createdAt = json['created_at'];
    locationKey = json['location_key'];
    currentAddress = json['current_address'];
    currentAddressKey = json['current_address_key'];
    // Default true so older responses without the field keep the
    // current SWA behaviour intact; backend sets false only for the
    // four blocked categories.
    swaCategoryEligible = json['swa_category_eligible'] != false;
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(new Images.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['category_id'] = this.categoryId;
    data['price'] = this.price;
    data['location'] = this.location;
    data['full_name'] = this.fullName;
    data['mobile_number'] = this.mobileNumber;
    data['state_id'] = this.stateId;
    data['city_id'] = this.cityId;
    data['year_of_manufacturing'] = this.yearOfManufacturing;
    data['languages_spoken'] = this.languagesSpoken;
    data['brand'] = this.brand;
    data['vehicle_number'] = this.vechileNumber;
    data['rental_duration'] = this.rentalDuration;
    data['floor_number'] = this.floorNo;
    data['listed_by'] = this.listedBy;
    data['project_status'] = this.projectStatus;
    data['furnishing_status'] = this.furnishingStatus;
    data['no_of_bathrooms'] = this.noOfBathRooms;
    data['no_of_carparking_spaces'] = this.noOfParking;
    data['room_no'] = this.roomNo;
    data['pet_type'] = this.breedType;
    data['age'] = this.age;
    data['storage'] = this.storage;
    data['ram'] = this.ram;
    data['salary_range'] = this.salaryRange;
    data['available_seats'] = this.availableSeats;
    data['institute_name'] = this.instuteName;
    data['area_size'] = this.areaSize;
    data['seat_type'] = this.seatType;
    data['player_slots'] = this.playerSlots;
    data['kms_run'] = this.kmsRun;
    data['ownership'] = this.ownership;
    data['transmission'] = this.transmission;
    data['fuel_type'] = this.fuelType;
    data['created_at'] = this.createdAt;
    data['location_key'] = this.locationKey;
    data['current_address'] = this.currentAddress;
    data['current_address_key'] = this.currentAddressKey;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Images {
  String? id;
  String? image;

  Images({this.id, this.image});

  Images.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? json['_id'])?.toString();
    image = json['image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['image'] = this.image;
    return data;
  }
}
