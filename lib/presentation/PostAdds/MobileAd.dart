import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:classifieds/data/cubit/Ad/MobileAd/mobile_ad_cubit.dart';
import 'package:classifieds/services/AuthService.dart';
import 'package:classifieds/utils/AppLogger.dart';
import '../../Components/CustomAppButton.dart';
import '../../Components/CustomSnackBar.dart';
import '../../Components/CutomAppBar.dart';
import '../../Components/ShakeWidget.dart';
import '../../data/cubit/Ad/MobileAd/mobile_ad_states.dart';
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
import '../../theme/ThemeHelper.dart';
import '../../utils/ImagePickerHelper.dart';
import '../../utils/ImageUtils.dart';
import '../../utils/color_constants.dart';
import '../../utils/constants.dart';
import '../../utils/place_picker_bottomsheet.dart';
import '../../utils/planhelper.dart';
import '../../widgets/CommonLoader.dart';
import '../../widgets/CommonTextField.dart';
import '../../theme/AppTextStyles.dart';
import '../../widgets/SelectCityBottomSheet.dart';
import '../../widgets/SelectStateBottomSheet.dart';

class MobileAd extends StatefulWidget {
  final String catId;
  final String CatName;
  final String SubCatName;
  final String subCatId;
  final String editId;

  const MobileAd({
    super.key,
    required this.catId,
    required this.CatName,
    required this.SubCatName,
    required this.subCatId,
    required this.editId,
  });

  @override
  State<MobileAd> createState() => _MobileAdState();
}

class _MobileAdState extends State<MobileAd> {
  final _formKey = GlobalKey<FormState>();
  bool negotiable = false;
  int? selectedStateId;
  int? selectedCityId;
  bool _showPaymentError = false;
  bool _showStateError = false;
  bool _showCityError = false;
  bool _showimagesError = false;
  final descriptionController = TextEditingController();
  final brandController = TextEditingController();
  final locationController = TextEditingController();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final storageCapacityController = TextEditingController();
  final ramController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final nameController = TextEditingController();
  final planController = TextEditingController();
  List<String> selectedConditions = [];
  bool _isSubmitting = false; // covers pre-submit work
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
        final commonAdData = await context.read<GetListingAdCubit>().getListingAd(widget.editId);
        if (commonAdData != null) {
          descriptionController.text = commonAdData.data?.listing?.description ?? '';
          titleController.text = commonAdData.data?.listing?.title ?? widget.SubCatName;
          locationController.text = commonAdData.data?.listing?.location ?? '';
          priceController.text = commonAdData.data?.listing?.price ?? '';
          nameController.text = commonAdData.data?.listing?.fullName ?? '';
          phoneController.text = commonAdData.data?.listing?.mobileNumber ?? '';
          ramController.text = commonAdData.data?.listing?.ram ?? '';
          storageCapacityController.text = commonAdData.data?.listing?.storage ?? '';

          if (commonAdData.data?.listing?.stateId != null) {
            selectedStateId = commonAdData.data?.listing?.stateId;
            stateController.text = commonAdData.data?.listing?.stateName ?? '';
          }
          if (commonAdData.data?.listing?.cityId != null) {
            selectedCityId = commonAdData.data?.listing?.cityId;
            cityController.text = commonAdData.data?.listing?.cityName ?? '';
          }
          if (commonAdData.data?.listing?.images != null) {
            _imageDataList = commonAdData.data!.listing!.images!
                .where((img) => (img.image ?? '').isNotEmpty)
                .map((img) => ImageData(id: img.id ?? 0, url: img.image ?? ''))
                .toList();
          }
        }
      }

      // Step 2: Fetch additional data from fetchData
      await fetchData();
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

  List<File> _images = [];
  final int _maxImages = 6;
  int? planId;
  int? packageId;

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
                        // CommonTextField1(
                        //   lable: 'Brand',
                        //   controller: brandController,
                        //   color: textColor,
                        // ),

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

                        // _sectionTitle('Condition', textColor),
                        // _buildChips(
                        //   ['Brand New', 'Like New', 'Used', 'For Parts Only'],
                        //   textColor,
                        //   isDarkMode,
                        // ),
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

                        CommonTextField1(
                          lable: 'Storage Capacity(ROM)',
                          hint: 'Enter Storage Capacity(ROM)',
                          controller: storageCapacityController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          color: textColor,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Storage Capacity(ROM) required'
                              : null,
                        ),
                        CommonTextField1(
                          lable: 'Memory ( RAM)',
                          hint: 'Enter Memory ( RAM)',
                          controller: ramController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          color: textColor,
                          keyboardType: TextInputType.text,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Memory ( RAM) required'
                              : null,
                        ),
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
                                  print(
                                    'Selected plan: ${selectedPlan.planName}',
                                  );
                                  planId = selectedPlan.planId;
                                  packageId = selectedPlan.packageId;
                                },
                                title: 'Choose Your Plan',
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
                future: Future.wait([
                  AuthService.isEligibleForAd,
                  AuthService.isNewUser,
                ]),
                builder: (context, asyncSnapshot) {
                  final isEligible = asyncSnapshot.data?[0] ?? false;
                  final isNewUser = asyncSnapshot.data?[1] ?? false;
                  final editId = widget.editId.replaceAll('"', '').trim();

                  return BlocConsumer<MarkAsListingCubit, MarkAsListingState>(
                    listener: (context, updateState) {
                      if (updateState is MarkAsListingSuccess ||
                          updateState is MarkAsListingUpdateSuccess) {
                        context.pushReplacement(
                          "/successfully?title=Your ad has been updated successfully",
                        );
                      } else if (updateState is MarkAsListingFailure) {
                        CustomSnackBar1.show(context, updateState.error);
                      }
                    },
                    builder: (context, updateState) {
                      return BlocConsumer<MobileAdCubit, MobileAdStates>(
                        listener: (context, state) {
                          if (state is MobileAdSuccess) {
                            context.pushReplacement(
                              "/successfully?title=Your ad has been Added successfully",
                            );
                          } else if (state is MobileAdFailure) {
                            CustomSnackBar1.show(context, state.error);
                          }
                        },
                        builder: (context, state) {
                          return CustomAppButton1(
                            isLoading:  _isSubmitting || state is MobileAdLoading || updateState is MarkAsListingUpdateLoading,
                            text: 'Submit Ad',
                            onPlusTap: isNewUser
                                ? () {
                              context.push('/register?from=ad');
                            }
                                : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                bool isValid = true;
                                if (locationController.text.trim().isEmpty) {
                                  CustomSnackBar1.show(context, "Please enter location");
                                  isValid = false;
                                }

                                if (selectedStateId == null) {
                                  setState(() => _showStateError = true);
                                  isValid = false;
                                } else {
                                  setState(() => _showStateError = false);
                                }
                                //
                                // if (selectedCityId == null) {
                                //   setState(() => _showCityError = true);
                                //   isValid = false;
                                // } else {
                                //   setState(() => _showCityError = false);
                                // }

                                // Check for plan selection (only for new ads, not edits)
                                // if ((widget.editId == null || widget.editId.replaceAll('"', '').trim().isEmpty) &&
                                //     (planId == null || packageId == null)) {
                                //   CustomSnackBar1.show(context, "Please select a plan");
                                //   isValid = false;
                                // }

                                // Check for images (if not eligible for free plan)
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

                                // Check other required fields
                                if (descriptionController.text.trim().isEmpty) {
                                  CustomSnackBar1.show(context, "Please enter description");
                                  isValid = false;
                                }
                                if (ramController.text.trim().isEmpty) {
                                  CustomSnackBar1.show(context, "Please enter RAM");
                                  isValid = false;
                                }
                                if (priceController.text.trim().isEmpty) {
                                  CustomSnackBar1.show(context, "Please enter price");
                                  isValid = false;
                                }
                                if (storageCapacityController.text.trim().isEmpty) {
                                  CustomSnackBar1.show(context, "Please enter storage capacity");
                                  isValid = false;
                                }

                                // Proceed with API call only if all validations pass
                                if (isValid) {
                                  try{
                                    setState(() => _isSubmitting = true);
                                    final locResult = await context
                                        .read<LocationCubit>()
                                        .getForSubmission();
                                    final Map<String, dynamic> data = {
                                      "title": titleController.text,
                                      "brand": brandController.text,
                                      "description": descriptionController.text,
                                      "sub_category_id": widget.subCatId,
                                      "category_id": widget.catId,
                                      "location": locationController.text,
                                      "location_key": latlng,
                                      "mobile_number": phoneController.text,
                                      "price": priceController.text,
                                      "full_name": nameController.text,
                                      "state_id": selectedStateId,
                                      // "city_id": selectedCityId,
                                      "storage": storageCapacityController.text,
                                      "ram": ramController.text,
                                      "current_address":
                                      locResult.locationName,
                                      "current_address_key":
                                      locResult.latlng,
                                    };

                                    if (widget.editId == null || widget.editId.replaceAll('"', '').trim().isEmpty) {
                                      data["plan_id"] = planId;
                                      data["package_id"] = packageId;
                                    }

                                    if (_images.isNotEmpty) {
                                      data["images"] = _images.map((file) => file.path).toList();
                                    }

                                    if (widget.editId != null && widget.editId.replaceAll('"', '').trim().isNotEmpty) {
                                      context.read<MarkAsListingCubit>().markAsUpdate(widget.editId, data);
                                    } else {
                                      context.read<MobileAdCubit>().postMobileAd(data);
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
}
