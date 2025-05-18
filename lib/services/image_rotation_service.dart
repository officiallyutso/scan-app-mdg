import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// import 'package:flutter/foundation.dart';

class ImageRotationService {
  static Future<String> rotateImage(String imagePath, int angleDegrees) async {
    // Read the image file
    final File imageFile = File(imagePath);
    final Uint8List imageBytes = await imageFile.readAsBytes();
    
    // image decode keliye
    final img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize the image if it's too large (for better performance)
    img.Image processedImage = image;
    if (image.width > 1000 || image.height > 1000) {
      processedImage = img.copyResize(
        image,
        width: image.width > image.height ? 1000 : null,
        height: image.height >= image.width ? 1000 : null,
      );
    }

    // Rotate the image
    final img.Image rotatedImage = img.copyRotate(processedImage, angle: angleDegrees);

    // Create a new file for the rotated image
    final Directory tempDir = await getTemporaryDirectory();
    final String fileName = path.basename(imagePath);
    final String rotatedImagePath = path.join(tempDir.path, 'rotated_$fileName');
    
    // Save the rotated image with reduced quality for better performance
    final File rotatedFile = File(rotatedImagePath);
    await rotatedFile.writeAsBytes(img.encodeJpg(rotatedImage, quality: 85));
    
    return rotatedImagePath;
  }
}