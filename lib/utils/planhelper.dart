import 'dart:io';

import 'package:classifieds/data/cubit/FreeAd/FreeAdCubit.dart';
import 'package:classifieds/data/cubit/FreeAd/FreeAdStates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:classifieds/utils/constants.dart';

import '../data/cubit/UserActivePlans/user_active_plans_cubit.dart';
import '../data/cubit/UserActivePlans/user_active_plans_states.dart';
import '../model/UserActivePlansModel.dart';
import '../services/AuthService.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'AppLogger.dart';

void showPlanBottomSheet({
  required BuildContext context,
  required TextEditingController controller,
  required Function(Plans) onSelectPlan,
  String? title = 'Select Plan',
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: ThemeHelper.backgroundColor(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: BlocBuilder<UserActivePlanCubit, UserActivePlanStates>(
              builder: (context, state) {
                final textColor = ThemeHelper.textColor(context);
                final cardColor = ThemeHelper.cardColor(context);

                if (state is UserActivePlanLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  );
                }

                if (state is UserActivePlanFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 60,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Oops! Something went wrong',
                          style: AppTextStyles.headlineMedium(
                            textColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Unable to load plans. Please try again.',
                          style: AppTextStyles.bodyMedium(textColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        _buildRetryButton(context, textColor),
                      ],
                    ),
                  );
                }

                if (state is UserActivePlanLoaded) {
                  final plans = state.userActivePlansModel.plans ?? [];
                  final isEligibleForFree =
                      state.userActivePlansModel.isFree ?? false;
                  AppLogger.info("isEligibleForFree:${isEligibleForFree}");

                  // If the user is eligible for a free plan and there are no plans, show the dummy free plan
                  if (isEligibleForFree && plans.isEmpty) {
                    return BlocBuilder<FreeAdCubit, FreeAdStates>(
                      builder: (context, states) {
                        String freeExpiry = "N/A";

                        if (states is FreeAdLoaded) {
                          freeExpiry =
                              states.freeAdModel.data?.expiryDate
                                  .toLocal()
                                  .toString()
                                  .split(" ")
                                  .first ??
                              "N/A";
                        }

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 16.0,
                                    left: 8.0,
                                  ),
                                  child: Text(
                                    title,
                                    style:
                                        AppTextStyles.headlineSmall(
                                          textColor,
                                        ).copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ),

                              /// 🔥 FREE AD CARD (REAL DATA)
                              if (isEligibleForFree)
                                BlocBuilder<FreeAdCubit, FreeAdStates>(
                                  builder: (context, freeState) {
                                    if (freeState is FreeAdLoading) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (freeState is FreeAdLoaded) {
                                      return _buildPlanCard(
                                        context,
                                        Plans(
                                          planName: 'Free Ad',
                                          packageName: 'Basic Free Ad',
                                          remaining: 1,
                                          endDate: freeExpiry,
                                        ),
                                        textColor,
                                        cardColor,
                                        controller,
                                        onSelectPlan,
                                      );
                                    }

                                    return const SizedBox.shrink();
                                  },
                                ),

                              if (isEligibleForFree) const SizedBox(height: 15),

                              /// 🔥 SUBSCRIPTION PLANS
                              if (plans.isNotEmpty)
                                Expanded(
                                  child: ListView.separated(
                                    controller: scrollController,
                                    itemCount: plans.length,
                                    itemBuilder: (context, index) {
                                      final plan = plans[index];
                                      return _buildPlanCard(
                                        context,
                                        plan,
                                        textColor,
                                        cardColor,
                                        controller,
                                        onSelectPlan,
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                  ),
                                ),

                              if (!isEligibleForFree && plans.isEmpty)
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "No Plans Available",
                                      style: AppTextStyles.bodyLarge(textColor),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  // Show dummy free plan card along with subscription plans
                  if (isEligibleForFree && plans.isNotEmpty) {
                    return BlocBuilder<FreeAdCubit, FreeAdStates>(
                      builder: (context, states) {
                        String freeExpiry = "N/A";

                        if (states is FreeAdLoaded) {
                          freeExpiry =
                              states.freeAdModel.data?.expiryDate
                                  .toLocal()
                                  .toString()
                                  .split(" ")
                                  .first ??
                              "N/A";
                        }

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 16.0,
                                    left: 8.0,
                                  ),
                                  child: Text(
                                    title,
                                    style:
                                        AppTextStyles.headlineSmall(
                                          textColor,
                                        ).copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ),

                              /// 🔥 FREE AD CARD (REAL DATA)
                              if (isEligibleForFree)
                                BlocBuilder<FreeAdCubit, FreeAdStates>(
                                  builder: (context, freeState) {
                                    if (freeState is FreeAdLoading) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (freeState is FreeAdLoaded) {
                                      return _buildPlanCard(
                                        context,
                                        Plans(
                                          planName: 'Free Ad',
                                          packageName: 'Basic Free Ad',
                                          remaining: 1,
                                          endDate: freeExpiry,
                                        ),
                                        textColor,
                                        cardColor,
                                        controller,
                                        onSelectPlan,
                                      );
                                    }

                                    return const SizedBox.shrink();
                                  },
                                ),

                              if (isEligibleForFree) const SizedBox(height: 15),

                              /// 🔥 SUBSCRIPTION PLANS
                              if (plans.isNotEmpty)
                                Expanded(
                                  child: ListView.separated(
                                    controller: scrollController,
                                    itemCount: plans.length,
                                    itemBuilder: (context, index) {
                                      final plan = plans[index];
                                      return _buildPlanCard(
                                        context,
                                        plan,
                                        textColor,
                                        cardColor,
                                        controller,
                                        onSelectPlan,
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                  ),
                                ),

                              if (!isEligibleForFree && plans.isEmpty)
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "No Plans Available",
                                      style: AppTextStyles.bodyLarge(textColor),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  // If there are no plans and the user is not eligible for free, show the subscription plans message
                  if (plans.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 80,
                              color: textColor.withOpacity(0.6),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Plans Yet!',
                              style: AppTextStyles.headlineLarge(
                                textColor,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            // if (!(mobile_no == "9999999999" &&
                            //     Platform.isIOS)) ...[
                            Text(
                              'Subscribe to a plan to get started and unlock amazing features!',
                              style: AppTextStyles.bodyMedium(textColor),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            _buildSubscribeButton(context, textColor),
                          ],
                          // ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 16.0,
                              left: 8.0,
                            ),
                            child: Text(
                              title,
                              style: AppTextStyles.headlineSmall(textColor)
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: plans.length,
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              return _buildPlanCard(
                                context,
                                plan,
                                textColor,
                                cardColor,
                                controller,
                                onSelectPlan,
                              );
                            },
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Text(
                    'No plans available',
                    style: AppTextStyles.bodyLarge(
                      textColor,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}

Widget _buildPlanCard(
  BuildContext context,
  Plans plan,
  Color textColor,
  Color cardColor,
  TextEditingController controller,
  Function(Plans) onSelectPlan,
) {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cardColor,
            ThemeHelper.isDarkMode(context)
                ? cardColor.withOpacity(0.8)
                : cardColor.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          plan.planName ?? 'No name',
          style: AppTextStyles.titleLarge(
            textColor,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              plan.packageName ?? 'No package',
              style: AppTextStyles.bodyMedium(
                textColor,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 6),
            if (plan.planName != "Free Plan") ...[
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Remaining Ads: ${plan.remaining.toString()}',
                    style: AppTextStyles.bodySmall(textColor),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Expire Date : ${plan.endDate}',
                    style: AppTextStyles.bodySmall(textColor),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textColor.withOpacity(0.6),
        ),
        onTap: () {
          controller.text = plan.planName ?? '';
          onSelectPlan(plan);
          Navigator.pop(context);
        },
      ),
    ),
  );
}

Widget _buildSubscribeButton(BuildContext context, Color textColor) {
  return ElevatedButton(
    onPressed: () {
      context.pop();
      if (!(mobile_no == "9999999999" && Platform.isIOS)) {
        context.push("/plans");
      } else {
        context.push("/subscription_plans");
      }
    },
    style: ElevatedButton.styleFrom(
      foregroundColor: textColor,
      backgroundColor: ThemeHelper.isDarkMode(context)
          ? Colors.blueAccent.withOpacity(0.9)
          : Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      elevation: 3,
    ),
    child: Text(
      'Subscribe Now',
      style: AppTextStyles.titleMedium(
        Colors.white,
      ).copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

Widget _buildRetryButton(BuildContext context, Color textColor) {
  return ElevatedButton(
    onPressed: () {
      context.read<UserActivePlanCubit>().getUserActivePlansData();
    },
    style: ElevatedButton.styleFrom(
      foregroundColor: textColor,
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      elevation: 3,
    ),
    child: Text(
      'Retry',
      style: AppTextStyles.titleMedium(
        Colors.white,
      ).copyWith(fontWeight: FontWeight.bold),
    ),
  );
}
