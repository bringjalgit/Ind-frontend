import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:classifieds/Components/CustomSnackBar.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/utils/AppLogger.dart';
import '../../Components/ShakeWidget.dart';
import '../../data/cubit/Ad/CommonAd/common_ad_cubit.dart';
import '../../data/cubit/Ad/CommonAd/common_ad_states.dart';
import '../../data/cubit/FreeAd/FreeAdCubit.dart';
import '../../data/cubit/Location/location_cubit.dart';
import '../../data/cubit/MyAds/GetMarkAsListing/get_listing_ad_cubit.dart';
import '../../data/cubit/MyAds/MarkAsListing/mark_as_listing_cubit.dart';
import '../../data/cubit/MyAds/MarkAsListing/mark_as_listing_state.dart';
import '../../data/cubit/Profile/profile_cubit.dart';
import '../../data/cubit/States/states_cubit.dart';
import '../../data/cubit/States/states_repository.dart';
import '../../data/cubit/UserActivePlans/user_active_plans_cubit.dart';
import '../../data/remote_data_source.dart';
import '../../services/AuthService.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/ImagePickerHelper.dart';
import '../../utils/constants.dart';
import '../../utils/place_picker_bottomsheet.dart';
import '../../utils/planhelper.dart';
import '../../widgets/CommonLoader.dart';
import '../../widgets/CommonTextField.dart';
import '../../widgets/SelectCityBottomSheet.dart';
import '../../widgets/SelectStateBottomSheet.dart';
import '../views/SuccessRecapScreen.dart';

class CommonAd extends StatefulWidget {
  final String catId;
  final String CatName;
  final String SubCatName;
  final String subCatId;
  final String editId;
  const CommonAd({
    super.key,
    required this.catId,
    required this.CatName,
    required this.SubCatName,
    required this.subCatId,
    required this.editId,
  });

  @override
  State<CommonAd> createState() => _CommonAdState();
}

class _CommonAdState extends State<CommonAd> {
  final _formKey = GlobalKey<FormState>();
  bool negotiable = false;
  int? selectedStateId;
  int? selectedCityId;
  bool _showStateError = false;
  bool _showPriceError = false;
  bool _showDescriptionError = false;
  bool _showCityError = false;
  bool _showimagesError = false;
  bool _showPaymentError = false;
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final planController = TextEditingController();
  int? imageId;
  List<String> selectedConditions = [];
  List<File> _images = [];
  final int _maxImages = 6;
  String? planId;
  String? packageId;
  bool isLoading = true;
  bool _isSubmitting = false; // covers pre-submit work
  List<ImageData> _imageDataList = [];

  @override
  void initState() {
    super.initState();
    debugPrint("typee:${widget.editId}");
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true); // Start loader

    try {
      // Step 1: Fetch API data from GetListingAdCubit (if editId is provided)
      final id = widget.editId.replaceAll('"', '').trim();
      if (id != null && id.isNotEmpty) {
        final commonAdData = await context.read<GetListingAdCubit>().getListingAd(widget.editId);
        if (commonAdData != null) {
          descriptionController.text = commonAdData.data?.listing?.description ?? '';
          titleController.text = commonAdData.data?.listing?.title ?? widget.SubCatName;
          locationController.text = commonAdData.data?.listing?.location ?? '';
          priceController.text = commonAdData.data?.listing?.price ?? '';
          nameController.text = commonAdData.data?.listing?.fullName ?? '';
          phoneController.text = commonAdData.data?.listing?.mobileNumber ?? '';

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
          phoneController.text = data.mobile?.toString() ?? "";
          mobile_no = data.mobile??"";
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

  void removeOldImage(ImageData image) {
    setState(() {
      _imageDataList.removeWhere((img) => img.id == image.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    return FutureBuilder(
      future: AuthService.isEligibleForFree,
      builder: (context, asyncSnapshot) {
        final isEligibleForFree = asyncSnapshot.data ?? false;
        AppLogger.info("isEligibleForFree:${isEligibleForFree}");
        return Scaffold(
          appBar: CustomAppBar1(
            title:
                (widget.editId.replaceAll('"', '').trim().isNotEmpty ?? false)
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

                        CommonTextField1(
                          lable: 'Price',
                          hint: 'Enter price',
                          controller: priceController,
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
                              // validator: (v) => (v == null || v.trim().isEmpty)
                              //     ? 'State required'
                              //     : null,
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
                        //       // validator: (v) => (v == null || v.trim().isEmpty)
                        //       //     ? 'City required'
                        //       //     : null,
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
                        _sectionTitle('Contact Information', textColor),
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
                          prefixIcon: Icon(
                            Icons.call,
                            color: textColor,
                            size: 16,
                          ),
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
                              stateName: stateController
                                  .text, // Pass the state name
                              initialQuery:
                              stateController.text.isNotEmpty
                                  ? "${locationController.text}, ${stateController.text}"
                                  : locationController.text,
                            );
                            if (picked != null) {
                              latlng = "${picked.lat}, ${picked.lng}";
                            }
                          },
                        ),
                        if ((widget.editId == null ||
                                widget.editId
                                    .replaceAll('"', '')
                                    .trim()
                                    .isEmpty) &&
                            !isEligibleForFree) ...[
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
                                  print(
                                    'Selected plan: ${selectedPlan.planName}',
                                  );
                                  planId = selectedPlan.planId;
                                  packageId = selectedPlan.packageId;
                                },
                                title:
                                    'Choose Your Plan', // Optional title for the bottom sheet
                              );
                            },
                          ),
                        ],
                        SizedBox(height: 10,),
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
                  return BlocConsumer<MarkAsListingCubit, MarkAsListingState>(
                    listener: (context, updateState) {
                      if (updateState is MarkAsListingSuccess ||
                          updateState is MarkAsListingUpdateSuccess) {
                        context.pushReplacement(
                          '/listing-success',
                          extra: SuccessRecapData.updated(
                            listingTitle: titleController.text.trim(),
                            listingCategory: widget.CatName,
                          ),
                        );
                      } else if (updateState is MarkAsListingFailure) {
                        CustomSnackBar1.show(context, updateState.error);
                      }
                    },
                    builder: (context, updateState) {
                      return BlocConsumer<CommonAdCubit, CommonAdStates>(
                        listener: (context, state) {
                          if (state is CommonAdSuccess) {
                            context.pushReplacement(
                              '/listing-success',
                              extra: SuccessRecapData.posted(
                                listingTitle: titleController.text.trim(),
                                listingPrice: priceController.text.trim(),
                                listingCategory: widget.CatName,
                                planName: planController.text.trim(),
                                durationDays: 30,
                              ),
                            );
                          } else if (state is CommonAdFailure) {
                            CustomSnackBar1.show(context, state.error);
                          }
                        },
                        builder: (context, state) {
                          return CustomAppButton1(
                            isLoading:       _isSubmitting ||
                                state is CommonAdLoading ||
                                updateState is MarkAsListingUpdateLoading,
                            text: 'Submit Ad',
                            onPlusTap: isNewUser
                                ? () {
                                    context.push('/register?from=ad');
                                  }
                                : () async {
                                    if (!(_formKey.currentState?.validate() ??
                                        false)) {
                                      CustomSnackBar1.show(
                                        context,
                                        "Please fill all required fields highlighted in red",
                                      );
                                      return;
                                    }
                                    {
                                      bool isValid = true;

                                      final editIdClean = widget.editId.replaceAll('"', '').trim();
                                      final isEdit = editIdClean.isNotEmpty;
                                      // IMAGE VALIDATION: consider both existing images and newly picked images
                                      final int existingCount = _imageDataList.length; // already uploaded images
                                      final int newCount = _images.length; // newly picked files
                                      final int totalCount = existingCount + newCount;
                                      const int minRequiredImages = 2;

                                      if (isEdit) {
                                        // For updates, total (existing + new) must be >= minRequiredImages
                                        if (totalCount < minRequiredImages) {
                                          CustomSnackBar1.show(context, "Please select at least $minRequiredImages images");
                                          setState(() => _showimagesError = true);
                                          isValid = false;
                                        } else {
                                          setState(() => _showimagesError = false);
                                        }
                                      } else {
                                        // For new listing, require at least minRequiredImages new images
                                        if (newCount < minRequiredImages) {
                                          CustomSnackBar1.show(context, "Please select at least $minRequiredImages images");
                                          setState(() => _showimagesError = true);
                                          isValid = false;
                                        } else {
                                          setState(() => _showimagesError = false);
                                        }
                                      }

                                      if (selectedStateId == null) {
                                        setState(() => _showStateError = true);
                                        isValid = false;
                                      } else {
                                        setState(() => _showStateError = false);
                                      }

                                      // if (selectedCityId == null) {
                                      //   setState(() => _showCityError = true);
                                      //   isValid = false;
                                      // } else {
                                      //   setState(() => _showCityError = false);
                                      // }

                                      if (descriptionController.text
                                          .trim()
                                          .isEmpty) {
                                        setState(
                                          () => _showDescriptionError = true,
                                        );
                                        isValid = false;
                                      } else {
                                        setState(
                                          () => _showDescriptionError = false,
                                        );
                                      }
                                      if (priceController.text.trim().isEmpty) {
                                        setState(() => _showPriceError = true);
                                        isValid = false;
                                      } else {
                                        setState(() => _showPriceError = false);
                                      }

                                      if ((widget.editId == null ||
                                              widget.editId
                                                  .replaceAll('"', '')
                                                  .trim()
                                                  .isEmpty) &&
                                          !isEligibleForFree) {
                                        if (planId == null ||
                                            packageId == null) {
                                          setState(
                                            () => _showPaymentError = true,
                                          );
                                          isValid = false;
                                        } else {
                                          setState(
                                            () => _showPaymentError = false,
                                          );
                                        }
                                      }
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
                                            "location_key": latlng,
                                            "mobile_number": phoneController.text,
                                            if ((widget.editId == null ||
                                                    widget.editId
                                                        .replaceAll('"', '')
                                                        .trim()
                                                        .isEmpty) &&
                                                planId != null)
                                              "plan_id": planId,
                                            if ((widget.editId == null ||
                                                    widget.editId
                                                        .replaceAll('"', '')
                                                        .trim()
                                                        .isEmpty) &&
                                                packageId != null)
                                              "package_id": packageId,
                                            "price": priceController.text,
                                            "full_name": nameController.text,
                                            "state_id": selectedStateId,
                                            // "city_id": selectedCityId,
                                            "current_address":
                                            locResult.locationName,
                                            "current_address_key":
                                            locResult.latlng,
                                          };

                                          if (_images.isNotEmpty) {
                                            data["images"] = _images;
                                          }
                                          if (widget.editId
                                              .replaceAll('"', '')
                                              .trim()
                                              .isNotEmpty ??
                                              false) {
                                            context
                                                .read<MarkAsListingCubit>()
                                                .markAsUpdate(
                                              widget.editId,
                                              data,
                                            );
                                          } else {
                                            context
                                                .read<CommonAdCubit>()
                                                .postCommonAd(data);
                                          }
                                        }finally{
                                          if (mounted)
                                            setState(
                                                  () => _isSubmitting = false,
                                            );
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
      },
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: AppTextStyles.titleMedium(
          color,
        ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// class ImageData {
//   final int id;
//   final String url;
//
//   ImageData({required this.id, required this.url});
// }
