import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nature_photo_predictiion{ai}.dart';
import 'nature_photo_sqlflite.dart'; // Import your LocalDBService

class ModalService {
  // 🎯 VERIFIED ACTIVE PRODUCTION ENDPOINT
  final String _endpointUrl = " https://muhammadmavia540--nature-classifier-v2-natureclassifier-predict.modal.run";
  final LocalDBService _dbService = LocalDBService(); // DB instance

  Future<NaturePrediction> predictImage(File imageFile) async {
    try {
      // 1. Read the image as raw bytes
      final bytes = await imageFile.readAsBytes();

      // 2. Send direct POST request to Modal
      final response = await http.post(
        Uri.parse(_endpointUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        print("DEBUG: --- RAW API RESPONSE ---");
        print("DEBUG: API Response Body: $json");

        // 3. BULLETPROOF CONFIDENCE PARSER
        double confidenceValue = 0.0;
        if (json['confidence'] != null) {
          String confStr = json['confidence'].toString().replaceAll('%', '').trim();
          double rawNum = double.tryParse(confStr) ?? 0.0;

          // Convert percentage string (e.g. 98.5) to decimal (0.985)
          if (rawNum > 1.0) {
            confidenceValue = rawNum / 100.0;
          } else {
            confidenceValue = rawNum;
          }
        }

        print("DEBUG: Final Parsed Confidence: $confidenceValue");

        // --- 🛡️ THE 80% CONFIDENCE GUARD ---
        if (confidenceValue < 0.80 || json['prediction'] == "unknown") {
          print("DEBUG: [GUARD TRIGGERED] Confidence ($confidenceValue) is below 80% or labeled 'unknown'. Forcing 'Unknown'.");
          return NaturePrediction(
            label: "Unknown",
            confidence: confidenceValue,
            description: "I'm not quite sure what this is. Please take a clearer photo of an animal or plant!",
            category: "Unknown",
          );
        }

        // 4. PROCESS SUCCESSFUL PREDICTION
        String rawLabel = (json['prediction'] as String).trim().toLowerCase();
        String normalizedLabel = _normalizeLabel(rawLabel);

        print("DEBUG: AI Raw Label: $rawLabel | Normalized Label: $normalizedLabel");

        // Query local DB for the specific fact
        var fact = await _dbService.getFactFor(normalizedLabel);

        return NaturePrediction(
          label: fact.name,
          confidence: confidenceValue,
          description: fact.description,
          category: fact.category,
        );
      } else {
        throw Exception("Model API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Modal Service Error: $e");
      return NaturePrediction(
        label: "Unknown",
        confidence: 0.0,
        description: "We are still learning about this! Check your connection and try again.",
        category: "Unknown",
      );
    }
  }

  /// Ensures labels match your SQLite database keys (e.g., spelling mapping)
  String _normalizeLabel(String label) {
    String temp = label.trim().toLowerCase().replaceAll(' ', '_');

    Map<String, String> labelMap = {
      "cat": "cat",
      "dog": "dog",
      "babul": "babul",
      "bamboo": "bamboo",
      "burnet": "burnet",
      "cactus": "cactus",
      "cockroach": "cockroach",
      "dafodils": "dafodils",
      "daffodil": "dafodils",
      "elephant": "elephant",
      "fly": "fly",
      "giraffe": "giraffe",
      "girraffe": "giraffe", // Maps dataset spelling mistake
      "grasshopper": "grasshopper",
      "ladybug": "ladybugs",
      "ladybugs": "ladybugs",
      "leopard": "leopard",
      "mango": "mango",
      "neem": "neem",
      "ostrich": "ostrich",
      "palm_tree": "palm_tree",
      "pipal": "pipal",
      "purple_cornflower": "purple_cornflower",
      "sunflower": "sunflower",
      "turtle": "turtle",
      "zebra": "zebra",
      "azalea": "azalea",
      "unknown": "unknown",
    };

    return labelMap[temp] ?? temp;
  }
}