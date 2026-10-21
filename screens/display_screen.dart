import 'dart:io';
import 'package:flutter/material.dart';
import '../services/tflite_service.dart';

class DisplayScreen extends StatefulWidget {
  final File imageFile;

  const DisplayScreen({super.key, required this.imageFile});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  final TFLiteService _tflite = TFLiteService();

  String result = "";
  String severity = "";

  bool isLoading = false;
  bool isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _tflite.loadModels();
    setState(() {
      isModelLoaded = true;
    });
  }

  Future<void> analyzeImage() async {
    if (!isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Model is still loading...")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
      severity = "";
    });

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final binaryResult = _tflite.runBinaryModel(widget.imageFile);

      if (binaryResult == "Negative") {
        setState(() {
          result = "No Crack Detected";
          severity = "";
          isLoading = false;
        });
      } else {
        final multiResult = _tflite.runMultiModel(widget.imageFile);

        setState(() {
          result = "Crack Detected";
          severity = multiResult;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  String getSeverityDescription(String severity) {
    switch (severity) {
      case "hairline":
        return "Minor crack. Monitor regularly.";
      case "medium":
        return "Moderate crack. Repair is recommended.";
      case "large":
        return "Severe crack. Immediate repair required!";
      default:
        return "";
    }
  }



  Color getResultColor() {
    if (result == "Crack Detected") return Colors.red;
    if (result == "No Crack Detected") return Colors.green;
    return Colors.grey;
  }

  IconData getResultIcon() {
    if (result == "Crack Detected") return Icons.warning;
    if (result == "No Crack Detected") return Icons.check_circle;
    return Icons.image;
  }

  Color getSeverityColor() {
    switch (severity) {
      case "hairline":
        return Colors.blue;
      case "medium":
        return Colors.orange;
      case "large":
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crack Analysis"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image preview
            Container(
              margin: const EdgeInsets.all(10),
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(widget.imageFile),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (!isModelLoaded)
              const Text("Loading AI model..."),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),

            if (!isLoading && result.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(12),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        getResultIcon(),
                        size: 50,
                        color: getResultColor(),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        result,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: getResultColor(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (severity.isNotEmpty)
                        Text(
                          "Severity: $severity",
                          style: TextStyle(
                            fontSize: 18,
                            color: getSeverityColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      if (severity.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            getSeverityDescription(severity),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: analyzeImage,
              icon: const Icon(Icons.analytics),
              label: const Text("Analyze Image"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}