import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _binaryInterpreter;
  late Interpreter _multiInterpreter;

  final int inputSize = 224; // change if your model uses different size

  // =========================
  // LOAD MODELS
  // =========================
  Future<void> loadModels() async {
    _binaryInterpreter =
    await Interpreter.fromAsset('assets/models/concrete_binary.tflite');

    _multiInterpreter =
    await Interpreter.fromAsset('assets/models/concrete_multi.tflite');
  }

  // =========================
  // IMAGE PREPROCESSING
  // =========================
  Float32List preprocessImage(File file) {
    final imageBytes = file.readAsBytesSync();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception("Invalid image");
    }

    // Resize image
    img.Image resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // Create input tensor
    Float32List input = Float32List(inputSize * inputSize * 3);

    int index = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);

        // ✅ NEW correct way (image 4.x)
        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  // =========================
  // BINARY MODEL
  // =========================
  String runBinaryModel(File imageFile) {
    final input = preprocessImage(imageFile)
        .reshape([1, inputSize, inputSize, 3]);

    // ✅ FIXED OUTPUT SHAPE
    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    _binaryInterpreter.run(input, output);

    final probability = output[0][0];

    // Threshold = 0.5
    if (probability > 0.5) {
      return "Positive"; // Crack detected
    } else {
      return "Negative"; // No crack
    }
  }

  // =========================
  // MULTI-CLASS MODEL
  // =========================
  String runMultiModel(File imageFile) {
    final input = preprocessImage(imageFile)
        .reshape([1, inputSize, inputSize, 3]);

    // ✅ Correct output shape (3 classes)
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

    _multiInterpreter.run(input, output);

    final result = output[0];

    // Debug (optional)
    print("Multi model output: $result");

    int maxIndex = 0;
    for (int i = 1; i < result.length; i++) {
      if (result[i] > result[maxIndex]) {
        maxIndex = i;
      }
    }

    // ⚠️ IMPORTANT: Match this order with your training labels!
    switch (maxIndex) {
      case 0:
        return "large";
      case 1:
        return "medium";
      case 2:
        return "hairline";
      default:
        return "unknown";
    }
  }
}