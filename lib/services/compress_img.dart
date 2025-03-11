import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Compresses and resizes an image to fit within maxSizeBytes
Future<pw.MemoryImage?> compressImageForPdf(String? imagePath,
    {int maxSizeBytes = 500000}) async {
  if (imagePath == null) return null;

  try {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      print('Image file does not exist: $imagePath');
      return null;
    }

    // Read the original image bytes
    final bytes = await imageFile.readAsBytes();
    print('Original image size: ${bytes.length} bytes');

    if (bytes.length <= maxSizeBytes) {
      print('Image already within size limit, using as is');
      return pw.MemoryImage(bytes);
    }

    // Decode the image
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      print('Failed to decode image');
      return null;
    }

    // Calculate dimensions for the resized image
    // Start with 80% quality and gradually reduce if needed
    int quality = 80;
    double scale = 1.0;
    Uint8List? compressedBytes;

    // Try different compression settings until we get under the size limit
    while (quality >= 30) {
      // Scale down proportionally if the image is large
      if (originalImage.width > 1000 || originalImage.height > 1000) {
        scale = 1000 / max(originalImage.width, originalImage.height);
      }

      final targetWidth = (originalImage.width * scale).round();
      final targetHeight = (originalImage.height * scale).round();

      // Resize the image
      final resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );

      // Encode as JPEG with the current quality setting
      compressedBytes =
          Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));

      print(
          'Compressed to ${compressedBytes.length} bytes (scale: $scale, quality: $quality)');

      if (compressedBytes.length <= maxSizeBytes) {
        break;
      }

      // If still too large, reduce quality or scale further
      if (quality > 30) {
        quality -= 10;
      } else if (scale > 0.3) {
        scale -= 0.1;
        quality = 80; // Reset quality when trying a new scale
      } else {
        // If we can't compress enough, use the last attempt
        print('Could not compress enough, using best effort');
        break;
      }
    }

    if (compressedBytes == null || compressedBytes.isEmpty) {
      print('Compression failed to produce valid image data');
      return null;
    }

    print('Final compressed size: ${compressedBytes.length} bytes');

    // Save the compressed image (optional, for debugging)
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_visitor_photo.jpg');
    await compressedFile.writeAsBytes(compressedBytes);
    print('Compressed image saved to: ${compressedFile.path}');

    // Return as MemoryImage for PDF
    return pw.MemoryImage(compressedBytes);
  } catch (e) {
    print('Error compressing image (pdf): $e');
    return null;
  }
}

Future<Uint8List?> compressImageToBytes(String? imagePath,
    {int maxSizeBytes = 500000}) async {
  if (imagePath == null) return null;

  try {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      print('Image file does not exist: $imagePath');
      return null;
    }

    print('Compressing image to $maxSizeBytes bytes: $imagePath');

    // Read the original image bytes
    final bytes = await imageFile.readAsBytes();

    if (bytes.length <= maxSizeBytes) {
      print('Image already within size limit, using as is');
      return bytes;
    }

    print('Original image size: ${bytes.length} bytes');

    // Decode the image
    late img.Image? originalImage;
    try {
      originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        print('Failed to decode image');
        return null;
      }
    } catch (e) {
      print('Error decoding image: $e');
      return null;
    }

    print('Decoded image: ${originalImage.width}x${originalImage.height}');

    // Calculate dimensions for the resized image
    // Start with 80% quality and gradually reduce if needed
    int quality = 80;
    double scale = 1.0;
    Uint8List? compressedBytes;

    // Try different compression settings until we get under the size limit
    while (quality >= 30) {
      // Scale down proportionally if the image is large
      if (originalImage.width > 1000 || originalImage.height > 1000) {
        scale = 1000 / max(originalImage.width, originalImage.height);
      }

      final targetWidth = (originalImage.width * scale).round();
      final targetHeight = (originalImage.height * scale).round();

      // Resize the image
      final resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );

      // Encode as JPEG with the current quality setting
      compressedBytes =
          Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));

      print(
          'Tried compression: ${compressedBytes.length} bytes (scale: $scale, quality: $quality)');

      if (compressedBytes.length <= maxSizeBytes) {
        break;
      }

      // If still too large, reduce quality or scale further
      if (quality > 30) {
        quality -= 10;
      } else if (scale > 0.3) {
        scale -= 0.1;
        quality = 80; // Reset quality when trying a new scale
      } else {
        // If we can't compress enough, use the last attempt
        print('Could not compress enough, using best effort');
        break;
      }
    }

    if (compressedBytes == null || compressedBytes.isEmpty) {
      print('Compression failed to produce valid image data');
      return null;
    }

    // Return the compressed bytes
    return compressedBytes;
  } catch (e) {
    print('Error compressing image (bytes): $e');
    return null;
  }
}
