import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/utils/AppLogger.dart';
import '../Components/CustomAppButton.dart';
import '../Components/CustomSnackBar.dart';
import '../data/cubit/MyAds/MarkAsListing/mark_as_listing_cubit.dart';
import '../data/cubit/MyAds/MarkAsListing/mark_as_listing_state.dart';
import '../data/cubit/MyAds/my_ads_cubit.dart';
import '../model/MyAdsModel.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import '../utils/constants.dart';
import 'ActionButton.dart';

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
    return Container(
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
        ],
      ),
    );
  }
}
