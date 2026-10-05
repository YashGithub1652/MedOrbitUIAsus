// lib/services/symptom_ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/symptom_models.dart';

class SymptomAIService {
  static const _apiKey = 'YOUR_GEMINI_API_KEY';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-1.5-flash:generateContent?key=$_apiKey';

  /// Full clinical analysis — returns AnalysisResult
  static Future<AnalysisResult> analyzeSymptoms({
    required List<String> symptoms,
    required String description,
    required SymptomDuration duration,
    required int severity,
    required List<SymptomEntry> history,
  }) async {
    final historyContext = _buildHistoryContext(history);
    final prompt = _buildClinicalPrompt(
      symptoms: symptoms,
      description: description,
      duration: duration,
      severity: severity,
      historyContext: historyContext,
    );

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        final json = jsonDecode(text) as Map<String, dynamic>;
        return AnalysisResult.fromMap(json);
      }
    } catch (_) {
      // Falls through to offline fallback
    }

    return _offlineFallback(symptoms, severity, duration);
  }

  static String _buildClinicalPrompt({
    required List<String> symptoms,
    required String description,
    required SymptomDuration duration,
    required int severity,
    required String historyContext,
  }) {
    return '''
You are a clinical decision-support AI trained on medical literature.
Analyze the following patient-reported symptoms and provide a structured JSON response.

PATIENT PRESENTATION:
- Symptoms: ${symptoms.join(', ')}
- Patient Description: "$description"
- Duration: ${duration.label} (${duration.days} days)
- Severity Score: $severity / 10
- Past Medical History Context: $historyContext

INSTRUCTIONS:
1. Identify 2-4 most probable differential diagnoses
2. Flag any red-flag symptoms indicating emergency
3. Recommend appropriate specialist
4. Generate a concise doctor handoff summary
5. Detect patterns from history if applicable
6. All probability scores must sum ≤ 1.0

Return ONLY valid JSON in this exact schema:
{
  "conditions": [
    {
      "name": "Condition Name",
      "probability": 0.0,
      "description": "Brief clinical description",
      "urgency": "Emergency | Urgent | Soon | Monitor | Routine"
    }
  ],
  "summary": "Clinical summary in 2-3 sentences",
  "redFlags": ["flag1", "flag2"],
  "recommendations": ["rec1", "rec2", "rec3"],
  "specialistType": "Specialist type",
  "requiresEmergency": false,
  "aiGeneratedHandoff": "Formal handoff note a doctor can read",
  "patternInsights": ["Pattern observation from history"]
}

IMPORTANT: This is a decision-support tool only. Always include disclaimer in handoff.
''';
  }

  static String _buildHistoryContext(List<SymptomEntry> history) {
    if (history.isEmpty) return 'No prior symptom history available.';
    final recent = history.take(5).map((e) {
      return '- ${e.timestamp.toString().substring(0, 10)}: '
          '${e.symptoms.join(', ')} '
          '(Risk: ${e.riskLevel.name}, Severity: ${e.severityScore}/10)';
    }).join('\n');
    return recent;
  }

  static AnalysisResult _offlineFallback(
    List<String> symptoms,
    int severity,
    SymptomDuration duration,
  ) {
    final isEmergency = severity >= 8 ||
        symptoms.any((s) =>
            s.toLowerCase().contains('chest') ||
            s.toLowerCase().contains('breath') ||
            s.toLowerCase().contains('unconscious'));

    return AnalysisResult(
      conditions: [
        PossibleCondition(
          name: 'Undetermined — Clinical Evaluation Needed',
          probability: 1.0,
          description: 'AI analysis unavailable. Please consult a physician.',
          urgency: isEmergency ? 'Emergency' : 'Soon',
        ),
      ],
      summary: 'Unable to perform AI analysis offline. '
          'Based on severity score ($severity/10) and duration '
          '(${duration.label}), '
          '${isEmergency ? "immediate medical attention is recommended." : "please monitor symptoms and consult a doctor."}',
      redFlags: isEmergency
          ? ['High severity score', 'Possible emergency symptoms']
          : [],
      recommendations: [
        'Consult a physician for proper diagnosis',
        'Monitor symptom progression',
        if (isEmergency) 'Consider emergency care immediately',
      ],
      specialistType: 'General Practitioner',
      requiresEmergency: isEmergency,
      aiGeneratedHandoff: 'Patient presents with: ${symptoms.join(", ")}. '
          'Severity: $severity/10. Duration: ${duration.label}. '
          'AI analysis unavailable — clinical evaluation required.',
      patternInsights: [],
    );
  }

  /// Detect recurring patterns in symptom history
  static List<PatternAlert> detectPatterns(List<SymptomEntry> history) {
    if (history.length < 2) return [];

    final Map<String, List<SymptomEntry>> symptomMap = {};
    for (final entry in history) {
      for (final s in entry.symptoms) {
        final key = s.toLowerCase();
        symptomMap.putIfAbsent(key, () => []).add(entry);
      }
    }

    final alerts = <PatternAlert>[];
    symptomMap.forEach((symptom, entries) {
      if (entries.length >= 2) {
        final oldest = entries.last.timestamp;
        final newest = entries.first.timestamp;
        final daySpan = newest.difference(oldest).inDays + 1;

        String insight;
        bool requiresAttention;

        if (entries.length >= 4) {
          insight =
              '$symptom has appeared ${entries.length} times in $daySpan days. '
              'This recurring pattern may indicate a chronic condition. '
              'Consider specialist referral.';
          requiresAttention = true;
        } else if (entries.length >= 2 && daySpan <= 14) {
          insight =
              '$symptom has recurred ${entries.length} times in the past $daySpan days. '
              'Monitor closely for worsening trend.';
          requiresAttention = entries.any((e) => e.severityScore >= 6);
        } else {
          insight =
              '$symptom has been reported ${entries.length} times historically.';
          requiresAttention = false;
        }

        alerts.add(PatternAlert(
          symptom: symptom,
          occurrences: entries.length,
          daySpan: daySpan,
          insight: insight,
          requiresAttention: requiresAttention,
        ));
      }
    });

    alerts.sort((a, b) => b.occurrences.compareTo(a.occurrences));
    return alerts.take(3).toList();
  }
}
