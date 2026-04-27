import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:classifieds/data/cubit/Ad/PetsAd/pets_ad_cubit.dart';
import '../../Components/CustomAppButton.dart';
import '../../Components/CustomSnackBar.dart';
import '../../Components/CutomAppBar.dart';
import '../../Components/ShakeWidget.dart';
import '../../data/cubit/Ad/PetsAd/pets_ad_states.dart';
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
import '../../utils/AppLogger.dart';
import '../../utils/ImagePickerHelper.dart';
import '../../utils/ImageUtils.dart';
import '../../utils/color_constants.dart';
import '../../utils/constants.dart';
import '../../utils/place_picker_bottomsheet.dart';
import '../../utils/planhelper.dart';
import '../../widgets/CommonLoader.dart';
import '../../widgets/CommonTextField.dart';
import '../../widgets/CommonWrapChipSelector.dart';
import '../../widgets/SelectCityBottomSheet.dart';
import '../../widgets/SelectStateBottomSheet.dart';
import '../views/SuccessRecapScreen.dart';

class PetAdScreen extends StatefulWidget {
  final String catId;
  final String CatName;
  final String SubCatName;
  final String subCatId;
  final String editId;
  const PetAdScreen({
    super.key,
    required this.catId,
    required this.CatName,
    required this.SubCatName,
    required this.subCatId,
    required this.editId,
  });

  @override
  State<PetAdScreen> createState() => _PetAdScreenState();
}

class _PetAdScreenState extends State<PetAdScreen> {
  final _formKey = GlobalKey<FormState>();

  int? selectedStateId;
  int? selectedCityId;
  bool _showStateError = false;
  bool _showCityError = false;
  bool _showimagesError = false;
  final descriptionController = TextEditingController();
  final brandController = TextEditingController();
  final locationController = TextEditingController();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final phoneController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final ageController = TextEditingController();
  String _selectedGender = "male";
  final planController = TextEditingController();
  String? planId;
  String? packageId;
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
          breedController.text = commonAdData.data?.listing?.breedType ?? '';
          ageController.text = commonAdData.data?.listing?.age ?? '';

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

  String? imagePath;
  List<File> _images = [];
  final int _maxImages = 6;
  final ImagePicker _picker = ImagePicker();

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
                          lable: 'Pet Type/ Bread',
                          hint: 'Enter Pet Type/ Bread',
                          controller: breedController,
                          color: textColor,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Pet Type/ Bread is required'
                              : null,
                        ),
                        CommonTextField1(
                          lable: 'Age ',
                          hint: 'Enter Age ',
                          controller: ageController,
                          color: textColor,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Age is required'
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
                        SizedBox(height: 12),
                        _sectionTitle("Select Gender", textColor),
                        RadioListTile<String>(
                          title: Text("Male"),
                          value: "male",
                          groupValue: _selectedGender,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val) {
                            setState(() => _selectedGender = val ?? "male");
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text("Female"),
                          value: "female",
                          groupValue: _selectedGender,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val) {
                            setState(() => _selectedGender = val ?? "female");
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
                        SizedBox(height: 12),
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
                            widget.editId
                                .replaceAll('"', '')
                                .trim()
                                .isEmpty) ...[
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
                            listingCategory: 'Pets',
                          ),
                        );
                      } else if (updateState is MarkAsListingFailure) {
                        CustomSnackBar1.show(context, updateState.error);
                      }
                    },
                    builder: (context, updateState) {
                      return BlocConsumer<PetsAdCubit, PetsAdStates>(
                        listener: (context, state) {
                          if (state is PetsAdSuccess) {
                            context.pushReplacement(
                              '/listing-success',
                              extra: SuccessRecapData.posted(
                                listingTitle: titleController.text.trim(),
                                listingPrice: priceController.text.trim(),
                                listingCategory: 'Pets',
                                planName: planController.text.trim(),
                                durationDays: 30,
                              ),
                            );
                          } else if (state is PetsAdFailure) {
                            CustomSnackBar1.show(context, state.error);
                          }
                        },
                        builder: (context, state) {
                          return CustomAppButton1(
                            isLoading: _isSubmitting || state is PetsAdLoading || updateState is MarkAsListingUpdateLoading,
                            text: 'Submit Ad',
                            onPlusTap: isNewUser
                                ? () {
                              context.push('/register?from=ad');
                            }
                                : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                bool isValid = true;
                                bool showStateError = false;
                                bool showCityError = false;
                                bool showImagesError = false;
                                List<String> errorMessages = [];

                                // Validate state
                                if (selectedStateId == null) {
                                  showStateError = true;
                                  isValid = false;
                                }

                                //
                                // if (selectedCityId == null) {
                                //   showCityError = true;
                                //   isValid = false;
                                // }

                                // Validate location
                                if (locationController.text.trim().isEmpty) {
                                  errorMessages.add("Please enter location");
                                  isValid = false;
                                }


                                // if ((widget.editId == null || widget.editId.replaceAll('"', '').trim().isEmpty) &&
                                //     (planId == null || packageId == null)) {
                                //   errorMessages.add("Please select a plan");
                                //   isValid = false;
                                // }

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
                                // Validate description
                                if (descriptionController.text.trim().isEmpty) {
                                  errorMessages.add("Please enter a description");
                                  isValid = false;
                                }


                                if (priceController.text.trim().isEmpty) {
                                  errorMessages.add("Please enter a price");
                                  isValid = false;
                                }

                                setState(() {
                                  _showStateError = showStateError;
                                  _showCityError = showCityError;

                                });

                                // Show all error messages
                                if (errorMessages.isNotEmpty) {
                                  for (var message in errorMessages) {
                                    CustomSnackBar1.show(context, message);
                                  }
                                }

                                // Proceed with API call only if all fields are valid
                                if (isValid) {
                                  try{
                                    setState(() => _isSubmitting = true);
                                    final locResult = await context
                                        .read<LocationCubit>()
                                        .getForSubmission();
                                    final Map<String, dynamic> data = {
                                      "title": titleController.text,
                                      "description": descriptionController.text,
                                      "sub_category_id": widget.subCatId,
                                      "category_id": widget.catId,
                                      "location": locationController.text,
                                      "location_key": latlng,
                                      "mobile_number": phoneController.text,
                                      "price": priceController.text,
                                      "full_name": nameController.text,
                                      "state_id": selectedStateId,
                                      "current_address": locResult.locationName,
                                      "current_address_key": locResult.latlng,
                                      "attributes": {
                                        "pet_type": breedController.text,
                                        "age": ageController.text,
                                        "gender": _selectedGender,
                                      },
                                    };


                                    if (widget.editId == null || widget.editId.replaceAll('"', '').trim().isEmpty) {
                                      data["plan_id"] = planId;
                                      data["package_id"] = packageId;
                                    }

                                    if (_images.isNotEmpty) {
                                      data["images"] = _images;
                                    }

                                    if (widget.editId != null && widget.editId.replaceAll('"', '').trim().isNotEmpty) {
                                      context.read<MarkAsListingCubit>().markAsUpdate(widget.editId, data);
                                    } else {
                                      context.read<PetsAdCubit>().postPetsAd(data);
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
