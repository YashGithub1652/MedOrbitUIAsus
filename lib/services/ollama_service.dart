import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/symptom_models.dart';

class OllamaService {
  static const String _baseUrl = 'http://10.146.170.178:11434';  // ← Changed from localhost
  static const String _model = 'qwen2.5:7b';
  static const Duration _timeout = Duration(seconds: 120);

  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> analyzeSymptoms({
    required List<String> symptoms,
    required String description,
    required String duration,
    required int severity,
    required List<SymptomEntry> history,
  }) async {
    final prompt =
        '''You are a medical AI assistant. Analyze these symptoms and respond ONLY with valid JSON.

Patient symptoms: ${symptoms.join(', ')}
Description: ${description.isEmpty ? 'No additional description' : description}
Duration: $duration
Severity: $severity/10

Respond with this exact JSON structure:
{
  "summary": "Brief clinical summary",
  "urgency": "low|medium|high|emergency",
  "specialist": "Type of specialist",
  "possible_conditions": [
    {
      "name": "Condition name",
      "probability": "high|medium|low",
      "description": "Brief description",
      "urgency": "Monitor|Soon|Urgent|Emergency"
    }
  ],
  "recommendations": ["recommendation 1", "recommendation 2"],
  "warning_signs": ["warning sign if any"],
  "pattern_insights": []
}''';

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _model,
              'prompt': prompt,
              'stream': false,
              'options': {
                'temperature': 0.3,
                'num_predict': 1024,
              },
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['response'] as String? ?? '';
        return _parseJson(text);
      }
      return _fallbackResponse(symptoms, severity);
    } catch (e) {
      debugPrint('OllamaService error: $e');
      return _fallbackResponse(symptoms, severity);
    }
  }

  Future<Map<String, dynamic>> analyzeScan(
      File imageFile, String scanType) async {
    try {
      // Read image as base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt =
          '''You are a medical imaging AI. Analyze this $scanType image and respond ONLY with valid JSON.

{
  "status": "normal|abnormal|requires_review",
  "analysis": "Detailed analysis text",
  "findings": ["finding 1", "finding 2"],
  "recommendations": ["recommendation 1"],
  "confidence": 0.85,
  "scan_type": "$scanType"
}''';

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _model,
              'prompt': prompt,
              'images': [base64Image],
              'stream': false,
              'options': {'temperature': 0.2, 'num_predict': 512},
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['response'] as String? ?? '';
        final parsed = _parseJson(text);
        parsed['scan_type'] = scanType;
        return {'success': true, 'analysis': parsed};
      }
    } catch (e) {
      debugPrint('Scan analysis error: $e');
    }

    // Fallback
    return {
      'success': true,
      'analysis': {
        'status': 'requires_review',
        'analysis':
            'Unable to connect to Ollama AI. Please ensure Ollama is running with qwen2.5:7b model.',
        'findings': ['AI analysis unavailable - manual review required'],
        'recommendations': ['Please consult a radiologist for proper analysis'],
        'confidence': 0.0,
        'scan_type': scanType,
      }
    };
  }

  Future<Map<String, dynamic>> analyzeReport(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const prompt =
          '''You are a medical lab report analyzer. Analyze this lab report and respond ONLY with valid JSON.

{
  "summary": "Summary of the lab report",
  "risk_level": "normal|warning|critical",
  "abnormal_values": [
    {
      "parameter": "Parameter name",
      "value": "measured value",
      "normal_range": "normal range",
      "severity": "low|medium|high"
    }
  ],
  "recommendations": ["recommendation 1", "recommendation 2"],
  "parameters": {}
}''';

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _model,
              'prompt': prompt,
              'images': [base64Image],
              'stream': false,
              'options': {'temperature': 0.2, 'num_predict': 512},
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['response'] as String? ?? '';
        final parsed = _parseJson(text);
        return {'success': true, 'analysis': parsed, 'parameters': {}};
      }
    } catch (e) {
      debugPrint('Report analysis error: $e');
    }

    return {
      'success': true,
      'analysis': {
        'summary': 'Unable to analyze report. Please ensure Ollama is running.',
        'risk_level': 'normal',
        'abnormal_values': [],
        'recommendations': ['Please consult your doctor for report analysis'],
      },
      'parameters': {}
    };
  }

  Future<String> chat(
    String message, {
    List<Map<String, String>>? history,
    String mode = 'general',
  }) async {
    final systemPrompt = _getSystemPrompt(mode);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...?history,
      {'role': 'user', 'content': message},
    ];

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'stream': false,
              'options': {'temperature': 0.7, 'num_predict': 1024},
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'] as String? ?? 'No response from AI';
      }
    } catch (e) {
      debugPrint('Chat error: $e');
    }

    return 'Unable to connect to Ollama. Please run: ollama serve';
  }

  Stream<String> streamChat(
    String message, {
    List<Map<String, String>>? history,
    String mode = 'general',
  }) async* {
    final systemPrompt = _getSystemPrompt(mode);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...?history,
      {'role': 'user', 'content': message},
    ];

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/api/chat'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': _model,
        'messages': messages,
        'stream': true,
        'options': {'temperature': 0.7, 'num_predict': 1024},
      });

      final client = http.Client();
      final streamedResponse = await client.send(request).timeout(_timeout);

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            final token = data['message']?['content'] as String? ?? '';
            if (token.isNotEmpty) yield token;
            if (data['done'] == true) return;
          } catch (_) {}
        }
      }
      client.close();
    } catch (e) {
      debugPrint('Stream chat error: $e');
      yield 'Unable to connect to Ollama. Please run: ollama serve';
    }
  }

  String _getSystemPrompt(String mode) {
    switch (mode) {
      case 'mental':
        return 'You are a compassionate mental health AI assistant. Provide supportive, evidence-based guidance. Always recommend professional help for serious issues.';
      case 'diet':
        return 'You are a nutrition and diet AI assistant. Provide evidence-based dietary advice. Always recommend consulting a registered dietitian for personalized plans.';
      case 'fitness':
        return 'You are a fitness and exercise AI assistant. Provide safe, evidence-based fitness advice. Always recommend consulting a healthcare provider before starting new exercise programs.';
      default:
        return 'You are CREVA, an AI health companion. Provide helpful, accurate health information. Always recommend consulting healthcare professionals for medical decisions.';
    }
  }

  Map<String, dynamic> _parseJson(String text) {
    // Try to extract JSON from the response
    final jsonRegex = RegExp(r'\{[\s\S]*\}');
    final match = jsonRegex.firstMatch(text);
    if (match != null) {
      try {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      } catch (_) {}
    }
    // Return raw text as summary if JSON parsing fails
    return {'summary': text, 'urgency': 'low'};
  }

  Map<String, dynamic> _fallbackResponse(List<String> symptoms, int severity) {
    String urgency = 'low';
    if (severity >= 8) {
      urgency = 'high';
    } else if (severity >= 5) {
      urgency = 'medium';
    }

    return {
      'summary':
          'Unable to connect to Ollama AI. Please ensure Ollama is running with: ollama run qwen2.5:7b',
      'urgency': urgency,
      'specialist': 'General Physician',
      'possible_conditions': [
        {
          'name': 'Assessment Unavailable',
          'probability': 'low',
          'description': 'AI service is offline',
          'urgency': 'Monitor',
        }
      ],
      'recommendations': [
        'Start Ollama: run "ollama serve" in terminal',
        'Pull model: run "ollama pull qwen2.5:7b"',
        'Consult a healthcare professional',
      ],
      'warning_signs': [],
      'pattern_insights': [],
    };
  }
}
