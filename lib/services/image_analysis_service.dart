import 'dart:io';
import 'package:creva/config/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageAnalysisService {
  // Analyze medical report image
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/reports/analyze-image/'),  // ← Changed this
      );

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image: $e');
    }
  }

  // Extract text from image using OCR
  Future<String> extractText(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/reports/extract-text/'),  // ← Changed this
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['text'] ?? '';
      } else {
        throw Exception('Failed to extract text: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error extracting text: $e');
    }
  }
}