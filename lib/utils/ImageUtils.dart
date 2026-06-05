import 'dart:io';
import '../../utils/AppLogger.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  static Future<File?> compressImage(File file) async {
    try {
      // Print original image size
      int originalSizeInKB = await file.length() ~/ 1024;
      AppLogger.log("Original image size: $originalSizeInKB KB");

      // Define the output file path (temporary directory)
      final String targetPath = '${file.path}_compressed.jpg';

      int quality = 85;

      XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, // Input file path
        targetPath, // Output file path
        quality: quality, // Initial quality (0-100)
        minHeight: 800, // Optional: Set minimum height
        minWidth: 800, // Optional: Set minimum width
      );

      if (compressedXFile == null) return null;

      // Check file size and adjust quality if necessary
      File compressedFile = File(compressedXFile.path);
      int fileSizeInKB = await compressedFile.length() ~/ 1024;

      // If still larger than 500KB, reduce quality further
      while (fileSizeInKB > 500 && quality > 10) {
        quality -= 10; // Reduce quality incrementally
        final XFile? reCompressedXFile =
            await FlutterImageCompress.compressAndGetFile(
              file.absolute.path,
              targetPath,
              quality: quality,
              minHeight: 800,
              minWidth: 800,
            );
        if (reCompressedXFile == null) return null;
        compressedFile = File(reCompressedXFile.path);
        fileSizeInKB = await compressedFile.length() ~/ 1024;
      }

      // Print the final image size
      AppLogger.log("Final compressed image size: $fileSizeInKB KB");

      return compressedFile;
    } catch (e) {
      AppLogger.log("Error compressing image: $e");
      return null;
    }
  }
}
