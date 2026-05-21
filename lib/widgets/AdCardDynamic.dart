import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/utils/AppLogger.dart';
import '../Components/CustomAppButton.dart';
import '../Components/CustomSnackBar.dart';
import '../data/cubit/MyAds/MarkAsListing/mark_as_listing_cubit.dart';
import '../data/cubit/MyAds/MarkAsListing/mark_as_listing_state.dart';
import '../data/cubit/MyAds/my_ads_cubit.dart';
// `hide State` resolves the name clash with Flutter's State class —
// MyAdsModel exports a `State` for region/state data that we don't use
// in this file, but Dart can't pick between them once both are in scope.
import '../model/MyAdsModel.dart' hide State;
import '../services/ApiClient.dart';
import '../services/api_endpoint_urls.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import '../utils/constants.dart';
import 'ActionButton.dart';
import 'PlanTierBadge.dart';

class AdCardDynamic extends StatelessWidget {
  final Data ad;
  final bool isDark;
  final Color textColor;
  final VoidCallback boostAdCallback; // Callback to show the dialog

  const AdCardDynamic({
    required this.ad,
    required this.isDark,
    required this.textColor,
    required this.boostAdCallback, // Added to constructor
    Key? key,
  }) : super(key: key);

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade800;
      case 'expired':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _statusBgColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return Colors.green.shade100;
      case 'pending':
        return Colors.orange.shade100;
      case 'expired':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String _priceText(String? price) =>
      (price == null || price.isEmpty) ? '—' : "₹$price";

  String _postedText(String? postedAt) =>
      (postedAt == null || postedAt.isEmpty) ? '' : postedAt;

  @override
  Widget build(BuildContext context) {
    print("mobile number ::${mobile_no}");
    final imageUrl = ad.image ?? '';
    final location = ad.location ?? '';
    final isSold = ad.sold == true;
    return _wrapSold(
      isSold,
      Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + overlay SWA corner badge. Only rendered when
              // Smart Assist is actively negotiating for this listing so
              // sellers can scan the list without reading captions.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isEmpty
                        ? Container(
                            width: 64,
                            height: 64,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.directions_car_filled_outlined),
                          )
                        : Image.network(
                            imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (ad.swaActive)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1677FF), Color(0xFF4D9FFF)],
                          ),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1677FF).withOpacity(0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flash_on_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Top-left corner ribbon — same widget the public
                  // browse cards use. PlanTierBadge picks at most one
                  // ribbon (Power Seller → Pro → Featured → none).
                  // The seller's "My Ads" view shows the same badge
                  // their listings show to buyers.
                  Positioned(
                    top: 0,
                    left: 0,
                    child: PlanTierBadge(
                      tier: ad.planTier,
                      isFeatured: ad.featuredStatus == true,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title ?? 'Untitled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(
                        textColor,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.isEmpty ? (ad.description ?? '') : location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ad.category?.path != "job_ad" ? _priceText(ad.price) : "",
                      style: AppTextStyles.titleLarge(Colors.blue),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBgColor(ad.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (ad.status ?? '').isEmpty
                      ? '—'
                      : ad.status!.substring(0, 1).toUpperCase() +
                            ad.status!.substring(1),
                  style: AppTextStyles.labelSmall(_statusColor(ad.status)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _postedText(ad.postedAt),
                style: AppTextStyles.labelSmall(Colors.grey.shade600),
              ),
            ],
          ),
          if ((ad.status ?? '').toLowerCase() != "rejected") ...[
            Column(
              children: [
                Divider(height: 24, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if ((ad.status ?? '').toLowerCase() == "pending" || (ad.status ?? '').toLowerCase() == "approved" && ad.sold != true) ...[
                      ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: () {
                          context.push(
                            '/${ad.category?.path ?? ""}?catId=${ad.categoryId ?? ""}&CatName=${Uri.encodeComponent(ad.category?.name ?? "")}&subCatId=${ad.subCategoryId ?? ""}&SubCatName=${Uri.encodeComponent(ad.subCategory?.name ?? "")}&editId=${ad.id ?? ""}',
                          );
                        },
                      ),
                    ],
                    if (ad.featuredStatus != true &&
                        ad.sold != true &&
                        (ad.status ?? '').toLowerCase() == "approved") ...[
                        ActionButton(
                          icon: Icons.rocket_launch_outlined,
                          label: 'Boost Your Ad',
                          onTap:
                              boostAdCallback, // Call the callback directly here
                        ),

                    ],

                    if ((ad.status ?? '').toLowerCase() == "pending") ...[
                      ActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        textColor: Colors.grey.shade600,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final isDark = ThemeHelper.isDarkMode(context);

                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                backgroundColor: ThemeHelper.cardColor(context),
                                title: Text(
                                  'Confirm Deletion',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily: 'Inter',
                                    color: ThemeHelper.textColor(context),
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this item? This action cannot be undone.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.black54,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                actions: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomAppButton(
                                          text: 'Cancel',
                                          onPlusTap: () => context.pop(),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child:
                                            BlocConsumer<
                                              MarkAsListingCubit,
                                              MarkAsListingState
                                            >(
                                              listener:
                                                  (
                                                    context,
                                                    deleteExpenseState,
                                                  ) {
                                                    if (deleteExpenseState
                                                        is MarkAsListingDeleted) {
                                                      context
                                                          .read<MyAdsCubit>()
                                                          .getMyAds("pending");
                                                      context.pop();
                                                    } else if (deleteExpenseState
                                                        is MarkAsListingFailure) {
                                                      CustomSnackBar1.show(
                                                        context,
                                                        deleteExpenseState
                                                            .error,
                                                      );
                                                    }
                                                  },
                                              builder:
                                                  (
                                                    context,
                                                    deleteExpenseState,
                                                  ) {
                                                    return CustomAppButton1(
                                                      onPlusTap: () {
                                                        context
                                                            .read<
                                                              MarkAsListingCubit
                                                            >()
                                                            .markAsDelete(
                                                              ad.id ?? '',
                                                            );
                                                      },
                                                      text: 'Delete',
                                                      isLoading:
                                                          deleteExpenseState
                                                              is MarkAsListingLoading,
                                                    );
                                                  },
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],

                    if ((ad.status ?? '').toLowerCase() == "approved") ...[
                      if (ad.sold == true)
                        const Text(
                          "Sold Out",
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        ActionButton(
                          icon: Icons.sell_outlined,
                          label: 'Mark Sold',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                final isDark = ThemeHelper.isDarkMode(context);
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: ThemeHelper.cardColor(
                                    context,
                                  ),
                                  title: Text(
                                    'Confirm Mark as Sold',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      fontFamily: 'Inter',
                                      color: ThemeHelper.textColor(context),
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to mark this item as sold? This action cannot be undone.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.black54,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  actions: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomAppButton(
                                            text: 'Cancel',
                                            onPlusTap: () => context.pop(),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child:
                                              BlocConsumer<
                                                MarkAsListingCubit,
                                                MarkAsListingState
                                              >(
                                                listener: (context, markSoldState) {
                                                  if (markSoldState
                                                      is MarkAsListingSuccess) {
                                                    context
                                                        .read<MyAdsCubit>()
                                                        .getMyAds("approved");
                                                    context.pop();
                                                  } else if (markSoldState
                                                      is MarkAsListingFailure) {
                                                    CustomSnackBar1.show(
                                                      context,
                                                      markSoldState.error,
                                                    );
                                                  }
                                                },
                                                builder: (context, markSoldState) {
                                                  return CustomAppButton1(
                                                    textSize: 12,
                                                    onPlusTap: () {
                                                      context
                                                          .read<
                                                            MarkAsListingCubit
                                                          >()
                                                          .markAsSold(
                                                            ad.id ?? '',
                                                          );
                                                    },
                                                    text: 'Mark Sold',
                                                    isLoading:
                                                        markSoldState
                                                            is MarkAsListingLoading,
                                                  );
                                                },
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ],
          // ── Smart Assist (SWA) strip ────────────────────────────────
          // Only shown on approved, unsold listings. Three variants:
          //   • ACTIVE        — purple gradient, "negotiating" copy, → dashboard
          //   • DEACTIVATED   — outline, "Tap to activate" copy, ONE-TAP
          //                     reactivate (no wizard) using stored config
          //   • ELIGIBLE      — subtle outline, "try it" copy, → pricing wizard
          // Rejected/expired/sold/pending listings get nothing.
          if (ad.swaActive) ...[
            const SizedBox(height: 12),
            _SwaActiveStrip(
              listingId: ad.id ?? '',
              isDark: isDark,
            ),
          ] else if (ad.swaEligible && ad.swaPreviouslyActivated) ...[
            const SizedBox(height: 12),
            _SwaDeactivatedStrip(
              listingId: ad.id ?? '',
              listingTitle: ad.title ?? '',
              listedPrice:
                  int.tryParse(ad.price?.toString() ?? '0') ?? 0,
              expiresListDate: ad.expiresListDate,
              createdAt: ad.createdAt,
              isDark: isDark,
            ),
          ] else if (ad.swaEligible) ...[
            const SizedBox(height: 12),
            _SwaEligibleStrip(
              listingId: ad.id ?? '',
              listingTitle: ad.title ?? '',
              listedPrice:
                  int.tryParse(ad.price?.toString() ?? '0') ?? 0,
              expiresListDate: ad.expiresListDate,
              createdAt: ad.createdAt,
              isDark: isDark,
            ),
          ],
        ],
      ),
    ),
    );
  }

  /// Wrap a sold listing's card body so the seller can tell at a glance
  /// it's no longer active. Opacity + light grayscale matrix mute the
  /// card without making text unreadable (the existing red "Sold Out"
  /// badge inside the card still reads through the 0.55 layer). Tap
  /// stays enabled — the seller can still open the listing to review
  /// what they sold.
  Widget _wrapSold(bool isSold, Widget child) {
    if (!isSold) return child;
    return Opacity(
      opacity: 0.55,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.65, 0.27, 0.08, 0, 0,
          0.21, 0.79, 0.00, 0, 0,
          0.21, 0.27, 0.52, 0, 0,
          0,    0,    0,    1, 0,
        ]),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Smart Assist strips — compact variants sized to sit inline under the
// card's action row. The full promo lives on ProductDetailsScreen
// (SWAEnableCard) for first-time discovery; here we only need a clear,
// tappable handle.
// ─────────────────────────────────────────────────────────────────────

class _SwaActiveStrip extends StatelessWidget {
  final String listingId;
  final bool isDark;

  const _SwaActiveStrip({
    required this.listingId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/swa-dashboard/$listingId'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [const Color(0xFF0A1628), const Color(0xFF0F2847)]
                  : [const Color(0xFFEBF4FF), const Color(0xFFD6E8FF)],
            ),
            border: Border.all(
              color: const Color(0xFF1677FF).withOpacity(isDark ? 0.35 : 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF1677FF), Color(0xFF4D9FFF)],
                  ),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Smart Assist is active',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'AI is negotiating for you · Tap to manage',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF1677FF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwaEligibleStrip extends StatelessWidget {
  final String listingId;
  final String listingTitle;
  final int listedPrice;
  // ISO timestamps for the parent listing — forwarded through the wizard
  // so the availability step can compute the plan-total validity
  // (expires - created) and cap its day picker by that. Using
  // (expires - now) drifts the cap downward every hour, which would
  // hide the matching chip within an hour of listing creation.
  final String? expiresListDate;
  final String? createdAt;
  final bool isDark;

  const _SwaEligibleStrip({
    required this.listingId,
    required this.listingTitle,
    required this.listedPrice,
    required this.expiresListDate,
    required this.createdAt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final expiryQuery = expiresListDate != null
              ? '&expiresListDate=${Uri.encodeComponent(expiresListDate!)}'
              : '';
          final createdQuery = createdAt != null
              ? '&createdAt=${Uri.encodeComponent(createdAt!)}'
              : '';
          context.push(
            '/swa-wizard-pricing'
            '?listingId=$listingId'
            '&listedPrice=$listedPrice'
            '&listingTitle=${Uri.encodeComponent(listingTitle)}'
            '$expiryQuery'
            '$createdQuery',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1677FF).withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Color(0xFF1677FF),
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Try Smart Assist',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Let AI negotiate offers 24/7 — free',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xFF1677FF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// _SwaDeactivatedStrip — listing has prior SWA config but is_active=false.
// Tap fires a ONE-TAP reactivation that reuses the stored config; if the
// backend says MISSING_PREVIOUS_CONFIG (defensive — shouldn't happen
// since the strip only renders when `swa_previously_activated`), we
// fall back to the wizard so the seller can fix the missing fields.
// ─────────────────────────────────────────────────────────────────────
class _SwaDeactivatedStrip extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  final int listedPrice;
  // Forwarded only to the wizard fallback path. The fast-path reactivate
  // doesn't need either timestamp because the backend reads stored values.
  final String? expiresListDate;
  final String? createdAt;
  final bool isDark;

  const _SwaDeactivatedStrip({
    required this.listingId,
    required this.listingTitle,
    required this.listedPrice,
    required this.expiresListDate,
    required this.createdAt,
    required this.isDark,
  });

  @override
  State<_SwaDeactivatedStrip> createState() => _SwaDeactivatedStripState();
}

class _SwaDeactivatedStripState extends State<_SwaDeactivatedStrip> {
  bool _busy = false;

  Future<void> _reactivate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final url = APIEndpointUrls.swaActivate(widget.listingId);
      // Empty body — backend uses the listing's stored sell_with_ai_config
      // to fill every field. Older backends without the fallback would
      // 400 with EXPECTED_INVALID etc; new backends 400 only with
      // MISSING_PREVIOUS_CONFIG when stored values are genuinely absent.
      final res = await ApiClient.post(url, data: const <String, dynamic>{});
      if (!mounted) return;
      if (res.statusCode == 200 && res.data?['success'] == true) {
        // Refresh My Ads so the card flips to the active strip. We don't
        // pop — there's no route to pop; the seller is on the list view.
        try {
          context.read<MyAdsCubit>().getMyAds('approved');
        } catch (_) {}
        CustomSnackBar1.show(context, 'Smart Assist reactivated');
      } else {
        final msg = res.data?['message']?.toString() ?? 'Failed to activate';
        CustomSnackBar1.show(context, msg);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.data?['code']?.toString() ?? '';
      // Defensive fallback: the listing's stored config is somehow
      // incomplete (rare). Open the wizard so the seller can re-enter
      // the missing fields — same path a never-activated listing takes.
      if (code == 'MISSING_PREVIOUS_CONFIG') {
        final expiryQuery = widget.expiresListDate != null
            ? '&expiresListDate=${Uri.encodeComponent(widget.expiresListDate!)}'
            : '';
        final createdQuery = widget.createdAt != null
            ? '&createdAt=${Uri.encodeComponent(widget.createdAt!)}'
            : '';
        context.push(
          '/swa-wizard-pricing'
          '?listingId=${widget.listingId}'
          '&listedPrice=${widget.listedPrice}'
          '&listingTitle=${Uri.encodeComponent(widget.listingTitle)}'
          '$expiryQuery'
          '$createdQuery',
        );
      } else {
        final msg =
            e.response?.data?['message']?.toString() ?? 'Failed to activate';
        CustomSnackBar1.show(context, msg);
      }
    } catch (_) {
      if (!mounted) return;
      CustomSnackBar1.show(context, 'Failed to activate');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _busy ? null : _reactivate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? const Color(0xFFFFB020).withOpacity(0.07)
                : const Color(0xFFFFF7E8),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFFB020).withOpacity(0.20)
                  : const Color(0xFFFFE0A8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFB020).withOpacity(0.18),
                ),
                child: const Icon(
                  Icons.pause_circle_outline_rounded,
                  color: Color(0xFFB45309),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Smart Assist Deactivated',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _busy
                          ? 'Reactivating…'
                          : 'Tap to activate with your last settings',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFB45309),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
