import 'package:classifieds/data/cubit/FreeAd/FreeAdCubit.dart';
import 'package:classifieds/data/cubit/FreeAd/FreeAdRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/data/cubit/AddToWishlist/addToWishlistCubit.dart';
import 'package:classifieds/data/cubit/Advertisement/advertisement_cubit.dart';
import 'package:classifieds/data/cubit/Advertisement/advertisement_repo.dart';
import 'package:classifieds/data/cubit/AdvertisementDetails/advertisement_details_cubit.dart';
import 'package:classifieds/data/cubit/Banners/banner_cubit.dart';
import 'package:classifieds/data/cubit/Banners/banner_repository.dart';
import 'package:classifieds/data/cubit/BoostAd/BoostAdCubit.dart';
import 'package:classifieds/data/cubit/BoostAd/BoostAdRepo.dart';
import 'package:classifieds/data/cubit/BoostAdInfo/BoostAdInfoCubit.dart';
import 'package:classifieds/data/cubit/BoostAdInfo/BoostAdInfoRepo.dart';
import 'package:classifieds/data/cubit/Categories/categories_cubit.dart';
import 'package:classifieds/data/cubit/Categories/categories_repository.dart';
import 'package:classifieds/data/cubit/ChatMessages/ChatMessagesCubit.dart';
import 'package:classifieds/data/cubit/ChatMessages/ChatMessagesRepository.dart';
import 'package:classifieds/data/cubit/ChatUserPin/ChatUserPinCubit.dart';
import 'package:classifieds/data/cubit/ChatUsers/ChatUsersCubit.dart';
import 'package:classifieds/data/cubit/ChatUsers/ChatUsersRepo.dart';
import 'package:classifieds/data/cubit/City/city_cubit.dart';
import 'package:classifieds/data/cubit/ContactInfo/ContactInfoCubit.dart';
import 'package:classifieds/data/cubit/ContactInfo/ContactInfoRepository.dart';
import 'package:classifieds/data/cubit/Dashboard/DashboardCubit.dart';
import 'package:classifieds/data/cubit/DeleteAccount/DeleteAccountCubit.dart';
import 'package:classifieds/data/cubit/DeleteAccount/DeleteAccountRepository.dart';
import 'package:classifieds/data/cubit/EmailVerification/EmailVerificationCubit.dart';
import 'package:classifieds/data/cubit/EmailVerification/EmailVerificationRepo.dart';
import 'package:classifieds/data/cubit/Location/location_cubit.dart';
import 'package:classifieds/data/cubit/MyAds/MarkAsListing/mark_as_listing_cubit.dart';
import 'package:classifieds/data/cubit/MyAds/my_ads_cubit.dart';
import 'package:classifieds/data/cubit/MyAds/my_ads_repo.dart';
import 'package:classifieds/data/cubit/NewCategories/new_categories_cubit.dart';
import 'package:classifieds/data/cubit/Packages/packages_cubit.dart';
import 'package:classifieds/data/cubit/Packages/packages_repository.dart';
import 'package:classifieds/data/cubit/Payment/payment_cubit.dart';
import 'package:classifieds/data/cubit/Plans/plans_cubit.dart';
import 'package:classifieds/data/cubit/Plans/plans_repository.dart';
import 'package:classifieds/data/cubit/ProductDetails/product_details_cubit.dart';
import 'package:classifieds/data/cubit/ProductDetails/product_details_repo.dart';
import 'package:classifieds/data/cubit/Products/products_cubit.dart';
import 'package:classifieds/data/cubit/Products/products_repository.dart';
import 'package:classifieds/data/cubit/Profile/profile_cubit.dart';
import 'package:classifieds/data/cubit/Profile/profile_repo.dart';
import 'package:classifieds/data/cubit/Aadhaar/aadhaar_cubit.dart';
import 'package:classifieds/data/cubit/Aadhaar/aadhaar_repo.dart';
import 'package:classifieds/data/cubit/RecoverAccount/recover_account_cubit.dart';
import 'package:classifieds/data/cubit/RecoverAccount/recover_account_repository.dart';
import 'package:classifieds/data/cubit/Register/register_cubit.dart';
import 'package:classifieds/data/cubit/Register/register_repo.dart';
import 'package:classifieds/data/cubit/ReportAd/ReportAdCubit.dart';
import 'package:classifieds/data/cubit/ReportAd/ReportAdRepo.dart';
import 'package:classifieds/data/cubit/Transections/transactions_cubit.dart';
import 'package:classifieds/data/cubit/Transections/transactions_repository.dart';
import 'package:classifieds/data/cubit/UpdateProfile/update_profile_cubit.dart';
import 'package:classifieds/data/cubit/UserActivePlans/user_active_plans_cubit.dart';
import 'package:classifieds/data/cubit/Wishlist/wishlist_cubit.dart';
import 'package:classifieds/data/cubit/Wishlist/wishlist_repository.dart';
import 'package:classifieds/data/cubit/subCategory/sub_category_cubit.dart';
import 'package:classifieds/data/cubit/subCategory/sub_category_repository.dart';
import 'package:classifieds/data/cubit/theme_cubit.dart';
import 'package:classifieds/services/SecureStorageService.dart';
import 'data/bloc/internet_status/internet_status_bloc.dart';
import 'data/cubit/Ad/AstrologyAd/astrology_ad_cubit.dart';
import 'data/cubit/Ad/AstrologyAd/astrology_ad_repo.dart';
import 'data/cubit/Ad/BikesAd/bikes_ad_cubit.dart';
import 'data/cubit/Ad/BikesAd/bikes_ad_repo.dart';
import 'data/cubit/Ad/CarsAd/cars_ad_cubit.dart';
import 'data/cubit/Ad/CarsAd/cars_ad_repo.dart';
import 'data/cubit/Ad/CityRentalsAd/city_rentals_ad_cubit.dart';
import 'data/cubit/Ad/CityRentalsAd/city_rentals_ad_repo.dart';
import 'data/cubit/Ad/CoWorkingAd/co_working_ad_cubit.dart';
import 'data/cubit/Ad/CoWorkingAd/co_working_ad_repo.dart';
import 'data/cubit/Ad/CommercialvehicleAd/commercial_vehicle_ad_cubit.dart';
import 'data/cubit/Ad/CommercialvehicleAd/commercial_vehicle_ad_repo.dart';
import 'data/cubit/Ad/CommonAd/common_ad_cubit.dart';
import 'data/cubit/Ad/CommonAd/common_ad_repo.dart';
import 'data/cubit/Ad/CommunityAd/community_ad_cubit.dart';
import 'data/cubit/Ad/CommunityAd/community_ad_repo.dart';
import 'data/cubit/Ad/EducationAd/education_ad_cubit.dart';
import 'data/cubit/Ad/EducationAd/education_ad_repo.dart';
import 'data/cubit/Ad/JobsAd/jobs_ad_cubit.dart';
import 'data/cubit/Ad/JobsAd/jobs_ad_repo.dart';
import 'data/cubit/Ad/MobileAd/mobile_ad_cubit.dart';
import 'data/cubit/Ad/MobileAd/mobile_ad_repo.dart';
import 'data/cubit/Ad/PetsAd/pets_ad_cubit.dart';
import 'data/cubit/Ad/PetsAd/pets_ad_repo.dart';
import 'data/cubit/Ad/PropertyAd/popperty_ad_cubit.dart';
import 'data/cubit/Ad/PropertyAd/property_ad_repo.dart';
import 'data/cubit/City/city_repository.dart';
import 'data/cubit/LogInWithMobile/login_with_mobile.dart';
import 'data/cubit/LogInWithMobile/login_with_mobile_repository.dart';
import 'data/cubit/MyAds/GetMarkAsListing/get_listing_ad_cubit.dart';
import 'data/cubit/Payment/payment_repository.dart';
import 'data/cubit/PostAdvertisement/post_advertisement_cubit.dart';
import 'data/cubit/PostCategories/categories_cubit.dart';
import 'data/cubit/Products/Product_cubit1.dart';
import 'data/cubit/Products/Product_cubit2.dart';
import 'data/cubit/States/states_cubit.dart';
import 'data/cubit/States/states_repository.dart';
import 'data/cubit/GoogleAuth/google_auth_cubit.dart';
import 'data/cubit/GoogleAuth/google_auth_repo.dart';
import 'data/remote_data_source.dart';

class StateInjector {
  static final repositoryProviders = <RepositoryProvider>[
    RepositoryProvider<RemoteDataSource>(
      create: (context) => RemoteDataSourceImpl(),
    ),
    RepositoryProvider<LogInWithMobileRepository>(
      create: (context) => LogInMobileRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<RegisterRepo>(
      create: (context) =>
          RegisterRepoImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<BannersRepository>(
      create: (context) => BannersRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<CategoriesRepo>(
      create: (context) => CategoriesRepoImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<ProductsRepo>(
      create: (context) =>
          ProductsRepoImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<SubCategoryRepository>(
      create: (context) => SubCategoryRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<SelectCityRepository>(
      create: (context) =>
          SelectCityImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<SelectStateRepository>(
      create: (context) =>
          SelectStatesImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<CommonAdRepository>(
      create: (context) =>
          CommonAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<MobileAdRepository>(
      create: (context) =>
          MobileAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<PropertyAdRepository>(
      create: (context) =>
          PropertyAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<CarsAdRepository>(
      create: (context) =>
          CarsAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<BikeAdRepository>(
      create: (context) =>
          BikeAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<CommercialVehileAdRepository>(
      create: (context) => CommercialVehileAdImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<PetsAdRepository>(
      create: (context) =>
          PetsAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<JobsAdRepository>(
      create: (context) =>
          JobsAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<EducationAdRepository>(
      create: (context) =>
          EducationAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<AstrologyAdRepository>(
      create: (context) =>
          AstrologyAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<CommunityAdRepository>(
      create: (context) =>
          CommunityAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<CityRentalsAdRepository>(
      create: (context) =>
          CityRentalsAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<CoWorkingAdRepository>(
      create: (context) =>
          CoWorkingAdImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),

    RepositoryProvider<WishlistRepository>(
      create: (context) => WishlistRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<PlansRepository>(
      create: (context) => PlansRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<PackagesRepository>(
      create: (context) => PackagesRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<ProductDetailsRepo>(
      create: (context) => ProductDetailsRepoImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<MyAdsRepo>(
      create: (context) =>
          MyAdsRepoImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<ProfileRepo>(
      create: (context) =>
          ProfileRepoImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<AadhaarRepo>(
      create: (context) =>
          AadhaarRepoImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<AdvertisementRepo>(
      create: (context) => AdvertisementRepoImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<PlansRepository>(
      create: (context) => PlansRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<PaymentRepository>(
      create: (context) => PaymentRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<ChatUsersRepo>(
      create: (context) =>
          ChatUsersRepoImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<ChatMessagesRepository>(
      create: (context) => ChatMessagesRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<TransactionsRepository>(
      create: (context) =>
          TransactionsImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<DeleteAccountRepo>(
      create: (context) => DeleteAccountRepoImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<RecoverAccountRepo>(
      create: (context) => RecoverAccountRepoImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<BoostAdRepository>(
      create: (context) => BoostAdRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<BoostAdInfoRepo>(
      create: (context) => BoostAdInfoRepoImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<ReportAdRepo>(
      create: (context) =>
          ReportAdRepoImpl(remoteDataSource: context.read<RemoteDataSource>()),
    ),
    RepositoryProvider<EmailVerificationRepo>(
      create: (context) => EmailVerificationRepoImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<ContactInfoRepository>(
      create: (context) => ContactInfoRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<FreeAdRepository>(
      create: (context) => FreeAdRepositoryImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
    RepositoryProvider<GoogleAuthRepo>(
      create: (context) => GoogleAuthRepoImpl(
        remoteDataSource: context.read<RemoteDataSource>(),
      ),
    ),
  ];

  static List<BlocProvider> blocProviders(ThemeCubit themeCubit) => [
    BlocProvider<InternetStatusBloc>(create: (context) => InternetStatusBloc()),
    BlocProvider<ThemeCubit>.value(value: themeCubit),
    BlocProvider<LocationCubit>(create: (context) => LocationCubit()),
    BlocProvider<LogInwithMobileCubit>(
      create: (context) =>
          LogInwithMobileCubit(context.read<LogInWithMobileRepository>()),
    ),
    BlocProvider<EmailVerificationCubit>(
      create: (context) =>
          EmailVerificationCubit(context.read<EmailVerificationRepo>()),
    ),
    BlocProvider<RegisterCubit>(
      create: (context) => RegisterCubit(context.read<RegisterRepo>()),
    ),
    BlocProvider<BannerCubit>(
      create: (context) => BannerCubit(context.read<BannersRepository>()),
    ),
    BlocProvider<CategoriesCubit>(
      create: (context) => CategoriesCubit(context.read<CategoriesRepo>()),
    ),
    BlocProvider<PostCategoriesCubit>(
      create: (context) => PostCategoriesCubit(context.read<CategoriesRepo>()),
    ),
    BlocProvider<NewCategoriesCubit>(
      create: (context) => NewCategoriesCubit(context.read<CategoriesRepo>()),
    ),
    BlocProvider<ProductsCubit>(
      create: (context) => ProductsCubit(context.read<ProductsRepo>()),
    ),

    BlocProvider<UserActivePlanCubit>(
      create: (context) => UserActivePlanCubit(context.read<PlansRepository>()),
    ),
    BlocProvider<SubCategoryCubit>(
      create: (context) =>
          SubCategoryCubit(context.read<SubCategoryRepository>()),
    ),
    BlocProvider<SelectStatesCubit>(
      create: (context) =>
          SelectStatesCubit(context.read<SelectStateRepository>()),
    ),
    BlocProvider<SelectCityCubit>(
      create: (context) =>
          SelectCityCubit(context.read<SelectCityRepository>()),
    ),
    BlocProvider<CommonAdCubit>(
      create: (context) => CommonAdCubit(context.read<CommonAdRepository>()),
    ),
    BlocProvider<PropertyAdCubit>(
      create: (context) =>
          PropertyAdCubit(context.read<PropertyAdRepository>()),
    ),
    BlocProvider<CarsAdCubit>(
      create: (context) => CarsAdCubit(context.read<CarsAdRepository>()),
    ),
    BlocProvider<BikesAdCubit>(
      create: (context) => BikesAdCubit(context.read<BikeAdRepository>()),
    ),
    BlocProvider<CommercialVehileAdCubit>(
      create: (context) =>
          CommercialVehileAdCubit(context.read<CommercialVehileAdRepository>()),
    ),
    BlocProvider<PetsAdCubit>(
      create: (context) => PetsAdCubit(context.read<PetsAdRepository>()),
    ),
    BlocProvider<JobsAdCubit>(
      create: (context) => JobsAdCubit(context.read<JobsAdRepository>()),
    ),
    BlocProvider<EducationAdCubit>(
      create: (context) =>
          EducationAdCubit(context.read<EducationAdRepository>()),
    ),
    BlocProvider<AstrologyAdCubit>(
      create: (context) =>
          AstrologyAdCubit(context.read<AstrologyAdRepository>()),
    ),
    BlocProvider<CommunityAdCubit>(
      create: (context) =>
          CommunityAdCubit(context.read<CommunityAdRepository>()),
    ),
    BlocProvider<CityRentalsAdCubit>(
      create: (context) =>
          CityRentalsAdCubit(context.read<CityRentalsAdRepository>()),
    ),
    BlocProvider<CoWorkingAdCubit>(
      create: (context) =>
          CoWorkingAdCubit(context.read<CoWorkingAdRepository>()),
    ),
    BlocProvider<MobileAdCubit>(
      create: (context) => MobileAdCubit(context.read<MobileAdRepository>()),
    ),
    BlocProvider<WishlistCubit>(
      create: (context) => WishlistCubit(context.read<WishlistRepository>()),
    ),
    BlocProvider<AddToWishlistCubit>(
      create: (context) =>
          AddToWishlistCubit(context.read<WishlistRepository>()),
    ),
    BlocProvider<PlansCubit>(
      create: (context) => PlansCubit(context.read<PlansRepository>()),
    ),
    BlocProvider<PackagesCubit>(
      create: (context) => PackagesCubit(context.read<PackagesRepository>()),
    ),
    BlocProvider<ProductDetailsCubit>(
      create: (context) =>
          ProductDetailsCubit(context.read<ProductDetailsRepo>()),
    ),
    BlocProvider<MyAdsCubit>(
      create: (context) => MyAdsCubit(context.read<MyAdsRepo>()),
    ),
    BlocProvider<MarkAsListingCubit>(
      create: (context) => MarkAsListingCubit(context.read<MyAdsRepo>()),
    ),
    BlocProvider<GetListingAdCubit>(
      create: (context) => GetListingAdCubit(context.read<MyAdsRepo>()),
    ),
    BlocProvider<ProfileCubit>(
      create: (context) => ProfileCubit(context.read<ProfileRepo>()),
    ),
    BlocProvider<AadhaarCubit>(
      create: (context) => AadhaarCubit(context.read<AadhaarRepo>()),
    ),
    BlocProvider<UpdateProfileCubit>(
      create: (context) => UpdateProfileCubit(context.read<ProfileRepo>()),
    ),
    BlocProvider<AdvertisementsCubit>(
      create: (context) =>
          AdvertisementsCubit(context.read<AdvertisementRepo>()),
    ),
    BlocProvider<PostAdvertisementsCubit>(
      create: (context) =>
          PostAdvertisementsCubit(context.read<AdvertisementRepo>()),
    ),
    BlocProvider<AdvertisementDetailsCubit>(
      create: (context) =>
          AdvertisementDetailsCubit(context.read<AdvertisementRepo>()),
    ),
    BlocProvider<PaymentCubit>(
      create: (context) => PaymentCubit(context.read<PaymentRepository>()),
    ),
    BlocProvider<ChatUsersCubit>(create: (context) => ChatUsersCubit(remoteDataSource: RemoteDataSourceImpl())),

    BlocProvider<ChatMessagesCubit>(
      create: (context) =>
          ChatMessagesCubit(context.read<ChatMessagesRepository>()),
    ),
    BlocProvider<ProductsCubit1>(
      create: (context) => ProductsCubit1(context.read<ProductsRepo>()),
    ),
    BlocProvider<ProductsCubit2>(
      create: (context) => ProductsCubit2(context.read<ProductsRepo>()),
    ),
    BlocProvider<TransactionCubit>(
      create: (context) =>
          TransactionCubit(context.read<TransactionsRepository>()),
    ),
    BlocProvider<DeleteAccountCubit>(
      create: (context) =>
          DeleteAccountCubit(context.read<DeleteAccountRepo>()),
    ),
    BlocProvider<RecoverAccountCubit>(
      create: (context) =>
          RecoverAccountCubit(context.read<RecoverAccountRepo>()),
    ),
    BlocProvider<BoostAdCubit>(
      create: (context) => BoostAdCubit(context.read<BoostAdRepository>()),
    ),
    BlocProvider<BoostAdInfoCubit>(
      create: (context) => BoostAdInfoCubit(context.read<BoostAdInfoRepo>()),
    ),
    BlocProvider<ReportAdCubit>(
      create: (context) => ReportAdCubit(context.read<ReportAdRepo>()),
    ),
    BlocProvider<ContactInfoCubit>(
      create: (context) =>
          ContactInfoCubit(context.read<ContactInfoRepository>()),
    ),
    BlocProvider<ChatUserPinCubit>(
      create: (context) => ChatUserPinCubit(context.read<ChatUsersRepo>()),
    ),
    BlocProvider<FreeAdCubit>(
      create: (context) => FreeAdCubit(context.read<FreeAdRepository>()),
    ),
    BlocProvider<GoogleAuthCubit>(
      create: (context) => GoogleAuthCubit(context.read<GoogleAuthRepo>()),
    ),
    BlocProvider<DashboardCubit>(
      create: (context) => DashboardCubit(
        bannersCubit: context.read<BannerCubit>(),
        newCategoriesCubit: context.read<NewCategoriesCubit>(),
        categoryCubit: context.read<CategoriesCubit>(),
        productsCubit: context.read<ProductsCubit>(),
      ),
    ),
  ];
}
