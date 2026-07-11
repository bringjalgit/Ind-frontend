// Models for the Refer & Earn feature (chat-stack referral endpoints).
// The backend returns { success, message, data: {...} }.

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? 0}') ?? 0;
}

/// GET /referral/info
class ReferralInfo {
  final bool enabled; // false when the feature is off / user not allow-listed
  final String? code;
  final String? shareLink;
  final String? shareText;
  final int referrerPoints; // what the inviter earns (10)
  final int refereePoints; // what the new user earns (5)
  final int rewardPoints; // the user's actual points wallet balance
  final int totalReferred;
  final int totalPending;
  final int totalEarned; // points already credited to the inviter (as referrer)
  // Redeem-a-free-listing state
  final int freeListingCredits; // free listings the user has banked
  final int redeemFreeListingCost; // points needed to redeem one (150)
  final bool canRedeemFreeListing; // balance >= cost and redeem enabled

  ReferralInfo({
    required this.enabled,
    this.code,
    this.shareLink,
    this.shareText,
    this.referrerPoints = 0,
    this.refereePoints = 0,
    this.rewardPoints = 0,
    this.totalReferred = 0,
    this.totalPending = 0,
    this.totalEarned = 0,
    this.freeListingCredits = 0,
    this.redeemFreeListingCost = 150,
    this.canRedeemFreeListing = false,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? const {};
    return ReferralInfo(
      enabled: d['enabled'] == true,
      code: d['referral_code']?.toString(),
      shareLink: d['share_link']?.toString(),
      shareText: d['share_text']?.toString(),
      referrerPoints: _asInt(d['referrer_points']),
      refereePoints: _asInt(d['referee_points']),
      rewardPoints: _asInt(d['reward_points']),
      totalReferred: _asInt(d['total_referred']),
      totalPending: _asInt(d['total_pending']),
      totalEarned: _asInt(d['total_earned']),
      freeListingCredits: _asInt(d['free_listing_credits']),
      redeemFreeListingCost:
          d['redeem_free_listing_cost'] == null ? 150 : _asInt(d['redeem_free_listing_cost']),
      canRedeemFreeListing: d['can_redeem_free_listing'] == true,
    );
  }
}

/// One row from GET /referral/list — a friend you referred.
class ReferredFriend {
  final String id;
  final String name; // masked, e.g. "Siddharth"
  final String status; // 'rewarded' | 'pending' | 'rejected'
  final int points; // referrer_points on that referral

  ReferredFriend({
    required this.id,
    required this.name,
    required this.status,
    required this.points,
  });

  bool get isRewarded => status == 'rewarded';
  bool get isPending => status == 'pending';

  factory ReferredFriend.fromJson(Map<String, dynamic> j) => ReferredFriend(
        id: j['id']?.toString() ?? '',
        name: (j['name']?.toString().trim().isNotEmpty ?? false)
            ? j['name'].toString()
            : 'New user',
        status: j['status']?.toString() ?? 'pending',
        points: _asInt(j['points']),
      );
}

/// POST /referral/apply result.
class ApplyReferralResult {
  final bool success;
  final String message;
  final String? code; // error code (ALREADY_APPLIED, INVALID_CODE, SELF_REFERRAL…)
  final String status; // 'pending' | 'rewarded'
  final bool credited;

  ApplyReferralResult({
    required this.success,
    required this.message,
    this.code,
    this.status = 'pending',
    this.credited = false,
  });

  factory ApplyReferralResult.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? const {};
    return ApplyReferralResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      code: json['code']?.toString(),
      status: d['status']?.toString() ?? 'pending',
      credited: d['credited'] == true,
    );
  }
}
