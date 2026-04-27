import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:classifieds/data/cubit/Ad/PropertyAd/popperty_ad_cubit.dart';
import 'package:classifieds/data/cubit/Ad/PropertyAd/property_ad_states.dart';
import '../../data/cubit/FreeAd/FreeAdCubit.dart';
import '../../data/cubit/Location/location_cubit.dart';
import '../../data/cubit/MyAds/GetMarkAsListing/get_listing_ad_cubit.dart';
import '../../data/cubit/MyAds/MarkAsListing/mark_as_listing_cubit.dart';
import '../../data/cubit/MyAds/MarkAsListing/mark_as_listing_state.dart';
import '../../data/cubit/Profile/profile_cubit.dart';
import '../../data/cubit/States/states_cubit.dart';
import '../../data/cubit/States/states_repository.dart';
import '../../data/cubit/UserActivePlans/user_active_plans_cubit.dart';
import '../../services/AuthService.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../theme/app_colors.dart';
import '../../utils/AppLogger.dart';
import '../../utils/ImagePickerHelper.dart';
import '../../utils/constants.dart';
import '../../utils/place_picker_bottomsheet.dart';
import '../../utils/planhelper.dart';
import '../../widgets/CommonLoader.dart';
import '../../widgets/CommonTextField.dart';
import '../../data/remote_data_source.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../Components/CustomAppButton.dart';
import '../../Components/CustomSnackBar.dart';
import '../../Components/CutomAppBar.dart';
import '../../Components/ShakeWidget.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/ImageUtils.dart';
import '../../utils/color_constants.dart';
import '../../widgets/CommonWrapChipSelector.dart';
import '../../widgets/SelectCityBottomSheet.dart';
import '../../widgets/SelectStateBottomSheet.dart';
import '../views/SuccessRecapScreen.dart';

class PropertiesAdScreen extends StatefulWidget {
  final String catId;
  final String CatName;
  final String SubCatName;
  final String subCatId;
  final String editId;

  const PropertiesAdScreen({
    super.key,
    required this.catId,
    required this.CatName,
    required this.SubCatName,
    required this.subCatId,
    required this.editId,
  });

  @override
  State<PropertiesAdScreen> createState() => _PropertiesAdScreenState();
}

class _PropertiesAdScreenState extends State<PropertiesAdScreen> {
  final _formKey = GlobalKey<FormState>();
  bool negotiable = false;
  int? selectedStateId;
  int? selectedCityId;
  bool _showStateError = false;
  bool _showCityError = false;
  bool _showimagesError = false;
  final descriptionController = TextEditingController();
  final brandController = TextEditingController();
  final locationController = TextEditingController();
  final titleController = TextEditingController();
  final bhkController = TextEditingController();
  final noOfBathroomsController = TextEditingController();
  final priceSquareFeetController = TextEditingController();
  final totelPriceController = TextEditingController();
  final parkingController = TextEditingController();
  final floorNoController = TextEditingController();
  final roomNoController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final nameController = TextEditingController();
  final planController = TextEditingController();
  String? planId;
  String? packageId;
  String? facingDirection;
  String? propertyType;
  String? furnishingStatus;
  String? projectStatus;
  String? listedBy;
  String? imagePath;
  bool _listeByError = false;
  bool _furnishingError = false;
  bool _facingDirectionError = false;
  bool _projectStatusError = false;
  bool _isSubmitting = false; // covers pre-submit work
  List<File> _images = [];
  final int _maxImages = 6;
  List<ImageData> _imageDataList = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    brandController.text = widget.SubCatName ?? "";
    // titleController.text = widget.CatName ?? "";
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true); // Start loader

    try {
      // Step 1: Fetch API data from GetListingAdCubit (if editId is provided)
      final id = widget.editId.replaceAll('"', '').trim();
      if (id != null && id.isNotEmpty) {
        final commonAdData = await context
            .read<GetListingAdCubit>()
            .getListingAd(widget.editId);
        if (commonAdData != null) {
          descriptionController.text =
              commonAdData.data?.listing?.description ?? '';
          titleController.text =
              commonAdData.data?.listing?.title ?? widget.SubCatName;
          locationController.text = commonAdData.data?.listing?.location ?? '';
          nameController.text = commonAdData.data?.listing?.fullName ?? '';
          phoneController.text = commonAdData.data?.listing?.mobileNumber ?? '';
          bhkController.text = commonAdData.data?.listing?.bhkType ?? '';
          totelPriceController.text = commonAdData.data?.listing?.price ?? '';
          noOfBathroomsController.text =
              commonAdData.data?.listing?.noOfBathRooms.toString() ?? '';
          parkingController.text =
              commonAdData.data?.listing?.noOfParking.toString() ?? '';
          facingDirection = commonAdData.data?.listing?.facingDirection ?? '';
          furnishingStatus = commonAdData.data?.listing?.furnishingStatus ?? '';
          projectStatus = commonAdData.data?.listing?.projectStatus ?? '';
          listedBy = commonAdData.data?.listing?.listedBy ?? '';
          floorNoController.text =
              commonAdData.data?.listing?.floorNo.toString() ?? '';
          roomNoController.text =
              commonAdData.data?.listing?.roomNo.toString() ?? '';

          if (commonAdData.data?.listing?.stateId != null) {
            selectedStateId = commonAdData.data?.listing?.stateId;
            stateController.text = commonAdData.data?.listing?.stateName ?? '';
          }
          if (commonAdData.data?.listing?.cityId != null) {
            selectedCityId = commonAdData.data?.listing?.cityId;
            cityController.text = commonAdData.data?.listing?.cityName ?? '';
          }
          if (commonAdData.data?.listing?.locationKey != null &&
              commonAdData.data!.listing!.locationKey!.isNotEmpty) {
            latlng = commonAdData.data!.listing!.locationKey!;
          }
          if (commonAdData.data?.listing?.images != null) {
            _imageDataList = commonAdData.data!.listing!.images!
                .where((img) => (img.image ?? '').isNotEmpty)
                .map((img) => ImageData(id: img.id ?? '', url: img.image ?? ''))
                .toList();
          }
        }
      }

      // Step 2: Only fetch profile defaults for new ads, not edits
      if (id.isEmpty) {
        await fetchData();
      }
    } catch (e) {
      // Handle errors (optional, but recommended)
      print('Error loading data: $e');
      // Optionally show an error message to the user
    } finally {
      setState(() => isLoading = false); // Stop loader after all data is loaded
    }
  }

  Future<void> fetchData() async {
    try {
      // Fetch profile details
      final userData = await context.read<ProfileCubit>().getProfileDetails();
      if (userData != null && userData.data != null) {
        final data = userData.data!;
        debugPrint("userData: ${data.email ?? 'No email'}");

        setState(() {
          nameController.text = data.name ?? "";
          emailController.text = data.email ?? "";
          phoneController.text = data.mobile?.toString() ?? "";
          mobile_no = data.mobile ?? "";
          stateController.text = data.state_name ?? "";
          selectedStateId = data.state_id;
          selectedCityId = data.city_id;
          cityController.text = data.city_name ?? "";
        });
      } else {
        debugPrint("No user data available");
      }

      locationController.text = address;

      // // Fetch location data
      // final locationResult = await context
      //     .read<LocationCubit>()
      //     .getForSubmission();
      //
      // if (locationResult.locationName != null) {
      //   setState(() {
      //     locationController.text = locationResult.locationName;
      //   });
      // }
    } catch (e, stackTrace) {
      debugPrint("Error fetching data: $e");
      debugPrint("Stack trace: $stackTrace");
      CustomSnackBar1.show(context, 'Failed to load profile data: $e');
    } finally {}
  }

  String _getLabel() {
    switch (widget.SubCatName) {
      case "For Rent":
        return "Monthly Rent Price";
      case "For Sale":
        return "Total Sale Price";
      case "Commercial":
        return "Price";
      default:
        return "Price";
    }
  }

  String _getHint() {
    switch (widget.SubCatName) {
      case "For Rent":
        return "Enter Monthly Rent";
      case "For Sale":
        return "Enter Sale Price";
      case "Commercial":
        return "Enter Price";
      default:
        return "Enter Price";
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    return Scaffold(
      appBar: CustomAppBar1(
        title: (widget.editId.replaceAll('"', '').trim().isNotEmpty ?? false)
            ? "Edit ${widget.CatName}"
            : widget.CatName,
        actions: [],
      ),
      body: isLoading
          ? Center(child: DottedProgressWithLogo())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonTextField1(
                      lable: ' Add Title',
                      hint: 'Enter Title',
                      controller: titleController,
                      color: textColor,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required title'
                          : null,
                    ),

                    // CommonTextField1(
                    //   lable: 'Brand',
                    //   controller: brandController,
                    //   color: textColor,
                    // ),
                    CommonTextField1(
                      lable: 'BHK Type',
                      hint: 'EX: 2bhk ,3bh',
                      controller: bhkController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      color: textColor,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required BHK Type'
                          : null,
                    ),
                    CommonTextField1(
                      lable: 'No Of Bathrooms',
                      hint: 'Enter Number Of Bathrooms',
                      controller: noOfBathroomsController,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      color: textColor,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required No Of Bathrooms'
                          : null,
                    ),
                    CommonTextField1(
                      lable: 'Car Parking',
                      hint: 'Enter Number of Parking Slots',
                      controller: parkingController,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      color: textColor,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required Car Parking'
                          : null,
                    ),

                    CommonTextField1(
                      lable: 'Description',
                      hint: 'Enter  Upto  500 words',
                      controller: descriptionController,
                      color: textColor,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description required';
                        }
                        return null;
                      },
                    ),

                    GestureDetector(
                      onTap: () async {
                        final selectedState = await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return BlocProvider(
                              create: (_) => SelectStatesCubit(
                                SelectStatesImpl(
                                  remoteDataSource: RemoteDataSourceImpl(),
                                ),
                              ),
                              child: const SelectStateBottomSheet(),
                            );
                          },
                        );

                        if (selectedState != null) {
                          stateController.text = selectedState.name ?? "";
                          selectedStateId = selectedState.id ?? "";
                          setState(() {});
                        }
                      },
                      child: AbsorbPointer(
                        // 👈 stops inner TextField from eating taps
                        child: CommonTextField1(
                          lable: 'State',
                          hint: 'Select State',
                          controller: stateController,
                          color: textColor,
                          keyboardType: TextInputType.text,
                          isRead: true,
                          prefixIcon: Icon(
                            Icons.location_city_outlined,
                            color: textColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    if (_showStateError) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: ShakeWidget(
                          key: Key("state"),
                          duration: const Duration(milliseconds: 700),
                          child: const Text(
                            'Please Select State',
                            style: TextStyle(
                              fontFamily: 'roboto_serif',
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    // GestureDetector(
                    //   onTap: () async {
                    //     final selectedCity = await showModalBottomSheet(
                    //       context: context,
                    //       isScrollControlled: true,
                    //       backgroundColor: Colors.transparent,
                    //       builder: (context) {
                    //         return SelectCityBottomSheet(
                    //           stateId: selectedStateId ?? 0,
                    //         );
                    //       },
                    //     );
                    //
                    //     if (selectedCity != null) {
                    //       cityController.text = selectedCity.name ?? "";
                    //       selectedCityId = selectedCity.id ?? "";
                    //       setState(() {});
                    //     }
                    //   },
                    //   child: AbsorbPointer(
                    //     child: CommonTextField1(
                    //       lable: 'City',
                    //       hint: 'Select City',
                    //       controller: cityController,
                    //       color: textColor,
                    //       keyboardType: TextInputType.text,
                    //       isRead: true,
                    //       prefixIcon: Icon(
                    //         Icons.location_city_outlined,
                    //         color: textColor,
                    //         size: 16,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // if (_showCityError) ...[
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 5),
                    //     child: ShakeWidget(
                    //       key: Key(
                    //         "dropdown_city_error_${DateTime.now().millisecondsSinceEpoch}",
                    //       ),
                    //       duration: const Duration(milliseconds: 700),
                    //       child: const Text(
                    //         'Please Select City',
                    //         style: TextStyle(
                    //           fontFamily: 'roboto_serif',
                    //           fontSize: 12,
                    //           color: Colors.red,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ],
                    SizedBox(height: 12),
                    CommonImagePicker(
                      title: "Upload Product Images",
                      images: _images,
                      existingImages: _imageDataList,
                      maxImages: _maxImages,
                      textColor: textColor,
                      showError: _showimagesError,
                      editId: widget.editId,
                      onImagesChanged: (newList) {
                        setState(() => _images = newList);
                      },
                      onExistingImagesChanged: (newList) {
                        setState(() => _imageDataList = newList);
                      },
                    ),
                    const SizedBox(height: 12),
                    ChipSelector(
                      initialValue: facingDirection,
                      title: "Facing Direction",
                      options: [
                        {"label": "East", "value": "east"},
                        {"label": "West", "value": "west"},
                        {"label": "South", "value": "south"},
                        {"label": "North", "value": "north"},
                        {"label": "North East", "value": "north-east"},
                        {"label": "South East", "value": "south-east"},
                        {"label": "North West", "value": "north-west"},
                        {"label": "South West", "value": "south-west"},
                      ],
                      onSelected: (val) =>
                          setState(() => facingDirection = val),
                      showError: _facingDirectionError,
                    ),
                    const SizedBox(height: 12),
                    ChipSelector(
                      showError: _furnishingError,
                      initialValue: furnishingStatus,
                      title: "Furnishing Status",
                      options: [
                        {"label": "Unfurnished", "value": "unfurnished"},
                        {"label": "Semi-Furnished", "value": "semi-furnished"},
                        {
                          "label": "Fully-Furnished",
                          "value": "fully-furnished",
                        },
                      ],
                      onSelected: (val) =>
                          setState(() => furnishingStatus = val),
                    ),
                    const SizedBox(height: 12),
                    ChipSelector(
                      showError: _projectStatusError,
                      initialValue: projectStatus,
                      title: "Project Status",
                      options: [
                        {
                          "label": "Under Construction",
                          "value": "under construction",
                        },
                        {"label": "Ready to Move", "value": "ready to move"},
                        {"label": "New Launch", "value": "new launch"},
                      ],
                      onSelected: (val) => setState(() => projectStatus = val),
                    ),
                    const SizedBox(height: 12),
                    ChipSelector(
                      showError: _listeByError,
                      initialValue: listedBy,
                      title: "Listed By",
                      options: [
                        {"label": "Owner", "value": "owner"},
                        {"label": "Builder", "value": "builder"},
                        {"label": "Dealer", "value": "dealer"},
                      ],
                      onSelected: (val) => setState(() => listedBy = val),
                    ),

                    CommonTextField1(
                      lable: 'Floor Number',
                      hint: 'Enter Floor Number',
                      controller: floorNoController,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      color: textColor,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required Floor Number'
                          : null,
                    ),
                    // CommonTextField1(
                    //   lable: 'Room Number',
                    //   hint: 'Enter Room Number',
                    //   controller: roomNoController,
                    //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    //   color: textColor,
                    //   validator: (v) => (v == null || v.trim().isEmpty)
                    //       ? 'Required Room Number'
                    //       : null,
                    // ),
                    if (widget.SubCatName == "For Sale") ...[
                      CommonTextField1(
                        lable: 'Price For Sq.ft',
                        hint: 'Enter Price For Sq.ft',
                        controller: priceSquareFeetController,
                        color: textColor,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icon(
                          Icons.currency_rupee,
                          color: textColor,
                          size: 16,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Price required'
                            : null,
                      ),
                    ],
                    CommonTextField1(
                      lable: _getLabel(),
                      hint: _getHint(),
                      controller: totelPriceController,
                      color: textColor,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(
                        Icons.currency_rupee,
                        color: textColor,
                        size: 16,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Price required'
                          : null,
                    ),
                    CommonTextField1(
                      lable: 'Name',
                      hint: 'Enter name',
                      controller: nameController,
                      color: textColor,
                      prefixIcon: Icon(
                        Icons.person,
                        color: textColor,
                        size: 16,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name required'
                          : null,
                    ),
                    CommonTextField1(
                      lable: 'Phone Number',
                      hint: 'Enter phone number',
                      controller: phoneController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      color: textColor,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icon(Icons.call, color: textColor, size: 16),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Phone required'
                          : null,
                    ),
                    // CommonTextField1(
                    //   lable: 'Email (Optional)',
                    //   hint: 'Enter email',
                    //   controller: emailController,
                    //   color: textColor,
                    //   prefixIcon: Icon(Icons.mail, color: textColor, size: 16),
                    // ),
                    CommonTextField1(
                      lable: 'Address',
                      hint: 'Enter Location',
                      controller: locationController,
                      color: ThemeHelper.textColor(context),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required Location'
                          : null,
                      isRead: true,
                      onTap: selectedStateId == null
                          ? () {
                              CustomSnackBar1.show(
                                context,
                                "Please select a state first",
                              );
                            }
                          : () async {
                              FocusScope.of(context).unfocus();
                              final picked = await openPlacePickerBottomSheet(
                                context: context,
                                googleApiKey: google_map_key,
                                controller: locationController,
                                appendToExisting: false,
                                components: 'country:in',
                                language: 'en',
                                stateName:
                                    stateController.text, // Pass the state name
                                initialQuery: stateController.text.isNotEmpty
                                    ? "${locationController.text}, ${stateController.text}"
                                    : locationController.text,
                              );
                              if (picked != null) {
                                latlng = "${picked.lat}, ${picked.lng}";
                              }
                            },
                    ),
                    if (widget.editId == null ||
                        widget.editId.replaceAll('"', '').trim().isEmpty) ...[
                      CommonTextField1(
                        lable: 'Plan',
                        isRead: true,
                        hint: 'Select Plan',
                        controller: planController,
                        color: textColor,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Plan is Required'
                            : null,
                        onTap: () {
                          context
                              .read<UserActivePlanCubit>()
                              .getUserActivePlansData();
                          context.read<FreeAdCubit>().getFreeAd();
                          showPlanBottomSheet(
                            context: context,
                            controller: planController,
                            onSelectPlan: (selectedPlan) {
                              print('Selected plan: ${selectedPlan.planName}');
                              planId = selectedPlan.planId;
                              packageId = selectedPlan.packageId;
                            },
                            title: 'Choose Your Plan',
                          );
                        },
                      ),
                    ],
                    SizedBox(height: 10),
                    Text(
                      "Note : Upload only proper images that match your Ad. Wrong or unrelated pictures may lead to rejection.",
                      style: AppTextStyles.bodyMedium(textColor),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: FutureBuilder(
            future: Future.wait([AuthService.isNewUser]),
            builder: (context, asyncSnapshot) {
              final isNewUser = asyncSnapshot.data?[0] ?? false;
              final editId = widget.editId.replaceAll('"', '').trim();

              return BlocConsumer<MarkAsListingCubit, MarkAsListingState>(
                listener: (context, updateState) {
                  if (updateState is MarkAsListingSuccess ||
                      updateState is MarkAsListingUpdateSuccess) {
                    context.pushReplacement(
                      '/listing-success',
                      extra: SuccessRecapData.updated(
                        listingTitle: titleController.text.trim(),
                        listingCategory: 'Properties',
                      ),
                    );
                  } else if (updateState is MarkAsListingFailure) {
                    CustomSnackBar1.show(context, updateState.error);
                  }
                },
                builder: (context, updateState) {
                  return BlocConsumer<PropertyAdCubit, PropertyAdStates>(
                    listener: (context, state) {
                      if (state is PropertyAdSuccess) {
                        context.pushReplacement(
                          '/listing-success',
                          extra: SuccessRecapData.posted(
                            listingTitle: titleController.text.trim(),
                            listingPrice: totelPriceController.text.trim(),
                            listingCategory: 'Properties',
                            planName: planController.text.trim(),
                            durationDays: 30,
                          ),
                        );
                      } else if (state is PropertyAdFailure) {
                        CustomSnackBar1.show(context, state.error);
                      }
                    },
                    builder: (context, state) {
                      return CustomAppButton1(
                        isLoading:
                            _isSubmitting ||
                            state is PropertyAdLoading ||
                            updateState is MarkAsListingUpdateLoading,
                        text: 'Submit Ad',
                        onPlusTap: isNewUser
                            ? () {
                                context.push('/register?from=ad');
                              }
                            : () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  String? propertyType;

                                  if (widget.SubCatName == "For Sale") {
                                    propertyType = "sale";
                                  } else if (widget.SubCatName == "For Rent") {
                                    propertyType = "rent";
                                  } else if (widget.SubCatName ==
                                      "Commercial") {
                                    propertyType = "commercial";
                                  }

                                  bool isValid = true;

                                  if (selectedStateId == null) {
                                    setState(() => _showStateError = true);
                                    isValid = false;
                                  } else {
                                    setState(() => _showStateError = false);
                                  }

                                  // Check for city selection
                                  // if (selectedCityId == null) {
                                  //   setState(() => _showCityError = true);
                                  //   isValid = false;
                                  // } else {
                                  //   setState(() => _showCityError = false);
                                  // }

                                  // Check for location
                                  if (locationController.text.trim().isEmpty) {
                                    CustomSnackBar1.show(
                                      context,
                                      "Please enter location",
                                    );
                                    isValid = false;
                                  }

                                  // Check for plan selection (only for new ads, not edits)
                                  // if ((widget.editId == null ||
                                  //         widget.editId
                                  //             .replaceAll('"', '')
                                  //             .trim()
                                  //             .isEmpty) &&
                                  //     (planId == null || packageId == null)) {
                                  //   CustomSnackBar1.show(
                                  //     context,
                                  //     "Please select a plan",
                                  //   );
                                  //   isValid = false;
                                  // }

                                  final editIdClean = widget.editId
                                      .replaceAll('"', '')
                                      .trim();
                                  final isEdit = editIdClean.isNotEmpty;
                                  // IMAGE VALIDATION: consider both existing images and newly picked images
                                  final int existingCount = _imageDataList
                                      .length; // already uploaded images
                                  final int newCount =
                                      _images.length; // newly picked files
                                  final int totalCount =
                                      existingCount + newCount;
                                  const int minRequiredImages = 2;

                                  if (isEdit) {
                                    // For updates, total (existing + new) must be >= minRequiredImages
                                    if (totalCount < minRequiredImages) {
                                      CustomSnackBar1.show(
                                        context,
                                        "Please select at least $minRequiredImages images",
                                      );
                                      setState(() => _showimagesError = true);
                                      isValid = false;
                                    } else {
                                      setState(() => _showimagesError = false);
                                    }
                                  } else {
                                    // For new listing, require at least minRequiredImages new images
                                    if (newCount < minRequiredImages) {
                                      CustomSnackBar1.show(
                                        context,
                                        "Please select at least $minRequiredImages images",
                                      );
                                      setState(() => _showimagesError = true);
                                      isValid = false;
                                    } else {
                                      setState(() => _showimagesError = false);
                                    }
                                  }

                                  if (facingDirection == null ||
                                      facingDirection!.isEmpty) {
                                    setState(
                                      () => _facingDirectionError = true,
                                    );
                                    isValid = false;
                                  } else {
                                    setState(
                                      () => _facingDirectionError = false,
                                    );
                                  }

                                  // Check for furnishing status
                                  if (furnishingStatus == null ||
                                      furnishingStatus!.isEmpty) {
                                    setState(() => _furnishingError = true);
                                    isValid = false;
                                  } else {
                                    setState(() => _furnishingError = false);
                                  }

                                  // Check for project status
                                  if (projectStatus == null ||
                                      projectStatus!.isEmpty) {
                                    setState(() => _projectStatusError = true);
                                    isValid = false;
                                  } else {
                                    setState(() => _projectStatusError = false);
                                  }

                                  // Check for listed by
                                  if (listedBy == null || listedBy!.isEmpty) {
                                    setState(() => _listeByError = true);
                                    isValid = false;
                                  } else {
                                    setState(() => _listeByError = false);
                                  }

                                  // Check for description
                                  if (descriptionController.text
                                      .trim()
                                      .isEmpty) {
                                    CustomSnackBar1.show(
                                      context,
                                      "Please enter description",
                                    );
                                    isValid = false;
                                  }

                                  // Check for number of bathrooms
                                  if (noOfBathroomsController.text
                                      .trim()
                                      .isEmpty) {
                                    CustomSnackBar1.show(
                                      context,
                                      "Please enter number of bathrooms",
                                    );
                                    isValid = false;
                                  }

                                  // Check for number of car parking spaces
                                  if (parkingController.text.trim().isEmpty) {
                                    CustomSnackBar1.show(
                                      context,
                                      "Please enter number of car parking spaces",
                                    );
                                    isValid = false;
                                  }

                                  // Check for floor number
                                  if (floorNoController.text.trim().isEmpty) {
                                    CustomSnackBar1.show(
                                      context,
                                      "Please enter floor number",
                                    );
                                    isValid = false;
                                  }

                                  // // Check for room number
                                  // if (roomNoController.text.trim().isEmpty) {
                                  //   CustomSnackBar1.show(
                                  //     context,
                                  //     "Please enter room number",
                                  //   );
                                  //   isValid = false;
                                  // }

                                  // Check for price
                                  if (totelPriceController.text
                                      .trim()
                                      .isEmpty) {
                                    CustomSnackBar1.show(
                                      context,
                                      "Please enter price",
                                    );
                                    isValid = false;
                                  }

                                  // Proceed with API call only if all validations pass
                                  if (isValid) {
                                    try {
                                      setState(() => _isSubmitting = true);
                                      final locResult = await context
                                          .read<LocationCubit>()
                                          .getForSubmission();

                                      final Map<String, dynamic> data = {
                                        "title": titleController.text,
                                        "description":
                                            descriptionController.text,
                                        "sub_category_id": widget.subCatId,
                                        "category_id": widget.catId,
                                        "location": locationController.text,
                                        "mobile_number": phoneController.text,
                                        "price": totelPriceController.text,
                                        "full_name": nameController.text,
                                        "state_id": selectedStateId,
                                        "location_key": latlng,
                                        "current_address":
                                            locResult.locationName,
                                        "current_address_key": locResult.latlng,
                                        "attributes": {
                                          "bhk_type": "${bhkController.text} BHK",
                                          "no_of_bathrooms":
                                              noOfBathroomsController.text,
                                          "no_of_carparking_spaces":
                                              parkingController.text,
                                          "facing_direction": facingDirection,
                                          "furnishing_status": furnishingStatus,
                                          "project_status": projectStatus,
                                          "listed_by": listedBy,
                                          "floor_number": floorNoController.text,
                                          "property_type": propertyType,
                                          if (widget.SubCatName == "For Sale")
                                            "square_pt":
                                                priceSquareFeetController.text,
                                        },
                                      };

                                      if (widget.editId == null ||
                                          widget.editId
                                              .replaceAll('"', '')
                                              .trim()
                                              .isEmpty) {
                                        data["plan_id"] = planId;
                                        data["package_id"] = packageId;
                                      }

                                      if (_images.isNotEmpty) {
                                        data["images"] = _images;
                                      }

                                      if (widget.editId != null &&
                                          widget.editId
                                              .replaceAll('"', '')
                                              .trim()
                                              .isNotEmpty) {
                                        context
                                            .read<MarkAsListingCubit>()
                                            .markAsUpdate(widget.editId, data);
                                      } else {
                                        context
                                            .read<PropertyAdCubit>()
                                            .postPropertyAd(data);
                                      }
                                    } finally {
                                      if (mounted)
                                        setState(() => _isSubmitting = false);
                                    }
                                  }
                                }
                              },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
