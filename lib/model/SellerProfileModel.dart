class SellerProfileModel {
  final SellerInfo? seller;
  final SellerCounts? counts;
  final List<SellerListing> listings;
  final bool isOwner;

  SellerProfileModel({
    this.seller,
    this.counts,
    this.listings = const [],
    this.isOwner = false,
  });

  factory SellerProfileModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return SellerProfileModel(
      seller: data['seller'] != null
          ? SellerInfo.fromJson(data['seller'] as Map<String, dynamic>)
          : null,
      counts: data['counts'] != null
          ? SellerCounts.fromJson(data['counts'] as Map<String, dynamic>)
          : null,
      listings: (data['listings'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SellerListing.fromJson)
          .toList(),
      isOwner: data['is_owner'] == true,
    );
  }
}

class SellerInfo {
  final String? id;
  final String? name;
  final String? image;
  final String? stateName;
  final String? cityName;
  final bool isVerified;
  final bool aadhaarVerified;
  final String? sellerCompanyName;
  final String? bio;
  final String? memberSince;

  SellerInfo({
    this.id,
    this.name,
    this.image,
    this.stateName,
    this.cityName,
    this.isVerified = false,
    this.aadhaarVerified = false,
    this.sellerCompanyName,
    this.bio,
    this.memberSince,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> j) => SellerInfo(
        id: j['id']?.toString(),
        name: j['name'] as String?,
        image: j['image'] as String?,
        stateName: j['state_name'] as String?,
        cityName: j['city_name'] as String?,
        isVerified: j['is_verified'] == true,
        aadhaarVerified: j['aadhaar_verified'] == true,
        sellerCompanyName: j['seller_company_name'] as String?,
        bio: j['bio'] as String?,
        memberSince: j['member_since'] as String?,
      );
}

class SellerCounts {
  final int active;
  final int sold;
  final int expired;
  final int total;

  SellerCounts({
    this.active = 0,
    this.sold = 0,
    this.expired = 0,
    this.total = 0,
  });

  factory SellerCounts.fromJson(Map<String, dynamic> j) => SellerCounts(
        active: (j['active'] as num?)?.toInt() ?? 0,
        sold: (j['sold'] as num?)?.toInt() ?? 0,
        expired: (j['expired'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

class SellerListing {
  final String? id;
  final String? title;
  final num? price;
  final String? image;
  final String? status;
  final bool sold;
  final bool isExpired;
  final String? location;
  final String? subCategoryId;
  final String? postedAt;

  SellerListing({
    this.id,
    this.title,
    this.price,
    this.image,
    this.status,
    this.sold = false,
    this.isExpired = false,
    this.location,
    this.subCategoryId,
    this.postedAt,
  });

  factory SellerListing.fromJson(Map<String, dynamic> j) => SellerListing(
        id: j['id']?.toString(),
        title: j['title'] as String?,
        price: j['price'] as num?,
        image: j['image'] as String?,
        status: j['status'] as String?,
        sold: j['sold'] == true,
        isExpired: j['is_expired'] == true,
        location: j['location'] as String?,
        subCategoryId: j['sub_category_id']?.toString(),
        postedAt: j['posted_at'] as String?,
      );
}
