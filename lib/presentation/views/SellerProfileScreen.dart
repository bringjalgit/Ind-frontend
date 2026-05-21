import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../model/SellerProfileModel.dart';
import '../../services/ApiClient.dart';
import '../../services/api_endpoint_urls.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

/// Public seller profile screen — opened from the listing detail
/// "View seller profile" link. Shows the seller's avatar, name,
/// member-since, location, listing counts, and a grid of all their
/// approved + expired listings. Expired listings render with reduced
/// opacity + a subtle blur, and tapping any listing opens the standard
/// product details screen.
class SellerProfileScreen extends StatefulWidget {
  final String userId;
  // Header title — defaults to "Seller Profile" (the only use until
  // 2026-05). Chat now opens the same screen for the BUYER side of a
  // conversation (i.e. when the seller taps the buyer's name in the
  // chat AppBar). The body is identical — listings just come back
  // empty for a pure-buyer — but the header label needs to switch to
  // "Buyer Profile" so the seller knows they're looking at the buyer,
  // not their own seller-facing view.
  final String? title;
  const SellerProfileScreen({super.key, required this.userId, this.title});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late Future<SellerProfileModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SellerProfileModel> _load() async {
    final Response r = await ApiClient.post(
      APIEndpointUrls.get_seller_public_profile,
      data: {'user_id': widget.userId},
    );
    return SellerProfileModel.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final bg = ThemeHelper.backgroundColor(context);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        // Force the icon/title to use the theme's text color. Without
        // this, in light mode the default AppBar foreground is white
        // → invisible back arrow on the white-ish app background.
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.title ?? 'Seller Profile',
          style: AppTextStyles.titleLarge(textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<SellerProfileModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load seller profile.\n${snap.error ?? ""}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(textColor.withOpacity(.7)),
                ),
              ),
            );
          }
          final data = snap.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _load();
              });
              await _future;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SellerHeader(
                    seller: data.seller,
                    counts: data.counts,
                    isOwner: data.isOwner,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Listings (${data.listings.length})',
                      style: AppTextStyles.titleMedium(textColor)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (data.listings.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          // Empty-state label flips with the header
                          // title. When ChatScreen opens this screen
                          // for the seller looking at the buyer, the
                          // title is "Buyer Profile" — so the empty
                          // state should also say "buyer". Anywhere
                          // else (the original "View seller profile"
                          // entry) the title is null / "Seller" and
                          // we keep the original copy.
                          (widget.title ?? '').toLowerCase().contains('buyer')
                              ? 'This buyer has no listings yet.'
                              : 'This seller has no listings yet.',
                          style: AppTextStyles.bodyMedium(textColor.withOpacity(.6)),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        // Slightly taller cells so the flexed image stays
                        // near-square after the price + 2-line title block.
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final l = data.listings[index];
                          return _ListingCard(
                            listing: l,
                            onTap: () => _openListing(l),
                          );
                        },
                        childCount: data.listings.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openListing(SellerListing l) {
    if (l.id == null) return;
    final sub = l.subCategoryId ?? '';
    context.push(
      '/products_details?listingId=${l.id}&subcategory_id=$sub',
    );
  }
}

class _SellerHeader extends StatelessWidget {
  final SellerInfo? seller;
  final SellerCounts? counts;
  final bool isOwner;
  const _SellerHeader({
    required this.seller,
    required this.counts,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    if (seller == null) return const SizedBox.shrink();
    final s = seller!;
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);
    final borderColor =
        ThemeHelper.isDarkMode(context) ? Colors.white12 : Colors.black12;
    final loc = [s.cityName, s.stateName].where((e) => (e ?? '').isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                // Same fallback the profile dashboard uses for
                // consistency across the app.
                backgroundImage: (s.image != null && s.image!.isNotEmpty)
                    ? NetworkImage(s.image!) as ImageProvider
                    : const AssetImage('assets/images/profile.png'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.name ?? 'Seller',
                            style: AppTextStyles.titleLarge(textColor)
                                .copyWith(fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Verified tick is Aadhaar-only — same rule as
                        // the user's own profile so the meaning is
                        // consistent across the app.
                        if (s.aadhaarVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified, color: Colors.blue, size: 18),
                        ],
                      ],
                    ),
                    if (loc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 14, color: textColor.withOpacity(.6)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              loc,
                              style: AppTextStyles.bodySmall(
                                textColor.withOpacity(.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (s.memberSince != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${s.memberSince!}',
                        style: AppTextStyles.bodySmall(textColor.withOpacity(.7)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (s.bio != null && s.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.bio!,
                style: AppTextStyles.bodySmall(textColor.withOpacity(.85)),
              ),
            ),
          ],
          if (counts != null) ...[
            const SizedBox(height: 14),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 10),
            // Owner sees Active · Sold · Expired (their full archive).
            // Outsiders only see Active — sold/expired counts are a
            // private slice of the seller's history.
            Row(
              mainAxisAlignment: isOwner
                  ? MainAxisAlignment.spaceAround
                  : MainAxisAlignment.center,
              children: [
                _CountStat(label: 'Active', value: counts!.active),
                if (isOwner) ...[
                  _CountStat(label: 'Sold', value: counts!.sold),
                  _CountStat(label: 'Expired', value: counts!.expired),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CountStat extends StatelessWidget {
  final String label;
  final int value;
  const _CountStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    return Column(
      children: [
        Text(
          '$value',
          style: AppTextStyles.titleLarge(textColor)
              .copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall(textColor.withOpacity(.7)),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  final SellerListing listing;
  final VoidCallback onTap;
  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);
    final borderColor =
        ThemeHelper.isDarkMode(context) ? Colors.white12 : Colors.black12;
    // Both expired AND sold listings are visually demoted (blur + dim)
    // so the active ones stand out. Each keeps its own corner badge.
    final blur = listing.isExpired || listing.sold;

    Widget image() {
      Widget img;
      if (listing.image != null && listing.image!.isNotEmpty) {
        img = CachedNetworkImage(
          imageUrl: listing.image!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (c, _) => Container(color: Colors.grey.shade200),
          errorWidget: (c, _, __) => Container(
            color: Colors.grey.shade200,
            child: Icon(Icons.image_not_supported, color: textColor.withOpacity(.4)),
          ),
        );
      } else {
        img = Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(Icons.image, color: textColor.withOpacity(.4)),
          ),
        );
      }
      // Expired and sold listings get a subtle blur + dim so they're
      // visually demoted but still tappable for archive viewing. Each
      // shows its own corner badge: EXPIRED (black) or SOLD (green).
      if (blur) {
        final isExpiredState = listing.isExpired;
        final label = isExpiredState ? 'EXPIRED' : 'SOLD';
        final badgeColor = isExpiredState
            ? Colors.black.withOpacity(0.65)
            : Colors.green.shade700;
        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
              child: img,
            ),
            Container(color: Colors.black.withOpacity(0.18)),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall(Colors.white)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      }
      return img;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image flexes to absorb whatever vertical space is left
              // after the text block, so the card never overflows the
              // grid cell regardless of screen width or text scaling.
              // (Previously a fixed square AspectRatio made the column
              // taller than the cell, pushing the title out of the card.)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: image(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${listing.price?.toStringAsFixed(0) ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(textColor)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.title ?? '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(textColor.withOpacity(.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
