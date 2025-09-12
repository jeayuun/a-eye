import 'dart:io';
import 'package:image/image.dart' as img;

// Helper function to apply a convolution kernel to an image
img.Image _convolution(img.Image src, List<List<int>> kernel) {
  final int kernelWidth = kernel[0].length;
  final int kernelHeight = kernel.length;
  final int kernelCenterX = kernelWidth ~/ 2;
  final int kernelCenterY = kernelHeight ~/ 2;

  final dst = img.Image(width: src.width, height: src.height, numChannels: 1);

  for (int y = 0; y < src.height; ++y) {
    for (int x = 0; x < src.width; ++x) {
      num r = 0;
      for (int ky = 0; ky < kernelHeight; ++ky) {
        for (int kx = 0; kx < kernelWidth; ++kx) {
          final int pixelX = x + (kx - kernelCenterX);
          final int pixelY = y + (ky - kernelCenterY);

          if (pixelX >= 0 && pixelX < src.width && pixelY >= 0 && pixelY < src.height) {
            final p = src.getPixel(pixelX, pixelY);
            r += p.r * kernel[ky][kx];
          }
        }
      }
      dst.setPixelR(x, y, r.clamp(0, 255));
    }
  }
  return dst;
}

// Custom Laplacian function
img.Image laplacian(img.Image src) {
  // 3x3 Laplacian kernel
  const kernel = [
    [0, 1, 0],
    [1, -4, 1],
    [0, 1, 0]
  ];
  return _convolution(src, kernel);
}

class ImageValidator {
  // Function to check if the image is blurry
  static bool isBlurry(img.Image image, {double threshold = 60.0}) {
    final gray = img.grayscale(image);
    final laplacianImage = laplacian(gray);

    double mean = 0.0;
    double variance = 0.0;
    int count = 0;

    for (final p in laplacianImage) {
      mean += p.r;
      count++;
    }
    mean /= count;

    for (final p in laplacianImage) {
      variance += (p.r - mean) * (p.r - mean);
    }
    variance /= count;

    return variance < threshold;
  }

  // The main validation function
  static Future<bool> isImageValid(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      print("Validation failed: File does not exist at $imagePath");
      return false;
    }

    final imageBytes = await file.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      print("Validation failed: Could not decode image.");
      return false;
    }

    // Check for blurriness
    if (isBlurry(image)) {
      print("Validation failed: Image is blurry.");
      return false;
    }

    // You can add more validation checks here in the future.
    // For example, eye detection using a machine learning model.

    print("Image validation successful!");
    return true;
  }
}