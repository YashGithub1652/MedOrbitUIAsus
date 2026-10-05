import 'package:flutter/foundation.dart';
import 'ollama_service.dart';

class ApiService {
  final OllamaService _ollama = OllamaService();
  final List<Map<String, String>> _chatHistory = [];

  // ── Ollama Chat ───────────────────────────────────────────────
  Future<Map<String, dynamic>> sendQuery(
    String message, {
    String? conversationId,
    String mode = 'general',
  }) async {
    try {
      final response = await _ollama.chat(
        message,
        history: _chatHistory,
        mode: mode,
      );

      _chatHistory.add({'role': 'user', 'content': message});
      _chatHistory.add({'role': 'assistant', 'content': response});

      if (_chatHistory.length > 20) {
        _chatHistory.removeRange(0, 2);
      }

      return {
        'response': response,
        'conversation_id': conversationId ?? 'local',
        'is_emergency': _checkEmergency(message),
        'urgency': 'low',
        'risk_score': 0,
        'confidence': 'high',
      };
    } catch (e) {
      debugPrint('ApiService sendQuery error: $e');
      return {
        'response': 'Unable to connect to Ollama. Please run: ollama serve',
        'conversation_id': conversationId ?? 'local',
        'is_emergency': false,
      };
    }
  }

  Stream<String> streamQuery(
    String message, {
    String? conversationId,
    String mode = 'general',
  }) async* {
    _chatHistory.add({'role': 'user', 'content': message});

    String fullResponse = '';

    await for (final token in _ollama.streamChat(
      message,
      history: _chatHistory.length > 1
          ? _chatHistory.sublist(0, _chatHistory.length - 1)
          : [],
      mode: mode,
    )) {
      fullResponse += token;
      yield token;
    }

    if (fullResponse.isNotEmpty) {
      _chatHistory.add({'role': 'assistant', 'content': fullResponse});
    }

    if (_chatHistory.length > 20) {
      _chatHistory.removeRange(0, 2);
    }
  }

  bool _checkEmergency(String message) {
    final emergencyKeywords = [
      'chest pain',
      'can\'t breathe',
      'heart attack',
      'stroke',
      'unconscious',
      'severe bleeding',
      'suicide',
      'overdose',
    ];
    final lower = message.toLowerCase();
    return emergencyKeywords.any((k) => lower.contains(k));
  }

  // ── Chat (used by ChatScreen) ─────────────────────────────────
  /// Called as: await _api.chat('message')
  /// Returns: Map<String, dynamic> with 'response' key
  Future<Map<String, dynamic>> chat(String message) async {
    try {
      final response = await _ollama.chat(
        message,
        history: _chatHistory,
        mode: 'general',
      );

      _chatHistory.add({'role': 'user', 'content': message});
      _chatHistory.add({'role': 'assistant', 'content': response});

      if (_chatHistory.length > 20) {
        _chatHistory.removeRange(0, 2);
      }

      return {
        'response': response,
        'message': response,
      };
    } catch (e) {
      debugPrint('ApiService chat error: $e');
      return {
        'response': 'Unable to connect. Please ensure Ollama is running.',
        'message': 'Unable to connect. Please ensure Ollama is running.',
      };
    }
  }

  // ── Vitals (used by VitalsScreen) ────────────────────────────
  /// Called as: await _api.getVitals()
  /// Returns: List<dynamic>
  Future<List<dynamic>> getVitals() async {
    // No backend for vitals — return empty list
    // Vitals screen will fall back to Firestore
    return [];
  }

  /// Called as: await _api.recordVitals(vitals)
  /// Accepts: Map<String, dynamic>
  Future<Map<String, dynamic>> recordVitals(Map<String, dynamic> vitals) async {
    try {
      // Try Ollama/local processing if needed
      // For now just return success — Firestore handles persistence
      debugPrint('Recording vitals locally: $vitals');
      return {
        'success': true,
        'message': 'Vitals recorded',
        'data': vitals,
      };
    } catch (e) {
      debugPrint('recordVitals error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    return {
      'avg_risk_score': 0.0,
      'total_records': 0,
      'conversations_count': 0,
      'vitals_history': [],
      'patterns': [],
    };
  }

  // ── Notifications ─────────────────────────────────────────────
  Future<List<dynamic>> getNotifications() async {
    return [];
  }

  Future<void> markNotificationRead(String id) async {}

  // ── Symptom Analysis ──────────────────────────────────────────
  Future<Map<String, dynamic>> analyzeSymptoms(List<String> symptoms) async {
    try {
      final prompt =
          'Analyze these symptoms and provide assessment: ${symptoms.join(', ')}';
      final response = await _ollama.chat(
        prompt,
        history: [],
        mode: 'general',
      );
      return {
        'analysis': response,
        'symptoms': symptoms,
        'is_emergency': symptoms.any((s) => _checkEmergency(s)),
      };
    } catch (e) {
      debugPrint('analyzeSymptoms error: $e');
      return {
        'analysis': 'Unable to analyze symptoms at this time.',
        'symptoms': symptoms,
        'is_emergency': false,
      };
    }
  }
}
