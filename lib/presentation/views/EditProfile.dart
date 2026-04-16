import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/data/cubit/EmailVerification/EmailVerificationCubit.dart';
import 'package:classifieds/data/cubit/EmailVerification/EmailVerificationStates.dart';
import 'package:classifieds/theme/AppTextStyles.dart';
import 'package:classifieds/widgets/CommonLoader.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../Components/CustomAppButton.dart';
import '../../Components/CustomSnackBar.dart';
import '../../data/cubit/Profile/profile_cubit.dart';
import '../../data/cubit/States/states_cubit.dart';
import '../../data/cubit/States/states_repository.dart';
import '../../data/cubit/UpdateProfile/update_profile_cubit.dart';
import '../../data/cubit/UpdateProfile/update_profile_states.dart';
import '../../data/remote_data_source.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/ImageUtils.dart';
import '../../utils/color_constants.dart';
import '../../widgets/CommonTextField.dart';
import '../../widgets/SelectCityBottomSheet.dart';
import '../../widgets/SelectStateBottomSheet.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  int? selectedStateId;
  int? selectedCityId;

  bool isEmailVerified = false; // from API
  String? originalEmail; // from API
  bool otpVerifiedNow = false; // runtime after verification

  File? _image;
  String? imagePath;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;

  String? _validateOtp(String otp) {
    if (otp.length < 6) {
      return 'Please enter a 6-digit OTP';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'OTP must contain only digits';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().getProfileDetails().then((userData) {
      if (userData != null) {
        debugPrint("userData:${userData.data?.email ?? ""}");
        final data = userData.data;
        setState(() {
          originalEmail = data?.email ?? "";
          isEmailVerified = data?.email_verified == true;
          otpVerifiedNow = isEmailVerified; // keep same at init
          _nameController.text = data?.name ?? "";
          _emailController.text = data?.email ?? "";
          _phoneController.text = data?.mobile?.toString() ?? "";
          stateController.text = data?.state_name?.toString() ?? "";
          selectedStateId = data?.state_id ?? 0;
          selectedCityId = data?.city_id ?? 0;
          cityController.text = data?.city_name?.toString() ?? "";
          _phoneController.text = data?.mobile?.toString() ?? "";
          imagePath = data?.image ?? "";
        });
      }
      setState(() => isLoading = false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      backgroundColor: ThemeHelper.backgroundColor(context),
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: primarycolor),
                title: Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primarycolor),
                title: Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      File? compressedFile = await ImageUtils.compressImage(
        File(pickedFile.path),
      );
      if (compressedFile != null) {
        setState(() => _image = compressedFile);
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      File? compressedFile = await ImageUtils.compressImage(
        File(pickedFile.path),
      );
      if (compressedFile != null) {
        setState(() => _image = compressedFile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final accent = isDark ? const Color(0xFF8B5CF6) : const Color(0xFF1677FF);
    final accentSoft = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF0EA5E9);
    final pinIdleBorder = isDark ? Colors.white24 : const Color(0xFFE5E7EB);
    final pinActiveBorder = accent;
    final pinSelectedBorder = accentSoft;
    return Scaffold(
      appBar: CustomAppBar1(title: "Edit Profile", actions: []),
      body: isLoading
          ? const Center(child: DottedProgressWithLogo())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Pic
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : (imagePath?.startsWith('http') ?? false)
                              ? CachedNetworkImageProvider(imagePath!)
                              : const AssetImage('assets/images/profile.png')
                                    as ImageProvider,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primarycolor,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CommonTextField1(
                      lable: "Name",
                      hint: 'Enter Name',
                      controller: _nameController,
                      color: textColor,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Name required"
                          : null,
                    ),
                    CommonTextField1(
                      lable: "Email",
                      hint: 'Enter Email',
                      controller: _emailController,
                      color: textColor,
                      onChanged: (value) {
                        if (value.trim() != originalEmail) {
                          // user changed email -> reset verification
                          otpVerifiedNow = false;
                          isEmailVerified = false;
                          setState(() {});
                        }
                      },
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Email required"
                          : null,
                    ),
                    BlocConsumer<
                      EmailVerificationCubit,
                      EmailVerificationStates
                    >(
                      listener: (context, state) {
                        if (!mounted) return; // <- Important
                        if (state is SendOTPSuccess) {
                          CustomSnackBar1.show(
                            context,
                            "OTP sent to ${_emailController.text}",
                          );
                        } else if (state is SendOTPFailure) {
                          CustomSnackBar1.show(context, "${state.error}");
                        } else if (state is VerifyOTPSuccess) {
                          otpVerifiedNow = true;
                          isEmailVerified = true;
                          setState(() {});
                          CustomSnackBar1.show(
                            context,
                            "OTP Verified Successfully!",
                          );
                        } else if (state is VerifyOTPFailure) {
                          CustomSnackBar1.show(context, "${state.error}");
                        }
                      },
                      builder: (context, state) {
                        final isSending = state is SendOTPLoading;
                        final isVerifying = state is VerifyOTPLoading;

                        // Determine if OTP has been sent
                        final otpSent =
                            state is SendOTPSuccess ||
                            state is VerifyOTPLoading ||
                            state is VerifyOTPFailure;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Send OTP button (hide after OTP is sent)
                            // if (!otpSent)
                            if (!otpVerifiedNow) ...[
                              Align(
                                alignment: Alignment.topRight,
                                child: TextButton(
                                  onPressed: isSending
                                      ? null
                                      : () {
                                          _otpController.clear();
                                          otpVerifiedNow =
                                              false; // reset verification
                                          setState(() {});
                                          context
                                              .read<EmailVerificationCubit>()
                                              .sendOTP({
                                                "email": _emailController.text
                                                    .trim()
                                                    .toLowerCase(),
                                              });
                                        },
                                  child: isSending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          "Send OTP",
                                          style: AppTextStyles.titleMedium(
                                            textColor,
                                          ),
                                        ),
                                ),
                              ),

                              // OTP input field (show only after OTP is sent)
                              if (otpSent) ...[
                                SizedBox(height: 25),
                                PinCodeTextField(
                                  autoUnfocus: true,
                                  autoDisposeControllers: false,
                                  appContext: context,
                                  controller: _otpController,
                                  backgroundColor: Colors.transparent,
                                  length: 6,
                                  animationType: AnimationType.fade,
                                  hapticFeedbackTypes:
                                      HapticFeedbackTypes.heavy,
                                  cursorColor: isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  keyboardType: TextInputType.number,
                                  enableActiveFill: true,
                                  useExternalAutoFillGroup: true,
                                  beforeTextPaste: (text) => true,
                                  autoFocus: true,
                                  autoDismissKeyboard: false,
                                  showCursor: true,
                                  pastedTextStyle: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Roboto',
                                  ),
                                  pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(12),
                                    fieldHeight: 40,
                                    fieldWidth: 40,
                                    fieldOuterPadding: const EdgeInsets.only(
                                      right: 2,
                                    ),
                                    activeFillColor: isDark
                                        ? const Color(0xFF131A22)
                                        : Colors.white,
                                    selectedFillColor: isDark
                                        ? const Color(0xFF131A22)
                                        : Colors.white,
                                    inactiveFillColor: isDark
                                        ? const Color(0xFF0D141B)
                                        : Colors.white,
                                    activeColor: pinActiveBorder,
                                    selectedColor: pinSelectedBorder,
                                    inactiveColor: pinIdleBorder,
                                    activeBorderWidth: 1.6,
                                    selectedBorderWidth: 1.6,
                                    inactiveBorderWidth: 1.1,
                                  ),
                                  textStyle: TextStyle(
                                    color: textColor,
                                    fontSize: 17,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textInputAction: Platform.isAndroid
                                      ? TextInputAction.none
                                      : TextInputAction.done,
                                  onCompleted: (value) {
                                    // Make sure OTP has exactly 6 digits
                                    if (_otpController.text.length == 6) {
                                      context
                                          .read<EmailVerificationCubit>()
                                          .verifyOTP({
                                            "email": _emailController.text
                                                .trim()
                                                .toLowerCase(),
                                            "otp":
                                                int.tryParse(
                                                  _otpController.text,
                                                ) ??
                                                0,
                                          });
                                    }
                                  },
                                  onSubmitted: (value) {
                                    if (_otpController.text.length == 6) {
                                      context
                                          .read<EmailVerificationCubit>()
                                          .verifyOTP({
                                            "email": _emailController.text
                                                .trim()
                                                .toLowerCase(),
                                            "otp":
                                                int.tryParse(
                                                  _otpController.text,
                                                ) ??
                                                0,
                                          });
                                    }
                                  },
                                ),
                              ],
                              // Verify OTP button (show only after OTP is sent)
                              if (otpSent)
                                Align(
                                  alignment: Alignment.topRight,
                                  child: TextButton(
                                    onPressed: isVerifying
                                        ? null
                                        : () {
                                            context
                                                .read<EmailVerificationCubit>()
                                                .verifyOTP({
                                                  "email": _emailController
                                                      .text
                                                      .trim()
                                                      .toLowerCase(),
                                                  "otp": int.parse(
                                                    _otpController.text,
                                                  ),
                                                });
                                          },
                                    child: isVerifying
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "Verify OTP",
                                            style: AppTextStyles.titleMedium(
                                              textColor,
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ],
                        );
                      },
                    ),
                    CommonTextField1(
                      lable: "Phone",
                      hint: 'Enter Phone',
                      controller: _phoneController,
                      color: textColor,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Phone Number required"
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'State required'
                              : null,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final selectedCity = await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return SelectCityBottomSheet(
                              stateId: selectedStateId ?? 0,
                            );
                          },
                        );

                        if (selectedCity != null) {
                          cityController.text = selectedCity.name ?? "";
                          selectedCityId = selectedCity.id ?? "";
                          setState(() {});
                        }
                      },
                      child: AbsorbPointer(
                        child: CommonTextField1(
                          lable: 'City',
                          hint: 'Select City',
                          controller: cityController,
                          color: textColor,
                          keyboardType: TextInputType.text,
                          isRead: true,
                          prefixIcon: Icon(
                            Icons.location_city_outlined,
                            color: textColor,
                            size: 16,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'City required'
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: BlocConsumer<UpdateProfileCubit, UpdateProfileStates>(
            listener: (context, state) {
              if (state is UpdateProfileSuccess) {
                context.read<ProfileCubit>().getProfileDetails();
                CustomSnackBar1.show(context, state.successModel.message ?? "");
                context.pop();
              } else if (state is UpdateProfileFailure) {
                CustomSnackBar1.show(context, state.error ?? "");
              }
            },
            builder: (context, state) {
              final isLoading = state is UpdateProfileLoading;
              return SizedBox(
                width: double.infinity,
                child: CustomAppButton1(
                  text: isLoading ? "Updating..." : "Submit",
                  onPlusTap: (isLoading || !otpVerifiedNow)
                      ? null
                      : () {
                          // Form validation
                          if (_formKey.currentState?.validate() ?? false) {
                            print("Form is valid");

                            // Ensure name and email are not empty
                            if (_nameController.text.trim().isEmpty) {
                              CustomSnackBar1.show(
                                context,
                                "Name is required.",
                              );
                              return;
                            }

                            if (_emailController.text.trim().isEmpty) {
                              CustomSnackBar1.show(
                                context,
                                "Email is required.",
                              );
                              return;
                            }

                            // Ensure state and city IDs are not null or invalid
                            if (selectedStateId == null ||
                                selectedStateId == 0) {
                              CustomSnackBar1.show(
                                context,
                                "Please select a valid state.",
                              );
                              return;
                            }
                            if (selectedCityId == null || selectedCityId == 0) {
                              CustomSnackBar1.show(
                                context,
                                "Please select a valid city.",
                              );
                              return;
                            }
                            // Collect data and make the API call
                            String? imageToSend;
                            if (_image != null && _image!.path.isNotEmpty) {
                              imageToSend = _image!.path;
                            }
                            final data = {
                              "name": _nameController.text.trim(),
                              "email": _emailController.text.trim().toLowerCase(),
                              "mobile": _phoneController.text.trim(),
                              "image": imageToSend,
                              "state_id": selectedStateId, // Optional or null
                              "city_id": selectedCityId, // Optional or null
                            };

                            // Call the update profile API
                            context
                                .read<UpdateProfileCubit>()
                                .updateProfileDetails(data);
                          } else {
                            // If form validation fails, show an error message
                            print("Form is invalid");
                            CustomSnackBar1.show(
                              context,
                              "Please fill all the required fields correctly.",
                            );
                          }
                        },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
