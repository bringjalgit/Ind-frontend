import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/presentation/views/Home.dart';
import 'package:classifieds/presentation/views/ProfileScreen.dart';
import 'package:classifieds/services/AuthService.dart';
import 'package:classifieds/theme/AppTextStyles.dart';
import 'package:classifieds/theme/app_colors.dart';
import 'package:classifieds/utils/AppLogger.dart';
import 'package:classifieds/utils/color_constants.dart';
import 'package:classifieds/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart' as OpenAppSettings;

import '../../data/bloc/internet_status/internet_status_bloc.dart';
import '../../data/cubit/Location/location_cubit.dart';
import '../../data/cubit/Location/location_state.dart';
import '../../data/cubit/UserActivePlans/user_active_plans_cubit.dart';
import '../../data/cubit/theme_cubit.dart';
import '../../services/NotificationService.dart';
import '../../services/SocketService.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/DeepLinkMapper.dart';
import '../../utils/NotificationIntent.dart';
import 'AddsScreen.dart';
import 'UserListScreen.dart';

class Dashboard extends StatefulWidget {
  final int initialTab;
  const Dashboard({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late PageController pageController;
  int _selectedIndex = 0;
  bool isLocationSheetShown = false;

  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    pageController = PageController(initialPage: _selectedIndex);
    getData();

    // ✅ correct call
    NotificationService.instance.requestPermissions();
    context.read<LocationCubit>().checkLocationPermission();
    initDeepLinks(); // start deep link handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final toChat = NotificationIntent.consumePendingChat();
      if (toChat != null && toChat.isNotEmpty && mounted) {
        context.push('/chat?receiverId=$toChat');
      }
    });
  }

  Future<void> initDeepLinks() async {
    final appLinks = AppLinks();
    debugPrint('DeepLink: initDeepLinks started');
    try {
      final initialUri = await appLinks.getInitialLink();
      debugPrint('DeepLink: getInitialLink -> $initialUri');
      final loc = DeepLinkMapper.toLocation(initialUri);
      if (loc != null) {
        debugPrint('DeepLink: navigating to $loc');
        context.push(loc);
      } else {
        debugPrint('DeepLink: no mapped location for $initialUri');
      }
    } catch (e) {
      debugPrint('DeepLink: Initial app link error: $e');
    }

    // 2) Handle links while the app is running
    // _linkSubscription = appLinks.uriLinkStream.listen((uri) {
    //   debugPrint('DeepLink: uriLinkStream -> $uri');
    //   final loc = DeepLinkMapper.toLocation(uri);
    //   if (loc != null) {
    //     debugPrint('DeepLink: navigating to $loc');
    //     context.push(loc);
    //   } else {
    //     debugPrint('DeepLink: no mapped location for $uri');
    //   }
    // }, onError: (e) => debugPrint('DeepLink: Link stream error: $e'));
  }

  @override
  void dispose() {
    debugPrint('DeepLink: dispose, cancelling subscription');
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> getData() async {
    final isGuest = await AuthService.isGuest;
    mobile_no = await AuthService.getMobile() ?? "";
    AppLogger.info("Mobile Number from Dashboard :${mobile_no}");
    if (!isGuest) {
      final plan = await context
          .read<UserActivePlanCubit>()
          .getUserActivePlansData();
      if (plan != null) {
        AuthService.setPlanStatus(plan.goToPlansPage.toString() ?? "");
        AuthService.setFreePlanStatus(plan.isFree.toString() ?? "");
        AuthService.setSubscribeStatus(
          plan.plans?.length != 0 ? "true" : "false" ?? "",
        );
      }
      final userId = await AuthService.getId();
      SocketService.connect(userId ?? "");
    }
  }

  void onItemTapped(int index) {
    pageController.jumpToPage(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, mode) {
        final cardColor = ThemeHelper.cardColor(context);
        return WillPopScope(
          onWillPop: () async {
            SystemNavigator.pop();
            return false;
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: BlocListener<InternetStatusBloc, InternetStatusState>(
              listener: (context, state) {
                if (state is InternetStatusLostState) {
                  context.push('/no_internet');
                } else if (state is InternetStatusBackState) {
                  // context.pop();
                  // AppLogger.info("called this");
                }
              },
              child: BlocListener<LocationCubit, LocationState>(
                listener: (context, state) {
                  if (state is LocationPermissionDenied ||
                      state is LocationServiceDisabled) {
                    showLocationBottomSheet(context);
                  } else if (state is LocationLoaded) {
                    address = state.locationName;
                    latlng = state.latlng;
                    // ✅ Close bottom sheet if showing
                    if (isLocationSheetShown) {
                      Navigator.of(context).pop(); // closes the bottom sheet
                      isLocationSheetShown = false; // reset flag
                    }
                  }
                },
                child: PageView(
                  controller: pageController,
                  onPageChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedIndex = value);
                  },
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    HomeScreen(),
                    AdsScreen(),
                    UserListScreen(),
                    ProfileScreen(),
                  ],
                ),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: Container(
                width: 50,
                height: 65,
                margin: const EdgeInsets.only(top: 40),
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 6,
                  children: [
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: FloatingActionButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        onPressed: () {
                          context.push("/category");
                          // context.read<LocationCubit>().checkLocationPermission();
                        },
                        child: const Icon(
                          Icons.add,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      "Sell",
                      style: AppTextStyles.titleSmall(AppColors.unselect),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, "Home", 0),
                  _buildNavItem(Icons.archive, "My Ads", 1),
                  const SizedBox(width: 40), // space for FAB
                  _buildNavItem(Icons.chat, "Chat", 2),
                  _buildNavItem(Icons.person, "Profile", 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? AppColors.primary : AppColors.unselect,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primary : AppColors.unselect,
            ),
          ),
        ],
      ),
    );
  }

  void showLocationBottomSheet(
    BuildContext context, {
    bool userInitiated = false,
  }) {
    if (isLocationSheetShown) return;

    isLocationSheetShown = true;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext bottomSheetContext) {
        return BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            bool isLoading = state is LocationLoading;
            bool isServiceDisabled = state is LocationServiceDisabled;
            bool isDenied = state is LocationPermissionDenied;
            bool isForeverDenied = state is LocationPermissionDeniedForever;

            String title;
            String description;

            if (isServiceDisabled) {
              title = 'Location Services Disabled';
              description =
                  'Please enable location services to see nearby listings.';
            } else if (isForeverDenied && userInitiated) {
              title = 'Permission Denied Permanently';
              description =
                  'To show listings near you, please enable location access from your device settings.';
            } else if (isDenied) {
              title = 'Location Access Needed';
              description =
                  'You can continue without enabling location, but nearby listings may not be shown.';
            } else {
              title = 'Allow Location Access';
              description =
                  'IND Classifieds uses your location to show listings near you for a personalized experience.';
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey[50]!],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: "lexend",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                      fontFamily: "lexend",
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isForeverDenied && userInitiated)
                        ElevatedButton(
                          onPressed: () async {
                            await OpenAppSettings.openAppSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Open Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: "lexend",
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context
                                      .read<LocationCubit>()
                                      .requestLocationPermission();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    fontFamily: "lexend",
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      isLocationSheetShown = false;
    });
  }

  // void showLocationBottomSheet(BuildContext context) {
  //   if (isLocationSheetShown) return;
  //
  //   isLocationSheetShown = true;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isDismissible: true,
  //     enableDrag: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //     ),
  //     backgroundColor: Colors.white,
  //     builder: (BuildContext bottomSheetContext) {
  //       return BlocBuilder<LocationCubit, LocationState>(
  //         builder: (context, state) {
  //           bool isLoading = state is LocationLoading;
  //           bool isServiceDisabled = state is LocationServiceDisabled;
  //           bool isDenied = state is LocationPermissionDenied;
  //           bool isForeverDenied = state is LocationPermissionDeniedForever;
  //
  //           String title;
  //           String description;
  //
  //           if (isServiceDisabled) {
  //             title = 'Location Services Disabled';
  //             description =
  //                 'Please enable location services on your device to see listings near you.';
  //           } else if (isForeverDenied) {
  //             title = 'Permission Denied Permanently';
  //             description =
  //                 'To show listings near you, please enable location access from device settings.';
  //           } else if (isDenied) {
  //             title = 'Location Access Needed';
  //             description =
  //                 'IND Classifieds uses your location to show listings near you. You can continue using the app without enabling location, but nearby listings may not be shown.';
  //           } else {
  //             title = 'Allow Location Access';
  //             description =
  //                 'IND Classifieds uses your location to show listings near you. This helps you discover items, services, and deals in your area for a personalized experience.';
  //           }
  //
  //           return Container(
  //             padding: const EdgeInsets.all(24),
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 begin: Alignment.topCenter,
  //                 end: Alignment.bottomCenter,
  //                 colors: [Colors.white, Colors.grey[50]!],
  //               ),
  //               borderRadius: const BorderRadius.vertical(
  //                 top: Radius.circular(24),
  //               ),
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Center(
  //                   child: Container(
  //                     width: 40,
  //                     height: 4,
  //                     margin: const EdgeInsets.only(bottom: 16),
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey[300],
  //                       borderRadius: BorderRadius.circular(2),
  //                     ),
  //                   ),
  //                 ),
  //                 Row(
  //                   children: [
  //                     Container(
  //                       padding: const EdgeInsets.all(8),
  //                       decoration: BoxDecoration(
  //                         color: AppColors.primary.withOpacity(0.5),
  //                         shape: BoxShape.circle,
  //                       ),
  //                       child: Icon(
  //                         Icons.location_on,
  //                         color: AppColors.primary,
  //                         size: 24,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 12),
  //                     Expanded(
  //                       child: Text(
  //                         title,
  //                         style: const TextStyle(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.black87,
  //                           fontFamily: "lexend",
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 16),
  //                 Text(
  //                   description,
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: Colors.grey[600],
  //                     height: 1.5,
  //                     fontFamily: "lexend",
  //                   ),
  //                 ),
  //                 const SizedBox(height: 24),
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.end,
  //                   children: [
  //                     if (isForeverDenied)
  //                       ElevatedButton(
  //                         onPressed: () async {
  //                           await OpenAppSettings.openAppSettings(); // Open system settings
  //                         },
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: AppColors.primary,
  //                           foregroundColor: Colors.white,
  //                           padding: const EdgeInsets.symmetric(
  //                             horizontal: 16,
  //                             vertical: 12,
  //                           ),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                           elevation: 0,
  //                         ),
  //                         child: const Text(
  //                           'Open Settings',
  //                           style: TextStyle(
  //                             fontWeight: FontWeight.w600,
  //                             fontSize: 14,
  //                             fontFamily: "lexend",
  //                           ),
  //                         ),
  //                       )
  //                     else
  //                       ElevatedButton(
  //                         onPressed: isLoading
  //                             ? null
  //                             : () {
  //                                 context
  //                                     .read<LocationCubit>()
  //                                     .requestLocationPermission();
  //                               },
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: AppColors.primary,
  //                           foregroundColor: Colors.white,
  //                           padding: const EdgeInsets.symmetric(
  //                             horizontal: 16,
  //                             vertical: 12,
  //                           ),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                           elevation: 0,
  //                         ),
  //                         child: isLoading
  //                             ? const SizedBox(
  //                                 width: 20,
  //                                 height: 20,
  //                                 child: CircularProgressIndicator(
  //                                   strokeWidth: 2,
  //                                   valueColor: AlwaysStoppedAnimation(
  //                                     Colors.white,
  //                                   ),
  //                                 ),
  //                               )
  //                             : const Text(
  //                                 'Continue',
  //                                 style: TextStyle(
  //                                   fontWeight: FontWeight.w600,
  //                                   fontSize: 14,
  //                                   fontFamily: "lexend",
  //                                   color: Colors.white,
  //                                 ),
  //                               ),
  //                       ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 16),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   ).whenComplete(() {
  //     isLocationSheetShown = false;
  //   });
  // }
}
