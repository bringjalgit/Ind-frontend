import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:classifieds/Components/CustomSnackBar.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/data/cubit/Products/products_cubit.dart';
import 'package:classifieds/model/WishlistModel.dart';
import 'package:classifieds/services/AuthService.dart';
import 'package:classifieds/utils/AppLogger.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Components/Shimmers.dart';
import '../../data/cubit/ProductDetails/product_details_cubit.dart';
import '../../data/cubit/ProductDetails/product_details_states.dart';
import '../../data/cubit/Products/Product_cubit1.dart';
import '../../data/cubit/ReportAd/ReportAdCubit.dart';
import '../../model/ProductDetailsModel.dart';
import '../../services/MetaEventTracker.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/AppLauncher.dart';
import '../../widgets/CommonLoader.dart';
import '../../widgets/SimilarProducts.dart';
import '../../widgets/SimilarProductsSection.dart';
import 'PhotoViewScreen.dart';
import 'ReportBottomSheet.dart';

extension DetailsX on Details {
  Map<String, dynamic> merged() {
    final map = Map<String, dynamic>.from(toJson());
    const hide = {'id', 'listing_id', 'created_at', 'updated_at'};
    map.removeWhere(
      (k, v) => hide.contains(k) || v == null || v.toString().trim().isEmpty,
    );
    return map;
  }
}

class ProductDetailsScreen extends StatefulWidget {
  final String listingId;
  final int subcategory_id;
  const ProductDetailsScreen({
    super.key,
    required this.listingId,
    required this.subcategory_id,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _didInitFromBloc = false;
  String? mobile_number;

  final ValueNotifier<int> _pageNotifier = ValueNotifier<int>(0);
  final PageController _pgCtrl = PageController();

  final Completer<GoogleMapController> _mapCtrl = Completer();

  LatLng? _listingLatLng;
  Set<Marker> _markers = {};
  bool _isResolvingLocation = false;

  String? receiverId;
  String? receiverName;
  String? receiverImage;
  String? listingId;
  String? listingTitle;

  @override
  void initState() {
    super.initState();
    context.read<ProductDetailsCubit>().getProductDetails(widget.listingId);
    context.read<ProductsCubit1>().getProducts(
      subCategoryId: widget.subcategory_id.toString(),
    );
  }

  LatLng? _parseLatLngFromString(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();

    final re = RegExp(r'(-?\d+(?:\.\d+)?)\D+(-?\d+(?:\.\d+)?)');
    final m = re.firstMatch(s);
    if (m != null && m.groupCount >= 2) {
      final lat = double.tryParse(m.group(1)!);
      final lng = double.tryParse(m.group(2)!);
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }

    // Super-simple fallback: pure "a,b"
    final parts = s.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  Future<void> _prepareMap(Listing listing) async {
    if (_isResolvingLocation) return;
    _isResolvingLocation = true;

    try {
      LatLng? pos;

      pos = _parseLatLngFromString(listing.location_key);

      if (pos == null) {
        final addressParts = [
          listing.location,
          listing.city_name,
          listing.state_name,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();

        if (addressParts.isNotEmpty) {
          final addr = addressParts.join(', ');
          final results = await geo
              .locationFromAddress(addr)
              .timeout(const Duration(seconds: 8));

          if (results.isNotEmpty) {
            pos = LatLng(results.first.latitude, results.first.longitude);
          }
        }
      }

      if (!mounted) return;

      if (pos != null) {
        setState(() {
          _listingLatLng = pos;
          _markers = {
            Marker(
              markerId: const MarkerId('listing'),
              position: pos!,
              infoWindow: InfoWindow(title: listing.title ?? 'Listing'),
            ),
          };
        });
      }
    } catch (e) {
      debugPrint("Map error: $e");
    } finally {
      _isResolvingLocation = false;
    }
  }

  Future<void> _openInGoogleMaps(LatLng pos) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String generateListingUrl(Listing listing) {
    final title = listing.title ?? '';
    final location = listing.location ?? '';
    final subCategoryId = listing.subCategoryId;
    final detailId = listing.id;

    // Create slug (convert spaces to hyphens, lowercase, remove special chars)
    String slugify(String text) {
      return text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // remove special chars
          .replaceAll(RegExp(r'\s+'), '-') // replace spaces with -
          .replaceAll(RegExp(r'-+'), '-'); // remove multiple dashes
    }

    final slugTitle = slugify('$title in $location');

    return 'https://indclassifieds.in/category/$slugTitle-$subCategoryId?detailId=$detailId';
  }

  @override
  void dispose() {
    _pgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final bgColor = ThemeHelper.backgroundColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: CustomAppBar1(title: 'Details', actions: []),
      bottomNavigationBar: FutureBuilder<List<Object?>>(
        future: Future.wait([AuthService.isGuest, AuthService.getId()]),
        builder: (context, snapshot) {
          /// 1️⃣ SHOW LOADER WHILE WAITING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _BottomCtaShimmer();
          }

          /// 2️⃣ HANDLE ERROR
          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }

          /// 3️⃣ HANDLE NO DATA SAFELY
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }

          final results = snapshot.data!;
          final isGuest = results[0] as bool;
          final userId = results[1] as String?;

          /// 4️⃣ HIDE IF INVALID
          if (userId == null ||
              userId.isEmpty ||
              receiverId == null ||
              receiverId!.isEmpty ||
              userId == receiverId) {
            return const SizedBox.shrink();
          }

          /// 5️⃣ SHOW CTA
          return _BottomCtaBar(
            onContact: isGuest
                ? () => context.push("/login")
                : () async {
                    if (mobile_number != null && mobile_number!.isNotEmpty) {
                      AppLauncher.call(mobile_number!);
                    } else {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      await Future.delayed(const Duration(seconds: 2));
                      if (context.mounted) Navigator.of(context).pop();
                      if (mobile_number != null && mobile_number!.isNotEmpty) {
                        AppLauncher.call(mobile_number!);
                      } else {
                        CustomSnackBar1.show(
                          context,
                          "Mobile number not available",
                        );
                      }
                    }
                  },
            onChat: isGuest
                ? () => context.push("/login")
                : () {
                    context.push(
                      '/chat'
                      '?receiverId=$receiverId'
                      '&listingId=$listingId'
                      '&listingTitle=${Uri.encodeComponent(listingTitle ?? "")}',
                    );
                  },
          );
        },
      ),
      body: SafeArea(
        child: BlocConsumer<ProductDetailsCubit, ProductDetailsStates>(
          listenWhen: (prev, curr) => curr is ProductDetailsLoaded,
          listener: (context, state) async {
            final s = state as ProductDetailsLoaded;
            final data = s.productDetailsModel.data!;
            final listing = data.listing!;

            if (!_didInitFromBloc) {
              _didInitFromBloc = true;

              receiverId = data.postedBy?.id.toString() ?? "";
              listingId = data.listing?.id;
              listingTitle = data.listing?.title ?? "";
              receiverName = data.postedBy?.name ?? "";
              receiverImage = data.postedBy?.image ?? "";
              mobile_number = listing.mobileNumber ?? "";

              // Initialize map position once
              await _prepareMap(listing);
              await MetaEventTracker.viewItem(
                itemId: widget.listingId.toString(),
                itemName: data.listing?.title ?? "",
              );
              if (mounted) setState(() {});
            }
          },
          builder: (context, state) {
            if (state is ProductDetailsLoading ||
                state is ProductDetailsInitially) {
              return productDetailsShimmer(context);
            }
            if (state is ProductDetailsFailure) {
              return _ErrorView(
                message: state.error.isNotEmpty
                    ? state.error
                    : "Failed to load.",
                onRetry: () => context
                    .read<ProductDetailsCubit>()
                    .getProductDetails(widget.listingId),
              );
            }
            if (state is ProductDetailsLoaded) {
              final model = (state as ProductDetailsLoaded).productDetailsModel;
              final data = model.data!;
              final listing = data.listing!;
              final images = data.images ?? const [];
              final details = data.details;
              final posted = data.postedBy;

              final title = listing.title ?? "Check this Listing";
              final priceStr = _formatINR(listing.price);
              final location = [
                listing.location,
                listing.city_name,
                listing.state_name,
              ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

              final safeLocation = location.isEmpty ? "—" : location;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            children: [
                              // 1) Images
                              PageView.builder(
                                controller: _pgCtrl,
                                onPageChanged: (i) => _pageNotifier.value = i,
                                itemCount: images.isEmpty ? 1 : images.length,
                                itemBuilder: (_, i) {
                                  final url = images.isNotEmpty
                                      ? images[i].image
                                      : null;
                                  return GestureDetector(
                                    onTap: () {
                                      if (images.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PhotoViewScreen(
                                                  images: images,
                                                  initialIndex: i,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    child: _ImageHero(url: url),
                                  );
                                },
                              ),

                              // 2) Watermark (bottom-right)
                              Positioned(
                                right: 0,
                                bottom: 0, // keep above the dots
                                child: IgnorePointer(
                                  ignoring: true,
                                  child: Image.asset(
                                    'assets/images/watermark.png', // <-- your watermark image
                                    width: 110, // tweak as needed
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),

                              // 3) Top-right actions
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _RoundIconButton(
                                      icon: Icons.ios_share_rounded,
                                      tooltip: 'Share',
                                      onTap: () {
                                        if (data.listing != null) {
                                          final shareUrl = generateListingUrl(
                                            data.listing!,
                                          );
                                          Share.share(shareUrl);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _RoundIconButton(
                                      icon: Icons.fullscreen_rounded,
                                      tooltip: 'View',
                                      onTap: () {
                                        if (images.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PhotoViewScreen(
                                                    images: images,
                                                    initialIndex:
                                                        _pageNotifier.value,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // 4) Dots
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 12,
                                child: Center(
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: _pageNotifier,
                                    builder: (context, page, _) {
                                      return _Dots(
                                        count: images.isEmpty
                                            ? 1
                                            : images.length,
                                        index: page,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.headlineSmall(textColor),
                          ),
                          const SizedBox(height: 6),
                          listing.price == "0.0" ||
                                  listing.price == "0" ||
                                  listing.price == "0.00"
                              ? const SizedBox.shrink()
                              : Text(
                                  "₹${_formatINR(listing.price)}",
                                  style: AppTextStyles.headlineMedium(
                                    textColor,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Item Information",
                        style: AppTextStyles.headlineSmall(
                          textColor,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  // Chips (Posted + Location)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          if (listing.createdAt != null)
                            _InfoChip(
                              icon: Icons.calendar_today_rounded,
                              label: "Posted At",
                              value: _shortDate(listing.createdAt),
                            ),
                          if (location.isNotEmpty)
                            _InfoChip(
                              icon: Icons.place_rounded,
                              label: "",
                              value: location,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ===== Description =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Description",
                        style: AppTextStyles.headlineSmall(
                          textColor,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Text(
                        (listing.description ?? "—").trim(),
                        style: AppTextStyles.bodyMedium(textColor),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  // ===== Specifications (Dynamic via Map) =====
                  if (details != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Specifications",
                          style: AppTextStyles.headlineSmall(
                            textColor,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: buildSpecifications(details),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                  // ===== AD ID =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "AD ID ${listing.id.toString()}",
                            style: AppTextStyles.bodyLarge(
                              textColor,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {
                              openReportSheetForListing(
                                context,
                                listingId: widget.listingId,
                              );
                            },
                            child: Text("REPORT THIS AD"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // ===== Location Map =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Location",
                            style: AppTextStyles.headlineSmall(
                              textColor,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 180,
                              color: ThemeHelper.cardColor(context),
                              child: _listingLatLng == null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          _isResolvingLocation
                                              ? "Loading map…"
                                              : "Location unavailable",
                                          style: AppTextStyles.bodySmall(
                                            textColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: _listingLatLng!,
                                        zoom: 14.5,
                                      ),
                                      zoomGesturesEnabled: false,
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: false,
                                      rotateGesturesEnabled: false,
                                      tiltGesturesEnabled: false,
                                      markers: _markers,
                                      onMapCreated: (c) => _mapCtrl.complete(c),
                                    ),
                            ),
                          ),
                          if (_listingLatLng != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _openInGoogleMaps(_listingLatLng!),
                                icon: const Icon(Icons.directions),
                                label: const Text("Open in Google Maps"),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // ===== Posted By =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PostedByCard(
                        avatarUrl: posted?.image,
                        name: posted?.name ?? "—",
                        postedOn:
                            posted?.postedAt ?? _shortDate(listing.createdAt),
                        onViewProfile: () {},
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 280,
                      child: SimilarProductsSection(
                        subCategoryId: listing.subCategoryId?.toString() ?? "",
                        excludeId: listing.id,
                        onTap: (prod) {
                          context.pushReplacement(
                            "/products_details?listingId=${listing.id}&subcategory_id=${listing.subCategoryId}",
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// ============================================================
  /// PRODUCT DETAILS PREMIUM SHIMMER
  /// Perfect Layout Match
  /// ============================================================

  Widget productDetailsShimmer(BuildContext context) {
    return CustomScrollView(
      slivers: [
        /// IMAGE AREA
        SliverToBoxAdapter(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: shimmerRectangle(
              width: double.infinity,
              height: double.infinity,
              context: context,
              radius: 0,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        /// TITLE + PRICE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmerText(width: 240, height: 22, context: context),
                const SizedBox(height: 12),
                shimmerText(width: 120, height: 24, context: context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        /// ITEM INFORMATION TITLE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shimmerText(width: 180, height: 20, context: context),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        /// CHIPS
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                shimmerRectangle(
                  width: 140,
                  height: 42,
                  radius: 16,
                  context: context,
                ),
                shimmerRectangle(
                  width: 180,
                  height: 42,
                  radius: 16,
                  context: context,
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        /// DESCRIPTION TITLE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shimmerText(width: 160, height: 20, context: context),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        /// DESCRIPTION LINES
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: shimmerText(width: double.infinity, context: context),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        /// SPECIFICATIONS TITLE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shimmerText(width: 180, height: 20, context: context),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        /// SPEC ROWS
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      shimmerText(width: 120, context: context),
                      const Spacer(),
                      shimmerText(width: 100, context: context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        /// MAP TITLE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shimmerText(width: 140, height: 20, context: context),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        /// MAP BOX
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shimmerRectangle(
              width: double.infinity,
              height: 180,
              radius: 16,
              context: context,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        /// POSTED BY CARD
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ThemeHelper.cardColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  shimmerCircle(44, context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerText(width: 80, context: context),
                        const SizedBox(height: 6),
                        shimmerText(width: 160, context: context),
                        const SizedBox(height: 6),
                        shimmerText(width: 120, context: context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        /// SIMILAR PRODUCTS TITLE PLACEHOLDER
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shimmerText(width: 200, height: 20, context: context),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        /// SIMILAR CARDS ROW
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: shimmerRectangle(
                  width: 150,
                  height: 200,
                  radius: 16,
                  context: context,
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  void openReportSheetForListing(
    BuildContext context, {
    required String listingId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return Material(
            color: ThemeHelper.backgroundColor(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SingleChildScrollView(
              controller: scrollController,
              child: ReportBottomSheet.listing(listingId: listingId),
            ),
          );
        },
      ),
    );
  }

  Widget buildSpecifications(Details d) {
    final map = d.merged(); // from extension
    if (map.isEmpty)
      return Text(
        "No specifications available.",
        style: AppTextStyles.bodyMedium(ThemeHelper.textColor(context)),
      );

    final textColor = ThemeHelper.textColor(context);
    final dividerColor = ThemeHelper.isDarkMode(context)
        ? Colors.white12
        : const Color(0x11000000);

    return Column(
      children: map.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _labelize(e.key),
                  style: AppTextStyles.bodyMedium(
                    textColor,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _formatValue(e.key, e.value),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMedium(textColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===== Helpers =====
  String _labelize(String key) {
    return key
        .replaceAll("_", " ")
        .split(" ")
        .map((w) => w.isEmpty ? w : "${w[0].toUpperCase()}${w.substring(1)}")
        .join(" ");
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return "—";
    final v = value.toString().trim();
    if (key.contains("mobile")) {
      final d = v.replaceAll(RegExp(r'\D'), '');
      return d.length >= 4 ? "******${d.substring(d.length - 4)}" : v;
    }
    if (key.contains("price")) return "₹$v";
    if (key.contains("facing_direction")) {
      return v.isEmpty
          ? v
          : (v[0].toUpperCase() + v.substring(1).toLowerCase());
    }
    return v;
  }
}

class _BottomCtaShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: shimmerRectangle(
                width: double.infinity,
                height: 50,
                radius: 14,
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: shimmerRectangle(
                width: double.infinity,
                height: 50,
                radius: 14,
                context: context,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ===== Widgets =====

class _ImageHero extends StatelessWidget {
  final String? url;
  const _ImageHero({this.url});

  @override
  Widget build(BuildContext context) {
    final cardColor = ThemeHelper.cardColor(context);
    final iconColor = ThemeHelper.textColor(context).withOpacity(.5);
    return Container(
      color: cardColor,
      child: (url == null || url!.isEmpty)
          ? Center(child: Icon(Icons.image, size: 56, color: iconColor))
          : Image.network(url!, fit: BoxFit.cover),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final activeColor = ThemeHelper.textColor(context);
    final idleColor = activeColor.withOpacity(0.25);
    return Wrap(
      spacing: 6,
      children: List.generate(count, (i) {
        final active = i == index;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? activeColor : idleColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final chipBg = ThemeHelper.isDarkMode(context)
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            "$label  ",
            style: AppTextStyles.bodySmall(
              textColor,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostedByCard extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String postedOn;
  final VoidCallback onViewProfile;
  const _PostedByCard({
    required this.avatarUrl,
    required this.name,
    required this.postedOn,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);
    final borderColor = ThemeHelper.isDarkMode(context)
        ? Colors.white12
        : Colors.black12;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? NetworkImage(avatarUrl!)
                : null,
            child: (avatarUrl == null || avatarUrl!.isEmpty)
                ? Icon(Icons.person, color: textColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Posted by",
                  style: AppTextStyles.bodySmall(textColor.withOpacity(.6)),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: AppTextStyles.bodyMedium(
                    textColor,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  "Posted on $postedOn",
                  style: AppTextStyles.bodySmall(textColor.withOpacity(.6)),
                ),
              ],
            ),
          ),
          // IconButton(
          //   onPressed: onViewProfile,
          //   icon: Icon(Icons.person_add_alt_1, color: textColor),
          // ),
        ],
      ),
    );
  }
}

class _BottomCtaBar extends StatelessWidget {
  final VoidCallback onContact;
  final VoidCallback onChat;
  const _BottomCtaBar({
    required this.onContact,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: CustomAppButton1(
                text: "Contact Seller",
                onPlusTap: onContact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomAppButton1(text: "Chat", onPlusTap: onChat),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipOval(
      child: Material(
        color: (isDark ? Colors.black54 : Colors.white70),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Tooltip(
              message: tooltip ?? '',
              child: Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Skeleton & Error (theme-aware) =====

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final card = ThemeHelper.cardColor(context);
    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(color: card),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(
              6,
              (i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 16,
                color: card,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final iconColor = Colors.redAccent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: iconColor),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(textColor),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Utility formatting =====

String _formatINR(String? price) {
  final val = double.tryParse(price ?? "");
  if (val == null) return "0";
  final f = NumberFormat.currency(
    locale: 'en_IN',
    symbol: "",
    decimalDigits: 0,
  );
  return f.format(val);
}

String _shortDate(String? iso) {
  if (iso == null) return "—";
  final d = DateTime.tryParse(iso);
  if (d == null) return "—";
  return DateFormat('dd/MM/yyyy').format(d.toLocal());
}
