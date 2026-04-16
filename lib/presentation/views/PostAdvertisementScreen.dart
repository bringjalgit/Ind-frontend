import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../../data/cubit/AdvertisementDetails/advertisement_details_cubit.dart';
import '../../data/cubit/AdvertisementDetails/advertisement_details_states.dart';
import '../../data/cubit/PostAdvertisement/post_advertisement_cubit.dart';
import '../../data/cubit/PostAdvertisement/post_advertisement_states.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

class PostAdvertisementScreen extends StatefulWidget {
  @override
  _PostAdvertisementScreenState createState() =>
      _PostAdvertisementScreenState();
}

class _PostAdvertisementScreenState extends State<PostAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _linkController = TextEditingController();
  final _planController = TextEditingController();
  File? _image;
  final _picker = ImagePicker();

  String? plan_id;
  String? package_id;
  // Function to validate the name
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Advertisement name is required';
    }
    return null;
  }

  // Function to validate image upload
  String? _validateImage() {
    if (_image == null) {
      return 'Please select an image';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
  }

  // Function to show the bottom sheet and fetch data using Cubit
  // Function to show the bottom sheet and fetch data using Cubit
  void _showPlanBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Get theme-related colors from ThemeHelper for bottom sheet
        final isDark = ThemeHelper.isDarkMode(context);
        final textColor = ThemeHelper.textColor(context);
        final backgroundColor = ThemeHelper.backgroundColor(context);
        final cardColor = ThemeHelper.cardColor(context);

        // Fetch data using the cubit
        context.read<AdvertisementDetailsCubit>().getAdvertisementDetails();

        return BlocBuilder<
          AdvertisementDetailsCubit,
          AdvertisementDetailsStates
        >(
          builder: (context, state) {
            if (state is AdvertisementDetailsLoading) {
              return Center(child: CircularProgressIndicator());
            }
            if (state is AdvertisementDetailsFailure) {
              return Center(child: Text('Failed to load data'));
            }

            if (state is AdvertisementDetailsLoaded) {
              final plans = state.advertisementDetailsModel.plans;

              return Container(
                height: 500, // Increased height for better display
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(24),
                    topLeft: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a Subscription Plan',
                      style: AppTextStyles.headlineMedium(
                        textColor,
                      ), // Headline text
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: plans?.length ?? 0,
                        itemBuilder: (context, index) {
                          final plan = plans?[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            color: cardColor,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              leading: Icon(
                                Icons
                                    .card_giftcard, // Plan icon (use a relevant icon here)
                                color: isDark ? Colors.white : Colors.blue,
                                size: 40,
                              ),
                              title: Text(
                                plan?.planName ?? 'N/A',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${plan?.packageName ?? 'N/A'}',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${plan?.remaining ?? 0} remaining',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Price: \$${plan?.remaining == 0 ? 0 : 9.99}', // Placeholder price
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Set the selected plan in the TextFormField
                                _planController.text = plan?.planName ?? 'N/A';
                                plan_id = plan?.planId;
                                package_id = plan?.packageId;
                                Navigator.pop(
                                  context,
                                ); // Close the bottom sheet
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(); // Return an empty container if the state is not one of the expected ones
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-related colors from ThemeHelper
    final isDark = ThemeHelper.isDarkMode(context);
    final backgroundColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);

    return Scaffold(
      appBar: AppBar(title: Text('Post Advertisement')),
      body: BlocConsumer<PostAdvertisementsCubit, PostAdvertisementStates>(
        listener: (context, state) {
          if (state is PostAdvertisementLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Advertisement posted successfully')),
            );
          } else if (state is PostAdvertisementFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        builder: (context, state) {
          if (state is PostAdvertisementLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state is PostAdvertisementFailure) {
            return Center(child: Text('Failed to load data'));
          }

          return Container(
            color: backgroundColor,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Advertisement Name',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: textColor),
                    validator: _validateName,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      labelText: 'Link (optional)',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: textColor),
                  ),
                  SizedBox(height: 16),
                  // The TextFormField for selecting the plan
                  TextFormField(
                    controller: _planController,
                    readOnly: true,
                    onTap: _showPlanBottomSheet, // Show bottom sheet
                    decoration: InputDecoration(
                      labelText: 'Select Plan',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: textColor),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final pickedFile = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (pickedFile != null) {
                        setState(() {
                          _image = File(pickedFile.path);
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.blue,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: cardColor,
                      ),
                      child: _image == null
                          ? Center(
                              child: Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: textColor,
                              ),
                            )
                          : Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        if (_validateImage() == null) {
                          final Map<String, dynamic> data = {
                            'plan_id': plan_id,
                            'package_id': package_id,
                            'name': _nameController.text,
                            'link': _linkController.text,
                            'image': _image!.path,
                          };
                          context
                              .read<PostAdvertisementsCubit>()
                              .postAdvertisement(data);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please select an image')),
                          );
                        }
                      }
                    },
                    child: Text('Submit Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.blue : Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
