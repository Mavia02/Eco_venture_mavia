import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nature_photo_predictiion{ai}.dart';
import 'nature_photo_sqlflite.dart'; // Import your LocalDBService

class ModalService {
  // Use the verified predict-v2 endpoint
  final String _endpointUrl = "https://muhammadmavia540--predict-v2.modal.run";
  final LocalDBService _dbService = LocalDBService(); // DB instance

  Future<NaturePrediction> predictImage(File imageFile) async {
    try {
      // 1. Read the image as raw bytes
      final bytes = await imageFile.readAsBytes();

      // 2. Send direct POST request
      final response = await http.post(
        Uri.parse(_endpointUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // 3. Parse Confidence: Convert "29.74%" string to double 0.2974
        double confidenceValue = 0.0;
        if (json['confidence'] != null) {
          String confStr = json['confidence'].toString().replaceAll('%', '');
          confidenceValue = double.parse(confStr) / 100.0;
        }

        // --- 🛡️ THE CONFIDENCE GUARD ---
        // If confidence is below 70%, we stop here and return "Unknown"
        // This prevents the "29.74% Cat" issue from reaching your UI.
        if (confidenceValue < 0.70) {
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
      print("Modal Error: $e");
      return NaturePrediction(
        label: "Unknown",
        confidence: 0.0,
        description: "We are still learning about this! Check your connection and try again.",
        category: "Unknown",
      );
    }
  }

  /// Ensures labels match your SQLite database keys
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
      "girraffe": "giraffe",
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
    };

    return labelMap[temp] ?? temp;
  }
}