/// Wire model for the P2P offer recommendation card shown inside
/// [P2POfferSheet]. Backed by `GET /app/get-offer-recommendation/:id`
/// (see handler/listing/offer.js). All numeric fields arrive as JSON
/// numbers but we parse defensively because legacy Mongo IDs and
/// older clients have surfaced strings in adjacent endpoints.
class OfferRecommendationModel {
  final bool success;
  final OfferRecommendation? data;

  OfferRecommendationModel({required this.success, this.data});

  factory OfferRecommendationModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return OfferRecommendationModel(
      success: json['success'] == true,
      data: raw is Map<String, dynamic> ? OfferRecommendation.fromJson(raw) : null,
    );
  }
}

class OfferRecommendation {
  /// Recommended single number — what the AI suggests the buyer offer.
  final int recommended;

  /// Lower bound of the suggested band — drives the "−10%" quick chip.
  final int lowBound;

  /// Upper bound of the suggested band — drives the "−3%" quick chip.
  final int highBound;

  /// The listed price the recommendation is computed against.
  /// Echoed back so the sheet doesn't have to re-look-it-up.
  final int listedPrice;

  /// Median discount percentage applied for this category.
  final int discountPct;

  /// Display name of the listing's category — surfaced in [reasonShort].
  final String categoryName;

  /// One-line human-readable reason rendered under the recommendation
  /// number. Templated server-side, not LLM-generated.
  final String reasonShort;

  OfferRecommendation({
    required this.recommended,
    required this.lowBound,
    required this.highBound,
    required this.listedPrice,
    required this.discountPct,
    required this.categoryName,
    required this.reasonShort,
  });

  factory OfferRecommendation.fromJson(Map<String, dynamic> json) {
    return OfferRecommendation(
      recommended: _toInt(json['recommended']),
      lowBound: _toInt(json['lowBound']),
      highBound: _toInt(json['highBound']),
      listedPrice: _toInt(json['listedPrice']),
      discountPct: _toInt(json['discountPct']),
      categoryName: (json['categoryName'] ?? '').toString(),
      reasonShort: (json['reasonShort'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
