import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/cubit/Advertisement/advertisement_cubit.dart';
import '../../data/cubit/Advertisement/advertisement_states.dart';
import '../../model/AdvertisementModel.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/CommonLoader.dart';
import 'AddsScreen.dart';

class AdvertisementScreen extends StatefulWidget {
  const AdvertisementScreen({Key? key}) : super(key: key);

  @override
  State<AdvertisementScreen> createState() => _AdvertisementScreenState();
}

class _AdvertisementScreenState extends State<AdvertisementScreen> {
  AdStatus selectedStatus = AdStatus.approved;

  @override
  void initState() {
    super.initState();
    // Initial fetch for "approved"
    context.read<AdvertisementsCubit>().getAdvertisements(
      selectedStatus.apiParam,
    );
  }

  void _onChangeTab(AdStatus status) {
    setState(() => selectedStatus = status);
    context.read<AdvertisementsCubit>().getAdvertisements(
      status.apiParam,
    ); // resets to page 1
  }

  bool _onScrollNotification(ScrollNotification sn, bool hasNextPage) {
    if (!hasNextPage) return false;

    final isScrollEnd = sn.metrics.pixels >= (sn.metrics.maxScrollExtent - 200);
    final movingForward =
        sn is ScrollUpdateNotification &&
        sn.scrollDelta != null &&
        sn.scrollDelta! > 0;

    if (isScrollEnd && movingForward) {
      context.read<AdvertisementsCubit>().getMoreAdvertisements(
        selectedStatus.apiParam,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final bgColor = ThemeHelper.backgroundColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: CustomAppBar1(
        title: "Advertisements",
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () {
                context.push("/post_advertisements");
              },
              icon: Icon(Icons.add_box_outlined, color: Colors.black, size: 30),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Tabs (Filtering buttons)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: AdStatus.values.map((status) {
                final isSelected = selectedStatus == status;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextButton(
                      onPressed: () => _onChangeTab(status),
                      style: TextButton.styleFrom(
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        status.label.toUpperCase(),
                        style: AppTextStyles.bodyMedium(
                          isSelected ? Colors.white : Colors.grey.shade700,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Advertisement List + Pagination
          Expanded(
            child: BlocBuilder<AdvertisementsCubit, AdvertisementStates>(
              builder: (context, state) {
                final isLoading =
                    state is AdvertisementLoading ||
                    state is AdvertisementInitially;
                final isLoadingMore = state is AdvertisementLoadingMore;
                final hasNextPage = (state is AdvertisementLoaded)
                    ? state.hasNextPage
                    : (state is AdvertisementLoadingMore)
                    ? state.hasNextPage
                    : false;

                if (isLoading) {
                  return Center(child:DottedProgressWithLogo());
                }

                if (state is AdvertisementFailure) {
                  return Center(
                    child: Text(
                      state.error.isEmpty ? 'Failed to load ads' : state.error,
                      style: AppTextStyles.bodyMedium(textColor),
                    ),
                  );
                }

                final model = (state is AdvertisementLoaded)
                    ? state.advertisementModel
                    : (state is AdvertisementLoadingMore)
                    ? state.advertisementModel
                    : null;

                final items = model?.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${selectedStatus.label.toLowerCase()} advertisements',
                      style: AppTextStyles.bodyMedium(textColor),
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (sn) =>
                      _onScrollNotification(sn, hasNextPage),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + (isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, index) {
                      if (isLoadingMore && index == items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final ad = items[index];
                      return _AdvertisementCard(
                        ad: ad,
                        isDark: isDark,
                        textColor: textColor,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvertisementCard extends StatelessWidget {
  final Data ad;
  final bool isDark;
  final Color textColor;

  const _AdvertisementCard({
    required this.ad,
    required this.isDark,
    required this.textColor,
    Key? key,
  }) : super(key: key);

  // Function to launch the URL
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Color getStatusColor(String? status) {
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

  Color getStatusBgColor(String? status) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Status Overlay
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    ad.image ?? '',
                    height: 180, // Adjust height for banner effect
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Status Overlay
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusBgColor(ad.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ad.status ?? 'Unknown',
                    style: AppTextStyles.bodyMedium(getStatusColor(ad.status)),
                  ),
                ),
              ),
            ],
          ),

          // Name and Link Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Advertisement Name
                Text(
                  ad.name ?? 'No Name',
                  style: AppTextStyles.headlineSmall(
                    ThemeHelper.textColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Advertisement Link
                GestureDetector(
                  onTap: () => _launchURL(ad.link ?? ''),
                  child: Text(
                    ad.link ?? 'No Link',
                    style: AppTextStyles.bodyMedium(
                      ThemeHelper.textColor(context),
                    ).copyWith(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
