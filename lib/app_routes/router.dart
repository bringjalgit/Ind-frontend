import 'dart:io';
import 'dart:ui';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/presentation/authentication/EmailLoginscreen.dart';
import 'package:classifieds/presentation/authentication/RegisterUserDetailsScreen.dart';
import 'package:classifieds/presentation/views/ActivePlansScreen.dart';
import 'package:classifieds/presentation/views/AdvertisementScreen.dart';
import 'package:classifieds/presentation/views/ContactSupportScreen.dart';
import 'package:classifieds/presentation/views/PlansScreen.dart';
import 'package:classifieds/presentation/PostAdds/CommunityAdScreen.dart';
import 'package:classifieds/presentation/PostAdds/EducationalAd.dart';
import 'package:classifieds/presentation/views/ProductDetailsScreen.dart';
import 'package:classifieds/presentation/views/RecoverAccountScreen.dart';
import 'package:classifieds/presentation/views/SearchScreen.dart';
import 'package:classifieds/presentation/views/SplashScreen.dart';
import 'package:classifieds/presentation/views/SubCategoriesScreen.dart';
import 'package:classifieds/presentation/views/SubscriptionScreen.dart';
import 'package:classifieds/presentation/views/SuccessScreen1.dart';
import 'package:classifieds/utils/constants.dart';
import '../Components/NoInternet.dart';
import '../data/cubit/Chat/private_chat_cubit.dart';
import '../model/CategoryModel.dart';
import '../presentation/PostAdds/AstrologyAd.dart';
import '../presentation/PostAdds/BikeAd.dart';
import '../presentation/PostAdds/CarsAd.dart';
import '../presentation/PostAdds/CityRentalAd.dart';
import '../presentation/PostAdds/CoWorkSpaceAd.dart';
import '../presentation/PostAdds/CommercialVechileAd.dart';
import '../presentation/PostAdds/CommonAd.dart';
import '../presentation/PostAdds/JobAd.dart';
import '../presentation/PostAdds/MobileAd.dart';
import '../presentation/PostAdds/PetAdScreen.dart';
import '../presentation/PostAdds/PropertiesAdScreen.dart';

import 'package:classifieds/presentation/views/ProductsListScreen.dart';
import '../presentation/authentication/LoginScreen.dart';
import '../presentation/authentication/OTPScreen.dart';
import '../presentation/views/BlockedAccountScreen.dart';
import '../presentation/views/ChatScreen.dart';
import '../presentation/views/EditProfile.dart';
import '../presentation/views/FavouritesScreen.dart';
import '../presentation/views/FilterScreen.dart';
import '../presentation/views/NotificationScreen.dart';
import '../presentation/views/CategoryScreen.dart';
import '../presentation/views/PostAdvertisementScreen.dart';
import '../presentation/views/ProfileScreen.dart';
import '../presentation/views/SelectSubCategory.dart';
import '../presentation/views/SuccessScreen.dart';
import '../presentation/views/TransactionsScreen.dart';
import '../presentation/views/dashboard.dart';
import '../services/AuthService.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorKey,
  // debugLogDiagnostics: true,
  overridePlatformDefaultLocation: true,
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(Splashscreen(), state),
    ),
    GoRoute(
      path: '/no_internet',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(Nointernet(), state);
      },
    ),
    GoRoute(
      path: '/contact_support',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(ContactSupportScreen(), state);
      },
    ),
    GoRoute(
      path: '/active_plans',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(ActivePlansScreen(), state);
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final receiverId =
            state.uri.queryParameters['receiverId'] ?? "";

        final listingId =
            state.uri.queryParameters['listingId'] ?? "0";

        final listingTitle =
        Uri.decodeComponent(
          state.uri.queryParameters['listingTitle'] ?? "",
        );

        return FutureBuilder<String?>(
          future: AuthService.getId(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final currentUserId = snapshot.data ?? "";

            return BlocProvider(
              create: (_) => PrivateChatCubit(
                currentUserId,
                receiverId,
                listingId, // 🔥 REQUIRED NOW
              ),
              child: ChatScreen(
                currentUserId: currentUserId,
                receiverId: receiverId,
                listingId: listingId,
                listingTitle: listingTitle,
              ),
            );
          },
        );
      },
    ),

    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(Dashboard(), state),
    ),
    GoRoute(
      path: '/plans',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(PlansScreen(), state),
    ),
    GoRoute(
      path: '/subscription_plans',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(SubscriptionScreen(), state),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(NotificationScreen(), state),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(Loginscreen(), state),
    ),
    GoRoute(
      path: '/email_login',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(EmailLoginscreen(), state),
    ),
    GoRoute(
      path: '/otp',
      pageBuilder: (context, state) {
        final mobile = state.uri.queryParameters['mobile'] ?? "";
        final email = state.uri.queryParameters['email'] ?? "";
        return buildSlideTransitionPage(
          Otpscreen(mobile: mobile, email: email),
          state,
        );
      },
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) {
        final from = state.uri.queryParameters['from'] ?? "";
        return buildSlideTransitionPage(
          RegisterUserDetailsScreen(from: from),
          state,
        );
      },
    ),
    GoRoute(
      path: '/wish_list',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(WishlistListScreen(), state),
    ),
    GoRoute(
      path: '/transactions',
      pageBuilder: (context, state) =>
          buildSlideTransitionPage(TransactionsScreen(), state),
    ),
    GoRoute(
      path: '/search_screen',
      pageBuilder: (context, state) {
        final searchText = state.extra as String? ?? '';
        return buildSlideTransitionPage(
          SearchScreen(search_text: searchText),
          state,
        );
      },
    ),
    GoRoute(
      path: '/sub_categories',
      pageBuilder: (context, state) {
        // Try to get CategoriesList from extra
        final categoriesList = state.extra is CategoriesList
            ? state.extra as CategoriesList
            : null;

        return buildSlideTransitionPage(
          SubCategoriesScreen(categoriesList: categoriesList),
          state,
        );
      },
    ),

    GoRoute(
      path: '/select_sub_categories',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['categoryId'] ?? "";
        final categoryName = state.uri.queryParameters['categoryName'] ?? "";
        return buildSlideTransitionPage(
          SelectSubCategory(categoryId: categoryId, categoryName: categoryName),
          state,
        );
      },
    ),
    GoRoute(
      path: '/products_list',
      pageBuilder: (context, state) {
        final sub_categoryId =
            state.uri.queryParameters['sub_categoryId'] ?? "";
        final subCategoryname =
            state.uri.queryParameters['subCategoryname'] ?? "";
        return buildSlideTransitionPage(
          ProductsListScreen(
            subCategoryId: sub_categoryId,
            subCategoryname: subCategoryname,
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/category/:slug',
      redirect: (ctx, st) {
        final slug = st.pathParameters['slug'];
        final listingId = st.uri.queryParameters['detailId'];

        if (listingId == null || slug == null) return null;

        String? subId;
        final match = RegExp(r'-(\d+)$').firstMatch(slug);
        if (match != null) subId = match.group(1);

        if (subId == null) return null;

        return '/products_details?listingId=$listingId&subcategory_id=$subId';
      },
    ),

    GoRoute(
      path: '/products_details',
      pageBuilder: (context, state) {
        // read from query params
        final listingIdStr = state.uri.queryParameters['listingId'];
        final subcategory_idstr = state.uri.queryParameters['subcategory_id'];

        final listingId = int.tryParse(listingIdStr ?? '') ?? 0;
        final subcategory_id = int.tryParse(subcategory_idstr ?? '') ?? 0;

        return buildSlideTransitionPage(
          ProductDetailsScreen(
            listingId: listingId,
            subcategory_id: subcategory_id,
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/successfully',
      pageBuilder: (context, state) {
        final nextRoute = state.uri.queryParameters['next'] ?? "";
        final title = state.uri.queryParameters['title'] ?? "";
        return buildSlideTransitionPage(
          SuccessScreen(title: title, nextRoute: nextRoute),
          state,
        );
      },
    ),

    GoRoute(
      path: '/recover_account',
      pageBuilder: (context, state) {
        final user_id = state.uri.queryParameters['user_id'] ?? "";
        return buildSlideTransitionPage(
          RecoverAccountScreen(user_id: user_id),
          state,
        );
      },
    ),

    GoRoute(
      path: '/blocked_account',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(BlockedAccountScreen(), state);
      },
    ),

    GoRoute(
      path: '/successfully1',
      pageBuilder: (context, state) {
        final nextRoute = state.uri.queryParameters['next'] ?? "";
        return buildSlideTransitionPage(
          SuccessScreen1(nextRoute: nextRoute),
          state,
        );
      },
    ),
    GoRoute(
      path: '/common_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideTransitionPage(
          CommonAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/property_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";

        return buildSlideTransitionPage(
          PropertiesAdScreen(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/profile_screen',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(ProfileScreen(), state);
      },
    ),
    GoRoute(
      path: '/edit_profile_screen',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(EditProfile(), state);
      },
    ),
    GoRoute(
      path: '/category',
      pageBuilder: (context, state) =>
          buildSlideFromBottomPage(CategoryScreen(), state),
    ),

    GoRoute(
      path: '/job_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          JobsAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/bikes_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          BikeAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/cars_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          CarsAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/commercial_vechile_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          CommercialVehicleAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/pets_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          PetAdScreen(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/education_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";

        return buildSlideFromBottomPage(
          EducationalAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/mobile_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          MobileAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/astrology_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          AstrologyAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/city_rental_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          CityRentalsAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/co_working_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          CoWorkingSpaceAd(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/community_ad',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['catId'] ?? "";
        final categoryName = state.uri.queryParameters['CatName'] ?? "";
        final SubCategoryName = state.uri.queryParameters['SubCatName'] ?? "";
        final subCatId = state.uri.queryParameters['subCatId'] ?? "";
        final editId = state.uri.queryParameters['editId'] ?? "";
        return buildSlideFromBottomPage(
          CommunityAdScreen(
            catId: categoryId,
            CatName: categoryName,
            subCatId: subCatId,
            SubCatName: SubCategoryName,
            editId: editId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/advertisements',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(AdvertisementScreen(), state);
      },
    ),
    GoRoute(
      path: '/post_advertisements',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(PostAdvertisementScreen(), state);
      },
    ),
    GoRoute(
      path: '/filter',
      pageBuilder: (context, state) {
        return buildSlideTransitionPage(FilterScreen(), state);
      },
    ),
  ],
);

Page<dynamic> buildSlideTransitionPage(Widget child, GoRouterState state) {
  if (Platform.isIOS) {
    // Use default Cupertino transition on iOS
    return CupertinoPage(key: state.pageKey, child: child);
  }

  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

Page<dynamic> buildSlideFromBottomPage(Widget child, GoRouterState state) {
  if (Platform.isIOS) {
    // Use default Cupertino transition on iOS
    return CupertinoPage(key: state.pageKey, child: child);
  }
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // bottom to top
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
