import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:classifieds/data/cubit/BoostAd/BoostAdCubit.dart';
import 'package:classifieds/data/cubit/BoostAd/BoostAdStates.dart';
import 'package:classifieds/data/cubit/BoostAdInfo/BoostAdInfoCubit.dart';
import 'package:classifieds/data/cubit/BoostAdInfo/BoostAdInfoStates.dart';
import 'package:classifieds/widgets/CommonLoader.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../data/cubit/MyAds/my_ads_cubit.dart';
import '../services/AuthService.dart';
import '../data/cubit/Profile/profile_repo.dart';
import '../presentation/views/SuccessRecapScreen.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import 'package:classifieds/utils/AppLogger.dart';

class AdBoostDialog extends StatefulWidget {
  final String listing_id;
  const AdBoostDialog({super.key, required this.listing_id});
  @override
  State<AdBoostDialog> createState() => _AdBoostDialogState();
}

class _AdBoostDialogState extends State<AdBoostDialog> {
  late Razorpay _razorpay;

  final ValueNotifier<String?> userNameNotifier = ValueNotifier<String?>("");
  final ValueNotifier<String?> userEmailNotifier = ValueNotifier<String?>("");
  final ValueNotifier<String?> userMobileNotifier = ValueNotifier<String?>("");

  Future<void> getUserDetails() async {
    // Source name/email/mobile from the SERVER (current profile), not the local
    // cache. The cache (AuthService) is written only at login, so after the user
    // changes their email in Edit Profile it goes stale — which made the Razorpay
    // checkout prefill (and Razorpay's own confirmation email) use the OLD email.
    // Fall back to the cache only when the server fetch fails (offline).
    final profileRepo = context.read<ProfileRepo>();
    try {
      final profile = await profileRepo.getProfileDetails();
      final name = profile?.data?.name;
      final email = profile?.data?.email;
      final mobile = profile?.data?.mobile;
      userNameNotifier.value =
          (name != null && name.isNotEmpty) ? name : await AuthService.getName();
      userEmailNotifier.value = (email != null && email.isNotEmpty)
          ? email
          : await AuthService.getEmail();
      userMobileNotifier.value = (mobile != null && mobile.isNotEmpty)
          ? mobile
          : await AuthService.getMobile();
    } catch (_) {
      userNameNotifier.value = await AuthService.getName();
      userEmailNotifier.value = await AuthService.getEmail();
      userMobileNotifier.value = await AuthService.getMobile();
    }
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    getUserDetails();
    context.read<BoostAdInfoCubit>().getBoostAdInfoDetails();
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
    context.read<BoostAdCubit>().verifyPayment(data);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    AppLogger.log("Payment failed: ${response.message}");
    // UPI is async: an error/timeout here does NOT prove the money wasn't
    // debited — the boost can still be captured and activated server-side.
    // Use a neutral message so the user waits instead of paying again.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Payment not confirmed. If any amount was debited, your boost will activate shortly — please don't pay again right away.",
          ),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.log("💼 External wallet selected: ${response.walletName}");
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openCheckout(String key, int amount, String order_id) {
    var options = {
      'key': '$key',
      'amount': amount,
      'currency': 'INR',
      'name': userNameNotifier.value,
      'order_id': '$order_id',
      'description': 'purchase',
      // 5 min: UPI collect needs more than 60s; a short timeout force-closed
      // checkout and reported "failed" while the debit still went through.
      'timeout': 300,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoostAdInfoCubit, BoostAdInfoStates>(
      builder: (context, state) {
        if (state is BoostAdInfoLoading) {
          return Center(child: DottedProgressWithLogo(size: 60, logoSize: 45));
        }
        if (state is! BoostAdInfoLoaded) {
          return const SizedBox.shrink();
        }
        return Dialog(
          backgroundColor: ThemeHelper.cardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Builder(
              builder: (context) {
              final data = state.boostAdModel.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/images/boostimage.png",
                    width: 100,
                    height: 100,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Amount: ₹${data?.amount.toString()}",
                    style: AppTextStyles.bodyLarge(
                      ThemeHelper.textColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "${data?.description}",
                    style: AppTextStyles.bodyLarge(
                      ThemeHelper.textColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  BlocConsumer<BoostAdCubit, BoostAdStates>(
                    listener: (context, state) {
                      if (state is BoostAdPaymentCreated) {
                        final payment_created_data = state.createPaymentModel;
                        _openCheckout(
                          payment_created_data.razorpayKey ?? "",
                          payment_created_data.amount ?? 0,
                          payment_created_data.orderId ?? "",
                        );
                      } else if (state is BoostAdPaymentVerified) {
                        context.read<MyAdsCubit>().getMyAds("approved");
                        context.pop();
                        context.push(
                          '/listing-success',
                          extra: SuccessRecapData.boost(
                            boostAmount: data?.amount?.toString(),
                            boostDescription: data?.description,
                            listingId: widget.listing_id,
                          ),
                        );
                      } else if (state is BoostAdFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.error), backgroundColor: Colors.red),
                        );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is BoostAdLoading;
                      return CustomAppButton1(
                        text: "Continue To Pay",
                        isLoading: isLoading,
                        onPlusTap: () {
                          Map<String, dynamic> data = {
                            "listing_id": widget.listing_id,
                          };
                          context.read<BoostAdCubit>().createPayment(data);
                        },
                      );
                    },
                  ),
                ],
              );
              },
            ),
          ),
        );
      },
    );
  }
}
