import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:classifieds/data/cubit/Plans/plans_cubit.dart';
import 'package:classifieds/utils/color_constants.dart';
import 'package:classifieds/widgets/CommonLoader.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Components/CustomSnackBar.dart';
import '../../Components/Shimmers.dart';
import '../../data/cubit/Packages/packages_cubit.dart';
import '../../data/cubit/Packages/packages_states.dart';
import '../../data/cubit/Payment/payment_cubit.dart';
import '../../data/cubit/Payment/payment_states.dart';
import '../../data/cubit/Plans/plans_states.dart';
import '../../data/cubit/UserActivePlans/user_active_plans_cubit.dart';
import '../../model/PlansModel.dart';
import '../../services/AuthService.dart';
import '../../services/MetaEventTracker.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/AppLogger.dart';
import 'dart:io' show Platform;

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _BoostYourSalesScreenState();
}

class _BoostYourSalesScreenState extends State<PlansScreen> {
  late Razorpay _razorpay;
  final ValueNotifier<String?> userNameNotifier = ValueNotifier<String?>("");
  final ValueNotifier<String?> userEmailNotifier = ValueNotifier<String?>("");
  final ValueNotifier<String?> userMobileNotifier = ValueNotifier<String?>("");

  @override
  void initState() {
    super.initState();
    getUserDetails();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlansCubit>().getPlans();
    });
  }

  Future<void> getUserDetails() async {
    userNameNotifier.value = await AuthService.getName();
    userEmailNotifier.value = await AuthService.getEmail();
    userMobileNotifier.value = await AuthService.getMobile();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    AppLogger.log(
      "✅ Payment successful: ${response.paymentId} ${response.signature} ${response.orderId}",
    );
    Map<String, dynamic> data = {
      "razorpay_order_id": response.orderId,
      "razorpay_payment_id": response.paymentId,
      "razorpay_signature": response.signature,
    };
    context.read<PaymentCubit>().verifyPayment(data);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    AppLogger.log("❌ Payment failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.log("💼 External wallet selected: ${response.walletName}");
  }

  void _openCheckout(String key, int amount, String order_id) {
    var options = {
      'key': '$key',
      'amount': amount,
      'currency': 'INR',
      'name': userNameNotifier.value,
      'order_id': '$order_id',
      'description': 'purchase',
      'timeout': 60,
      'prefill': {
        'contact': userMobileNotifier.value ?? "",
        'email': userEmailNotifier.value ?? "",
      },
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      AppLogger.log('Error: $e');
    }
  }

  String getPlatformText({required String ios, required String android}) {
    return Platform.isIOS ? ios : android;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final bgColor = ThemeHelper.backgroundColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Color(0xff1677FF),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          getPlatformText(ios: "Post Your Ad", android: "Boost Your Sales"),
          style: AppTextStyles.headlineSmall(
            Colors.white,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<PlansCubit, PlansStates>(
        builder: (context, state) {
          if (state is PlansLoading) {
            return plansScreenShimmer(context);
          }
          if (state is PlansFailure) {
            return _PlansErrorView(
              message: state.error.isNotEmpty == true
                  ? state.error
                  : "Unable to load plans.",
              onRetry: () => context.read<PlansCubit>().getPlans(),
            );
          }
          if (state is PlansLoaded) {
            final plans = state.plansModel.plans ?? const <Plans>[];
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    getPlatformText(
                      ios: "Select an Ad Posting Package",
                      android: "Choose Your Plan",
                    ),
                    style: AppTextStyles.headlineMedium(
                      textColor,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    getPlatformText(
                      ios:
                          "Choose a package to list your physical product for sale.",
                      android: "Select the perfect package to boost your sales",
                    ),
                    style: AppTextStyles.bodyMedium(textColor.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 20),

                  // Dynamic cards from API
                  if (plans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(
                        "No plans available right now.",
                        style: AppTextStyles.bodyMedium(textColor),
                      ),
                    )
                  else
                    ...plans.map((plan) {
                      final visuals = _planVisualsFor(plan);
                      final features = _deriveFeatureBullets(plan);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _buildPlanCard(
                          context,
                          title: plan.name ?? "—",
                          planid: plan.id ?? 0,
                          duration_days: plan.durationDays ?? 0,
                          subtitle: plan.description ?? "",
                          price: plan.startingPriceFrom != null
                              ? "Starting from ₹${plan.startingPriceFrom}"
                              : "Custom pricing",
                          oldPrice: null,
                          discount: null,
                          gradient: visuals.gradient,
                          icon: visuals.icon,
                          imageUrl: plan.image,
                          features: features,
                          tag: (plan.features?.type == true)
                              ? getPlatformText(
                                  ios: "POPULAR PACKAGE",
                                  android: "MOST POPULAR",
                                )
                              : null,
                        ),
                      );
                    }).toList(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Secure Payment",
                        style: AppTextStyles.bodySmall(
                          textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.support_agent,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "24/7 Support",
                        style: AppTextStyles.bodySmall(
                          textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Best Value",
                        style: AppTextStyles.bodySmall(
                          textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    getPlatformText(
                      ios: "Need help choosing a package?",
                      android: "Need help choosing?",
                    ),
                    style: AppTextStyles.bodyMedium(textColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push("/contact_support");
                    },
                    child: Text(
                      "Contact Support",
                      style: AppTextStyles.bodyMedium(
                        Colors.blue,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
          // initial
          return Center(child: DottedProgressWithLogo());
        },
      ),
    );
  }

  /// ============================================================
  /// PREMIUM PLAN CARD SHIMMER
  /// Matches _buildPlanCard UI
  /// ============================================================

  Widget planCardShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ThemeHelper.isDarkMode(context)
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            /// HEADER IMAGE AREA
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: shimmerRectangle(
                width: double.infinity,
                height: 120,
                context: context,
                radius: 0,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  shimmerText(width: 180, height: 20, context: context),
                  const SizedBox(height: 8),

                  shimmerText(width: 220, context: context),
                  const SizedBox(height: 16),

                  /// PRICE ROW
                  shimmerText(width: 140, height: 18, context: context),

                  const SizedBox(height: 20),

                  /// BUTTON
                  shimmerRectangle(
                    width: double.infinity,
                    height: 53,
                    radius: 16,
                    context: context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget plansHeaderShimmer(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        shimmerText(width: 220, height: 22, context: context),
        const SizedBox(height: 10),
        shimmerText(width: 260, context: context),
        const SizedBox(height: 4),
        shimmerText(width: 200, context: context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget plansFooterShimmer(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            shimmerCircle(16, context),
            const SizedBox(width: 8),
            shimmerText(width: 90, context: context),
            const SizedBox(width: 16),
            shimmerCircle(16, context),
            const SizedBox(width: 8),
            shimmerText(width: 90, context: context),
          ],
        ),
        const SizedBox(height: 20),
        shimmerText(width: 200, context: context),
        const SizedBox(height: 8),
        shimmerText(width: 120, context: context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget plansScreenShimmer(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          plansHeaderShimmer(context),

          /// 3 Plan Cards
          planCardShimmer(context),
          planCardShimmer(context),
          planCardShimmer(context),

          plansFooterShimmer(context),
        ],
      ),
    );
  }

  /// Build a single Plan Card (now supports image header)
  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required int planid,
    required int duration_days,
    required String subtitle,
    required String price,
    String? oldPrice, // not used when null
    String? discount, // not used when null
    required List<Color> gradient,
    required IconData icon,
    String? imageUrl,
    required List<String> features,
    String? tag,
  }) {
    final textColor = ThemeHelper.textColor(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ThemeHelper.cardColor(context),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: ThemeHelper.isDarkMode(context)
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header: image if present, otherwise gradient + icon
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 6,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) {
                            // fallback to gradient if image fails
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: gradient),
                              ),
                              alignment: Alignment.center,
                              child: Icon(icon, size: 50, color: Colors.white),
                            );
                          },
                        ),
                      ),
                      // Overlay gradient for readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.25),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 50, color: Colors.white),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineSmall(
                        textColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(
                          textColor.withOpacity(0.7),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // price / discount row
                    if (price.isNotEmpty ||
                        discount != null ||
                        oldPrice != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (price.isNotEmpty)
                            Text(
                              price,
                              style: AppTextStyles.bodyMedium(
                                textColor,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          if (oldPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              oldPrice,
                              style:
                                  AppTextStyles.bodySmall(
                                    textColor.withOpacity(0.6),
                                  ).copyWith(
                                    decoration: TextDecoration.lineThrough,
                                  ),
                            ),
                          ],
                          if (discount != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              discount,
                              style: AppTextStyles.bodySmall(
                                Colors.green,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 12),
                    //
                    // // bullets
                    // Column(
                    //   children: features
                    //       .map(
                    //         (f) => Padding(
                    //           padding: const EdgeInsets.symmetric(vertical: 4),
                    //           child: Row(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               const Icon(
                    //                 Icons.check_circle,
                    //                 color: Colors.blue,
                    //                 size: 18,
                    //               ),
                    //               const SizedBox(width: 8),
                    //               Expanded(
                    //                 child: Text(
                    //                   f,
                    //                   style: AppTextStyles.bodyMedium(
                    //                     textColor,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       )
                    //       .toList(),
                    // ),

                    // const SizedBox(height: 14),
                    SizedBox(
                      height: 53,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (planid == null) return;
                          showPlanPackagesSheet(
                            context,
                            planId: planid,
                            planName: title ?? '—',
                            durationDays: duration_days ?? 0,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: gradient.last,
                        ),
                        icon: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                        ),
                        label: Text(
                          "View Plans",
                          style: AppTextStyles.bodyMedium(
                            Colors.white,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating Tag
        if (tag != null)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.labelSmall(
                    Colors.white,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> showPlanPackagesSheet(
    BuildContext context, {
    required int planId,
    required String planName,
    required int durationDays,
  }) async {
    final existing = context.read<PackagesCubit>();
    final ValueNotifier<int?> selectedIndex = ValueNotifier(null);
    final ValueNotifier<int?> packageId = ValueNotifier(null);
    final ValueNotifier<int?> plan_id = ValueNotifier(null);
    final ValueNotifier<String?> price = ValueNotifier("");
    final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeHelper.backgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        Future.microtask(() => existing.getPackages(planId));

        final textColor = ThemeHelper.textColor(sheetCtx);
        final cardColor = ThemeHelper.cardColor(sheetCtx);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: BlocBuilder<PackagesCubit, PackagesStates>(
              bloc: existing,
              builder: (ctx, state) {
                final header = _SheetHeader(
                  planName: planName,
                  durationDays: durationDays,
                );

                if (state is PackagesLoading || state is PackagesInitially) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      header,
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 16),
                      _SkeletonPackageTile(color: cardColor),
                      const SizedBox(height: 12),
                      _SkeletonPackageTile(color: cardColor),
                      const SizedBox(height: 12),
                      _SkeletonPackageTile(color: cardColor),
                      const SizedBox(height: 24),
                    ],
                  );
                }

                if (state is PackagesFailure) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      header,
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 24),
                      Icon(
                        Icons.error_outline,
                        size: 40,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          state.error.isEmpty
                              ? "Unable to fetch packages."
                              : state.error,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(textColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => existing.getPackages(planId),
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                final model = (state as PackagesLoaded).packagesModel;
                final packages = model.data ?? [];
                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.85,
                  minChildSize: 0.6,
                  maxChildSize: 0.95,
                  builder: (_, scrollCtrl) {
                    return Column(
                      children: [
                        header,
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _AvailabilityAndUSP(
                            durationDays: durationDays,
                            textColor: textColor,
                            chipBg: cardColor,
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: packages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (_, index) {
                              final p = packages[index];
                              final badgeText = _formatBadgeCount(
                                p.listingsCount,
                              );
                              final badgeColors = _badgeColorsFor(index);
                              final savings = _computeSavingsPercent(
                                p.price,
                                p.price,
                              );

                              return ValueListenableBuilder<int?>(
                                valueListenable: selectedIndex,
                                builder: (_, selected, __) {
                                  final isSelected = selected == index;
                                  return _PackageTile(
                                    title: "${p.listingsCount ?? 0} ads",
                                    subTag: (p.name ?? "").isEmpty
                                        ? null
                                        : p.name!,
                                    price: p.price,
                                    mrp: p.normalPrice,
                                    savingsPercent: savings,
                                    badgeText: badgeText,
                                    badgeGradient: badgeColors.gradient,
                                    isSelected: isSelected,
                                    onTap: () {
                                      if (isSelected) {
                                        selectedIndex.value = null;
                                        packageId.value = null;
                                        plan_id.value = null;
                                        price.value = "";
                                      } else {
                                        selectedIndex.value = index;
                                        packageId.value = p.id;
                                        plan_id.value = planId;
                                        price.value = p.price.toString();
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        ValueListenableBuilder<int?>(
                          valueListenable: selectedIndex,
                          builder: (_, selected, __) {
                            if (selected == null)
                              return const SizedBox.shrink();
                            return SafeArea(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                                child: BlocConsumer<PaymentCubit, PaymentStates>(
                                  listener: (context, state) async {
                                    isLoadingNotifier.value =
                                        state is PaymentLoading;
                                    if (state is PaymentCreated) {
                                      final payment_created_data =
                                          state.createPaymentModel;
                                      _openCheckout(
                                        payment_created_data.razorpayKey ?? "",
                                        payment_created_data.amount ?? 0,
                                        payment_created_data.orderId ?? "",
                                      );
                                    } else if (state is PaymentVerified) {
                                      context.pushReplacement('/successfully1');
                                      final plan = await context
                                          .read<UserActivePlanCubit>()
                                          .getUserActivePlansData();
                                      if (plan != null) {
                                        AuthService.setPlanStatus(
                                          plan.goToPlansPage.toString() ?? "",
                                        );
                                        AuthService.setFreePlanStatus(
                                          plan.isFree.toString() ?? "",
                                        );
                                      }
                                    } else if (state is PaymentFailure) {
                                      CustomSnackBar1.show(
                                        context,
                                        state.error,
                                      );
                                    }
                                  },
                                  builder: (context, state) {
                                    return CustomAppButton1(
                                      isLoading: state is PaymentLoading,
                                      text: getPlatformText(
                                        ios: "Pay & Post Ad",
                                        android: "Submit",
                                      ),
                                      onPlusTap: () async {
                                        if (selected == null) {
                                          CustomSnackBar1.show(
                                            context,
                                            "Please select a pack",
                                          );
                                          return;
                                        } else {
                                          // if (userMobileNotifier.value ==
                                          //         "9999999999" &&
                                          //     Platform.isIOS) {
                                          //   CustomSnackBar1.show(
                                          //     context,
                                          //     "You can Buy a Subscription plan from Website",
                                          //   );
                                          //   await launchUrl(
                                          //     Uri.parse(
                                          //       "https://indclassifieds.in/",
                                          //     ),
                                          //     mode: LaunchMode
                                          //         .externalApplication,
                                          //   );
                                          // } else {
                                          final Map<String, dynamic> data = {
                                            "plan_id": plan_id.value,
                                            "package_id": packageId.value,
                                            "price": price.value,
                                          };
                                          context
                                              .read<PaymentCubit>()
                                              .createPayment(data);
                                          await MetaEventTracker.subscribePremium(
                                            plan: plan_id.value.toString(),
                                            price: price.value.toString(),
                                            currency: "Rupee",
                                          );
                                          // }
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String planName;
  final int durationDays;
  const _SheetHeader({required this.planName, required this.durationDays});

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          // Left icon/avatar (🔥 style)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text("🔥", style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  style: AppTextStyles.headlineSmall(
                    textColor,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  "Choose your package",
                  style: AppTextStyles.bodySmall(
                    ThemeHelper.textColor(context).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
    );
  }
}

/// ---------- AVAILABILITY + USP ----------
class _AvailabilityAndUSP extends StatelessWidget {
  final int durationDays;
  final Color textColor;
  final Color chipBg;

  const _AvailabilityAndUSP({
    required this.durationDays,
    required this.textColor,
    required this.chipBg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Availability chip (soft gradient look)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade100, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                "${durationDays > 0 ? durationDays : 7}-days package availability",
                style: AppTextStyles.bodySmall(
                  Colors.black87,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text("🚀"),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Sell 5x faster with Auto-Promoted Listings",
                style: AppTextStyles.bodyMedium(textColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  final String title; // "1 ads"
  final String? subTag; // "STARTER" / "Popular"
  final String? price; // "133.00"
  final String? mrp;
  final int? savingsPercent;
  final String badgeText;
  final List<Color> badgeGradient;
  final VoidCallback onTap;
  final bool isSelected;

  const _PackageTile({
    super.key,
    required this.title,
    required this.subTag,
    required this.price,
    required this.mrp,
    required this.savingsPercent,
    required this.badgeText,
    required this.badgeGradient,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? primarycolor
                  : Colors.black12, // highlight if selected
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? cardColor.withOpacity(0.95) : cardColor,
          ),
          child: Row(
            children: [
              // Badge square with little "+" bubble
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: badgeGradient),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: badgeGradient.last.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? primarycolor : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : SizedBox.shrink(),
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
                      title,
                      style: AppTextStyles.bodyLarge(
                        textColor,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    if (subTag != null && subTag!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          subTag!,
                          style: AppTextStyles.labelSmall(
                            textColor,
                          ).copyWith(letterSpacing: .3),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (mrp != null && mrp!.isNotEmpty) ...[
                        Text(
                          "₹${_money(mrp!)}",
                          style: AppTextStyles.bodySmall(
                            textColor.withOpacity(0.5),
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        "₹${_money(price ?? '0')}",
                        style: AppTextStyles.bodyLarge(
                          textColor,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (savingsPercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A1A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$savingsPercent% Savings",
                        style: AppTextStyles.labelSmall(
                          Colors.white,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- SKELETON ----------
class _SkeletonPackageTile extends StatelessWidget {
  final Color color;
  const _SkeletonPackageTile({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}

/// ---------- HELPERS (formatting & visuals) ----------
String _money(String raw) {
  // raw like "133.00" -> "133"
  final d = double.tryParse(raw) ?? 0;
  final i = d.truncate();
  return (d == i) ? "$i" : d.toStringAsFixed(2);
}

/// If server starts sending MRP, we can compute savings:
int? _computeSavingsPercent(String? mrp, String? price) {
  final m = double.tryParse(mrp ?? "");
  final p = double.tryParse(price ?? "");
  if (m == null || p == null || m <= 0 || p <= 0 || p >= m) return null;
  return (((m - p) / m) * 100).round();
}

/// Badge color cycles (matches 1/3/5/10+ vibe)
class _BadgeColors {
  final List<Color> gradient;
  _BadgeColors(this.gradient);
}

_BadgeColors _badgeColorsFor(int index) {
  switch (index % 4) {
    case 0:
      return _BadgeColors([Colors.blue.shade500, Colors.indigo.shade400]);
    case 1:
      return _BadgeColors([Colors.green.shade500, Colors.teal.shade400]);
    case 2:
      return _BadgeColors([Colors.purple.shade400, Colors.deepPurple.shade300]);
    default:
      return _BadgeColors([Colors.orange.shade500, Colors.deepOrange.shade400]);
  }
}

/// From listings_count -> “1”, “3”, “10+”
String _formatBadgeCount(int? count) {
  if (count == null) return "0";
  return count.toString(); // ✅ always show real count
}

/// —— Helpers ——

class _PlanVisuals {
  final List<Color> gradient;
  final IconData icon;
  _PlanVisuals(this.gradient, this.icon);
}

_PlanVisuals _planVisualsFor(Plans plan) {
  final type = plan.features?.type?.toLowerCase().trim() ?? '';
  switch (type) {
    case 'power':
      return _PlanVisuals([
        Colors.orange.shade400,
        Colors.deepOrange.shade300,
      ], Icons.local_fire_department);
    case 'pro':
      return _PlanVisuals([Colors.purpleAccent, Colors.pinkAccent], Icons.star);
    case 'essential':
    default:
      return _PlanVisuals([
        Colors.blue.shade400,
        Colors.blue.shade300,
      ], Icons.rocket_launch);
  }
}

List<String> _deriveFeatureBullets(Plans plan) {
  final List<String> points = [];

  // Always useful basics from API
  if (plan.durationDays != null && plan.durationDays! > 0) {
    points.add("${plan.durationDays} days validity");
  }
  if ((plan.description ?? "").isNotEmpty) {
    // Keep description short in bullets
    points.add(plan.description!.trim());
  }

  // Type-specific defaults (keeps parity with your earlier static UI)
  final type = plan.features?.type?.toLowerCase().trim() ?? '';
  if (type == 'essential') {
    points.addAll([
      "3 Standard Listings",
      "1 Boosted Post (7 days)",
      "Basic Analytics",
    ]);
  } else if (type == 'power') {
    points.addAll(["Top Category Placement", "Priority Support"]);
  } else if (type == 'pro') {
    points.addAll(["Homepage Spotlight", "Advanced Analytics"]);
  }

  // Dynamic extras from features
  // (the API example shows boosts & highlighted on POWER plan)
  try {
    final raw = plan.features;
    // If you extend Features class later, update here; for now reflect known fields via `toJson`
    final fMap = raw == null ? const <String, dynamic>{} : raw.toJson();
    if (fMap['boosts'] != null) {
      points.add("${fMap['boosts']} Auto Boosts");
    }
    if (fMap['highlighted'] == true) {
      // already shown as tag; add subtle point
      points.add("Featured placement");
    }
  } catch (_) {
    // ignore if structure differs
  }

  // De-duplicate & cap to 6 bullets for neatness
  final seen = <String>{};
  final dedup = <String>[];
  for (final p in points) {
    if (p.trim().isEmpty) continue;
    if (seen.add(p)) dedup.add(p);
    if (dedup.length == 6) break;
  }
  return dedup;
}

class _PlansErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PlansErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: textColor.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
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
