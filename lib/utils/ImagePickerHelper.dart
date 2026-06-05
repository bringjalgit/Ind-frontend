import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../data/cubit/MyAds/MarkAsListing/mark_as_listing_cubit.dart';
import '../theme/ThemeHelper.dart';
import 'ImageUtils.dart';
import 'package:flutter/material.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImageFromGallery(BuildContext context) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    return _processPickedFile(pickedFile, context);
  }

  static Future<File?> pickImageFromCamera(BuildContext context) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    return _processPickedFile(pickedFile, context);
  }

  static Future<File?> _processPickedFile(
    XFile? pickedFile,
    BuildContext context,
  ) async {
    if (pickedFile != null) {
      File? compressedFile = await ImageUtils.compressImage(
        File(pickedFile.path),
      );
      return compressedFile;
    }
    return null;
  }
  static Future<void> showImagePickerBottomSheet({
    required BuildContext context,
    required Function(File) onImageSelected,
    int maxImages = 6,
    required List<File> images,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: ThemeHelper.backgroundColor(context),
      builder: (BuildContext context) {
        final textColor =  ThemeHelper.textColor(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.blue),
                  title:  Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final File? selectedImage = await pickImageFromGallery(
                      context,
                    );
                    if (selectedImage != null && images.length < maxImages) {
                      onImageSelected(selectedImage);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.blue),
                  title:  Text(
                    'Take a Photo',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final File? selectedImage = await pickImageFromCamera(
                      context,
                    );
                    if (selectedImage != null && images.length < maxImages) {
                      onImageSelected(selectedImage);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CommonImagePicker extends StatefulWidget {
  final List<File> images;
  final List<ImageData> existingImages;
  final int maxImages;
  final bool showError;
  final Color textColor;
  final String title;
  final Function(List<File>) onImagesChanged;
  final Function(List<ImageData>)? onExistingImagesChanged;
  final String? editId;

  const CommonImagePicker({
    super.key,
    required this.images,
    required this.existingImages,
    required this.maxImages,
    required this.textColor,
    required this.title,
    required this.showError,
    required this.onImagesChanged,
    this.onExistingImagesChanged,
    this.editId,
  });

  @override
  State<CommonImagePicker> createState() => _CommonImagePickerState();
}

class _CommonImagePickerState extends State<CommonImagePicker> {
  void _pickImage() {
    ImagePickerHelper.showImagePickerBottomSheet(
      context: context,
      images: widget.images,
      maxImages: widget.maxImages,
      onImageSelected: (image) {
        final updated = [...widget.images, image];
        widget.onImagesChanged(updated);
      },
    );
  }

  void _removeLocalImage(int index) {
    final updated = [...widget.images]..removeAt(index);
    widget.onImagesChanged(updated);
  }

  void _removeExistingImage(int index, String imageUrl) {
    context.read<MarkAsListingCubit>().removeImageOnListingAd(imageUrl, widget.editId ?? '');

    final updated = [...widget.existingImages]..removeAt(index);
    widget.onExistingImagesChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D000000),
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: (widget.images.isEmpty && widget.existingImages.isEmpty)
              ? InkWell(
                  onTap: _pickImage,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_camera,
                          color: widget.textColor.withOpacity(0.6),
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+ Add Photos (${widget.maxImages})',
                          style: TextStyle(

                            fontSize: 14,
                            color: widget.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount:
                      widget.images.length + widget.existingImages.length <
                          widget.maxImages
                      ? widget.images.length + widget.existingImages.length + 1
                      : widget.images.length + widget.existingImages.length,
                  itemBuilder: (context, index) {
                    if (index < widget.existingImages.length) {
                      final image = widget.existingImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              image.url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  _removeExistingImage(index, image.url ?? ''),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final localIndex = index - widget.existingImages.length;
                    if (localIndex < widget.images.length) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              widget.images[localIndex],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeLocalImage(localIndex),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return InkWell(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              color: widget.textColor.withOpacity(0.6),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (widget.showError && widget.images.isEmpty) ...[
          const SizedBox(height: 5),
          const Text(
            'Please upload at least one image',
            style: TextStyle(
              fontFamily: 'roboto_serif',
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class ImageData {
  final String id;
  final String url;

  ImageData({required this.id, required this.url});
}
