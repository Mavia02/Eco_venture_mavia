import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nature_photo_predictiion{ai}.dart';
import 'nature_photo_sqlflite.dart';

class ModalService {
  final String _endpointUrl = "https://muhammadmavia540--predict-v2.modal.run";
  final LocalDBService _dbService = LocalDBService();

  Future<NaturePrediction> predictImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final response = await http.post(
        Uri.parse(_endpointUrl),
        headers: {'Content-Type': 'application/octet-stream'},
        body: bytes,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        double confidenceValue = 0.0;
        if (json['confidence'] != null) {
          String confStr = json['confidence'].toString().replaceAll('%', '');
          confidenceValue = double.parse(confStr) / 100.0;
        }

        // --- 🛡️ THE CONFIDENCE GUARD ---
        // <comment-tag>Increased threshold to 0.80. Backgrounds like windows often hit 60-75% confidence; 80% is much safer.</comment-tag>
        if (confidenceValue < 0.80) {
          return NaturePrediction(
            label: "Unknown",
            confidence: confidenceValue,
            description: "I'm not quite sure what this is. Please take a clearer photo of an animal or plant!",
            category: "Unknown",
          );
        }

        String rawLabel = (json['prediction'] as String).trim().toLowerCase();
        String normalizedLabel = _normalizeLabel(rawLabel);

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
        description: "We are still learning about this!",
        category: "Unknown",
      );
    }
  }

  String _normalizeLabel(String label) {
    String temp = label.trim().toLowerCase().replaceAll(' ', '_');
    Map<String, String> labelMap = {
      "cat": "cat", "dog": "dog", "babul": "babul", "bamboo": "bamboo",
      "burnet": "burnet", "cactus": "cactus", "cockroach": "cockroach",
      "dafodils": "dafodils", "daffodil": "dafodils", "elephant": "elephant",
      "fly": "fly", "giraffe": "giraffe", "girraffe": "giraffe",
      "grasshopper": "grasshopper", "ladybug": "ladybugs", "ladybugs": "ladybugs",
      "leopard": "leopard", "mango": "mango", "neem": "neem", "ostrich": "ostrich",
      "palm_tree": "palm_tree", "pipal": "pipal", "purple_cornflower": "purple_cornflower",
      "sunflower": "sunflower", "turtle": "turtle", "zebra": "zebra", "azalea": "azalea",
    };
    return labelMap[temp] ?? temp;
  }
}