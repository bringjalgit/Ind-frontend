import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/data/cubit/Profile/profile_cubit.dart';
import 'package:classifieds/data/cubit/Profile/profile_states.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Components/CustomAppButton.dart';
import '../../Components/Shimmers.dart';
import '../../data/cubit/theme_cubit.dart';
import '../../services/AuthService.dart';
import '../../services/MetaEventTracker.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/color_constants.dart';
import '../../utils/spinkittsLoader.dart';
import '../../widgets/CommonLoader.dart';
import '../../widgets/DeleteAccountConfirmation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool? _isGuestUser; // ← track guest
  String mobile_number = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final isGuest = await AuthService.isGuest;
    setState(() => _isGuestUser = isGuest);
    // fetch profile ONLY if not guest
    if (!isGuest) {
      // ignore: use_build_context_synchronously
      context.read<ProfileCubit>().getProfileDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    var height = MediaQuery.sizeOf(context).height;

    final mode = context.watch<ThemeCubit>().state;
    final isSystem = mode == AppThemeMode.system;
    final platformIsDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final effectiveDark =
        mode == AppThemeMode.dark || (isSystem && platformIsDark);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Profile', style: AppTextStyles.headlineSmall(textColor)),
      ),
      body: (_isGuestUser == null)
          ? const ProfileShimmer()
          : (_isGuestUser == true)
          // ── Guest view: no API, simple prompt
          ? _GuestProfilePlaceholder(textColor: textColor)
          // ── Logged-in view: original BlocBuilder flow
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: BlocConsumer<ProfileCubit, ProfileStates>(
                listener: (context, state) {
                  if (state is ProfileLoaded) {
                    mobile_number = state.profileModel.data?.mobile ?? "";
                  }
                },
                builder: (context, state) {
                  if (state is ProfileLoading) {
                    return const ProfileShimmer();
                  } else if (state is ProfileLoaded) {
                    final user_data = state.profileModel.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: FutureBuilder(
                            future: AuthService.isSubscribedUser,
                            builder: (context, asyncSnapshot) {
                              final isSubscribedUser =
                                  asyncSnapshot.data ?? false;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer circular frame with specific gradient (purple to blue)
                                  Container(
                                    width: 160,
                                    height: 160,
                                    padding: isSubscribedUser
                                        ? EdgeInsets.all(5)
                                        : EdgeInsets.all(0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF1677FF), // Purple
                                          const Color(0xFFFF16FB), // Blue
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: user_data?.image ?? "",
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  width: 120,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                        placeholder: (context, url) =>
                                            Container(
                                              width: 120,
                                              height: 120,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: spinkits
                                                    .getSpinningLinespinkit(),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              width: 120,
                                              height: 120,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                    "assets/images/profile.png",
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  // Subscribed user badge with specific gradient (pink to orange)
                                  if (isSubscribedUser &&
                                      Platform.isAndroid) ...[
                                    Positioned(
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          // color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(
                                                0xFFFF1493,
                                              ), // Deep Pink
                                              const Color(0xFFFFA500), // Orange
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                        child: const Text(
                                          "Subscribed User",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user_data?.name ?? "",
                          style: AppTextStyles.headlineSmall(textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user_data?.email ?? "",
                          style: AppTextStyles.bodySmall(textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user_data?.mobile ?? "",
                          style: AppTextStyles.bodySmall(textColor),
                        ),
                        const SizedBox(height: 8),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => context.push('/edit_profile_screen'),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _settingsTile(
                          Icons.unsubscribe_outlined,
                          Colors.blue.shade100,
                          Platform.isAndroid ? 'Subscription' : "Buy Packages",
                          isDark,
                          textColor,
                          trailing: Icons.arrow_forward_ios,
                          onTap: () {
                            if (!(mobile_number == "9999999999" &&
                                Platform.isIOS)) {
                              context.push("/plans");
                            } else {
                              context.push("/subscription_plans");
                            }
                          },
                        ),
                        if (!(mobile_number == "9999999999" &&
                            Platform.isIOS)) ...[
                          _settingsTile(
                            Icons.subscriptions,
                            Colors.blue.shade100,
                            Platform.isAndroid
                                ? 'Active Subscription Plans'
                                : "My Orders (Active, Scheduled, Expired)",
                            isDark,
                            textColor,
                            trailing: Icons.arrow_forward_ios,
                            onTap: () => context.push("/active_plans"),
                          ),
                        ],
                        _settingsTile(
                          Icons.favorite,
                          Colors.red.shade100,
                          'Wishlist',
                          isDark,
                          textColor,
                          trailing: Icons.arrow_forward_ios,
                          onTap: () => context.push('/wish_list'),
                        ),
                        if (!(mobile_number == "9999999999" &&
                            Platform.isIOS)) ...[
                          _settingsTile(
                            Icons.receipt_long,
                            Colors.blue.shade100,
                            'Transaction History',
                            isDark,
                            textColor,
                            trailing: Icons.arrow_forward_ios,
                            onTap: () => context.push('/transactions'),
                          ),
                        ],
                        _settingsTile(
                          Icons.dark_mode_outlined,
                          Colors.blue.shade100,
                          'Dark Mode',
                          isDark,
                          textColor,
                          trailing: Icons.arrow_forward_ios,
                          onTap: () {
                            _openThemePicker(context);
                          },
                        ),

                        _settingsTile(
                          Icons.share,
                          Colors.orange.shade100,
                          'Share this App',
                          isDark,
                          textColor,
                          trailing: Icons.arrow_forward_ios,
                          onTap: Platform.isIOS
                              ? () async {
                                  final box =
                                      context.findRenderObject() as RenderBox?;

                                  const appUrl =
                                      'https://apps.apple.com/in/app/ind-classifieds/id6752408949';

                                  await Share.share(
                                    '🚀 Check out **IND Classifieds** — your one-stop destination to buy, sell, and discover great deals near you! 🛒\n\n'
                                    'It’s fast, easy!\n\n'
                                    '👉 Download now on the App Store:\n$appUrl',
                                    subject:
                                        'IND Classifieds – Buy & Sell Locally!',
                                    sharePositionOrigin:
                                        box!.localToGlobal(Offset.zero) &
                                        box.size,
                                  );
                                }
                              : () async {
                                  const appUrl =
                                      'https://play.google.com/store/apps/details?id=com.ind.classifieds';

                                  await Share.share(
                                    '🚀 Check out **IND Classifieds** — your one-stop destination to buy, sell, and discover great deals near you! 🛒\n\n'
                                    'It’s fast, easy!\n\n'
                                    '👉 Download now on Google Play:\n$appUrl',
                                    subject:
                                        'IND Classifieds – Buy & Sell Locally!',
                                  );
                                },
                        ),
                        _settingsTile(
                          Icons.support_agent_outlined,
                          Colors.blue.shade100,
                          'Help & Support',
                          isDark,
                          textColor,
                          trailing: Icons.arrow_forward_ios,
                          onTap: () {
                            context.push("/contact_support");
                          },
                        ),

                        // _settingsTile(
                        //   Icons.star_rate,
                        //   Colors.yellow.shade100,
                        //   'Rate us',
                        //   isDark,
                        //   textColor,
                        //   trailing: Icons.arrow_forward_ios,
                        // ),
                        const SizedBox(height: 20),
                        CustomAppButton1(
                          text: "Log Out",
                          onPlusTap: () => showLogoutDialog(context),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              DeleteAccountConfirmation.showDeleteConfirmationSheet(
                                context,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: textColor.withOpacity(0.4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Delete Account',
                              style: AppTextStyles.titleMedium(textColor),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Center(
                      child: Text(
                        "No data Found!",
                        style: AppTextStyles.bodyMedium(textColor),
                      ),
                    );
                  }
                },
              ),
            ),
    );
  }

  void _openThemePicker(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);
    final activeColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: cardColor,
      barrierColor: Colors.black.withOpacity(isDark ? 0.6 : 0.3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (ctx, mode) {
            void pick(AppThemeMode m) {
              final cubit = ctx.read<ThemeCubit>();
              switch (m) {
                case AppThemeMode.system:
                  cubit.setSystemTheme();
                  break;
                case AppThemeMode.light:
                  cubit.setLightTheme();
                  break;
                case AppThemeMode.dark:
                  cubit.setDarkTheme();
                  break;
              }
              HapticFeedback.selectionClick();
              Navigator.pop(ctx);
            }

            Widget option({
              required IconData icon,
              required String title,
              String? subtitle,
              required AppThemeMode value,
            }) {
              final selected = mode == value;
              return ListTile(
                leading: Icon(
                  icon,
                  color: selected ? activeColor : textColor.withOpacity(0.7),
                ),
                title: Text(title, style: TextStyle(color: textColor)),
                subtitle: subtitle == null
                    ? null
                    : Text(
                        subtitle,
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                trailing: selected
                    ? Icon(Icons.check, color: activeColor)
                    : null,
                onTap: () => pick(value),
              );
            }

            // Helpful subtitle for "System" to show what it currently resolves to
            final platformIsDark =
                MediaQuery.of(context).platformBrightness == Brightness.dark;
            final systemSubtitle =
                'Follows device: ${platformIsDark ? 'Dark' : 'Light'}';

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  option(
                    icon: Icons.brightness_auto_rounded,
                    title: 'Use device theme',
                    subtitle: systemSubtitle,
                    value: AppThemeMode.system,
                  ),
                  option(
                    icon: Icons.wb_sunny_rounded,
                    title: 'Light',
                    value: AppThemeMode.light,
                  ),
                  option(
                    icon: Icons.nightlight_round,
                    title: 'Dark',
                    value: AppThemeMode.dark,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 4.0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: SizedBox(
            width: 300.0,
            height: 230.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Power Icon Positioned Above Dialog
                Positioned(
                  top: -35.0,
                  left: 0.0,
                  right: 0.0,
                  child: Container(
                    width: 70.0,
                    height: 70.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(width: 6.0, color: Colors.white),
                      shape: BoxShape.circle,
                      color: Colors.red.shade100, // Light red background
                    ),
                    child: const Icon(
                      Icons.power_settings_new,
                      size: 40.0,
                      color: Colors.red, // Power icon color
                    ),
                  ),
                ),

                // Dialog Content
                Positioned.fill(
                  top: 30.0, // Moves content down
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 15.0),
                        Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700,
                            color: primarycolor,
                            fontFamily: "roboto_serif",
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        const Text(
                          "Are you sure you want to logout?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black54,
                            fontFamily: "roboto_serif",
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // No Button (Filled)
                            SizedBox(
                              width: 100,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      primarycolor, // Filled button color
                                  foregroundColor: Colors.white, // Text color
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text(
                                  "No",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "roboto_serif",
                                  ),
                                ),
                              ),
                            ),

                            // Yes Button (Outlined)
                            SizedBox(
                              width: 100,
                              height: 45,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await AuthService.logout();
                                  await MetaEventTracker.logout();
                                  context.go("/login");
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primarycolor, // Text color
                                  side: BorderSide(
                                    color: primarycolor,
                                  ), // Border color
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text(
                                  "Yes",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "roboto_serif",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _settingsTile(
    IconData icon,
    Color iconBg,
    String label,
    bool isDark,
    Color textcolor, {
    IconData? trailing,
    String? trailingText,
    bool isSwitch = false,
    VoidCallback? onTap,
    // ✅ add these:
    bool? switchValue,
    ValueChanged<bool>? onSwitchChanged,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                )
              : LinearGradient(
                  colors: [
                    const Color(0xffF9FAFB).withOpacity(0.8),
                    const Color(0xffFFFFFF).withOpacity(0.8),
                  ],
                ),
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconBg,
              child: Icon(icon, size: 18, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium(textcolor)),
            ),
            if (trailingText != null)
              Text(trailingText, style: AppTextStyles.bodySmall(textcolor)),
            if (trailing != null) Icon(trailing, size: 16, color: Colors.grey),

            // ✅ use the provided value & callback
            if (isSwitch)
              Switch(value: switchValue ?? false, onChanged: onSwitchChanged),
          ],
        ),
      ),
    );
  }
}

/// Simple guest-only placeholder widget
class _GuestProfilePlaceholder extends StatelessWidget {
  final Color textColor;
  const _GuestProfilePlaceholder({required this.textColor});

  @override
  Widget build(BuildContext context) {
    final card = ThemeHelper.cardColor(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/nodata/no_data.png', width: 100, height: 100),
            const SizedBox(height: 12),
            Text(
              'You are browsing as a guest',
              style: AppTextStyles.headlineSmall(textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Login to view and edit your profile.',
              style: AppTextStyles.bodyMedium(textColor.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomAppButton1(
              text: 'Go to Login',
              onPlusTap: () {
                context.push('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}


class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          /// PROFILE IMAGE (160 circle)
          shimmerCircle(160, context),

          const SizedBox(height: 16),

          /// NAME
          shimmerText(
            width: 160,
            height: 18,
            context: context,
          ),

          const SizedBox(height: 12),

          /// EMAIL
          shimmerText(
            width: 220,
            context: context,
          ),

          const SizedBox(height: 8),

          /// MOBILE
          shimmerText(
            width: 150,
            context: context,
          ),

          const SizedBox(height: 16),

          /// EDIT PROFILE BUTTON
          shimmerButton(
            140,
            40,
            context,
          ),

          const SizedBox(height: 24),

          /// SETTINGS TILES
          ...List.generate(6, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: shimmerRectangle(
                width: double.infinity,
                height: 56,
                context: context,
                radius: 12,
              ),
            );
          }),

          const SizedBox(height: 20),

          /// LOGOUT BUTTON
          shimmerButton(
            double.infinity,
            48,
            context,
          ),

          const SizedBox(height: 20),

          /// DELETE ACCOUNT BUTTON
          shimmerRectangle(
            width: double.infinity,
            height: 48,
            context: context,
            radius: 8,
          ),
        ],
      ),
    );
  }
}
