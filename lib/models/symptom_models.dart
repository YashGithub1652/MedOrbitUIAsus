// lib/models/symptom_models.dart

enum RiskLevel { low, medium, high, emergency }

enum SymptomDuration {
  today,
  lessThanDay,
  oneToThreeDays,
  fourToSevenDays,
  oneToTwoWeeks,
  moreThanTwoWeeks;

  String get label {
    switch (this) {
      case SymptomDuration.today:
        return 'Today';
      case SymptomDuration.lessThanDay:
        return 'Less than a day';
      case SymptomDuration.oneToThreeDays:
        return '1-3 days';
      case SymptomDuration.fourToSevenDays:
        return '4-7 days';
      case SymptomDuration.oneToTwoWeeks:
        return '1-2 weeks';
      case SymptomDuration.moreThanTwoWeeks:
        return 'More than 2 weeks';
    }
  }

  // ✅ ADDED: days getter used by SymptomAIService and DoctorHandoffScreen
  int get days {
    switch (this) {
      case SymptomDuration.today:
        return 0;
      case SymptomDuration.lessThanDay:
        return 1;
      case SymptomDuration.oneToThreeDays:
        return 3;
      case SymptomDuration.fourToSevenDays:
        return 7;
      case SymptomDuration.oneToTwoWeeks:
        return 14;
      case SymptomDuration.moreThanTwoWeeks:
        return 21;
    }
  }
}

// ✅ AnalysisResult — used by SymptomAIService (Gemini path)
class AnalysisResult {
  final List<PossibleCondition> conditions;
  final String summary;
  final List<String> redFlags;
  final List<String> recommendations;
  final String specialistType;
  final bool requiresEmergency;
  final String aiGeneratedHandoff;
  final List<String> patternInsights;

  const AnalysisResult({
    required this.conditions,
    required this.summary,
    required this.redFlags,
    required this.recommendations,
    required this.specialistType,
    required this.requiresEmergency,
    required this.aiGeneratedHandoff,
    required this.patternInsights,
  });

  factory AnalysisResult.fromMap(Map<String, dynamic> map) {
    return AnalysisResult(
      conditions: (map['conditions'] as List? ?? [])
          .map((e) => PossibleCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: map['summary'] as String? ?? '',
      redFlags: List<String>.from(map['redFlags'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      specialistType:
          map['specialistType'] as String? ?? 'General Practitioner',
      requiresEmergency: map['requiresEmergency'] as bool? ?? false,
      aiGeneratedHandoff: map['aiGeneratedHandoff'] as String? ?? '',
      patternInsights: List<String>.from(map['patternInsights'] ?? []),
    );
  }

  // Convert to SymptomAnalysis for use in SymptomEntry
  SymptomAnalysis toSymptomAnalysis() {
    return SymptomAnalysis(
      summary: summary,
      overallRisk: requiresEmergency
          ? RiskLevel.emergency
          : conditions.isNotEmpty
              ? _urgencyToRisk(conditions.first.urgency)
              : RiskLevel.low,
      conditions: conditions,
      recommendations: recommendations,
      redFlags: redFlags,
      patternInsights: patternInsights,
      specialistType: specialistType,
      aiGeneratedHandoff: aiGeneratedHandoff,
    );
  }

  static RiskLevel _urgencyToRisk(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return RiskLevel.emergency;
      case 'urgent':
        return RiskLevel.high;
      case 'soon':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }
}

class SymptomEntry {
  final String id;
  final List<String> symptoms;
  final String description;
  final SymptomDuration duration;
  final int severityScore;
  final DateTime timestamp;
  final SymptomAnalysis? analysis;

  SymptomEntry({
    required this.id,
    required this.symptoms,
    required this.description,
    required this.duration,
    required this.severityScore,
    required this.timestamp,
    this.analysis,
  });

  RiskLevel get riskLevel => analysis?.overallRisk ?? RiskLevel.low;
}

class SymptomAnalysis {
  final String summary;
  final RiskLevel overallRisk;
  final List<PossibleCondition> conditions;
  final List<String> recommendations;
  final List<String> redFlags;
  final List<String> patternInsights;
  final String specialistType;
  final String aiGeneratedHandoff;

  SymptomAnalysis({
    required this.summary,
    required this.overallRisk,
    required this.conditions,
    required this.recommendations,
    this.redFlags = const [],
    this.patternInsights = const [],
    this.specialistType = 'General Physician',
    this.aiGeneratedHandoff = '',
  });

  factory SymptomAnalysis.fromJson(Map<String, dynamic> json) {
    return SymptomAnalysis(
      summary: json['summary'] as String? ?? '',
      overallRisk: _parseRisk(json['urgency'] as String?),
      specialistType: json['specialist'] as String? ?? 'General Physician',
      conditions: (json['possible_conditions'] as List? ?? [])
          .map((e) => PossibleCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      redFlags: List<String>.from(json['warning_signs'] ?? []),
      patternInsights: List<String>.from(json['pattern_insights'] ?? []),
      aiGeneratedHandoff: json['aiGeneratedHandoff'] as String? ?? '',
    );
  }

  static RiskLevel _parseRisk(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'emergency':
        return RiskLevel.emergency;
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }
}

class PossibleCondition {
  final String name;
  final double probability;
  final String description;
  final String urgency;

  PossibleCondition({
    required this.name,
    required this.probability,
    required this.description,
    required this.urgency,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> json) {
    // Handle both numeric and string probability
    double prob;
    final rawProb = json['probability'];
    if (rawProb is num) {
      prob = rawProb.toDouble();
    } else if (rawProb == 'high') {
      prob = 0.9;
    } else if (rawProb == 'medium') {
      prob = 0.5;
    } else {
      prob = 0.2;
    }

    return PossibleCondition(
      name: json['name'] as String? ?? 'Unknown',
      probability: prob,
      description: json['description'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'Monitor',
    );
  }
}

class PatternAlert {
  final String symptom;
  final String insight;
  final int occurrences;
  final int daySpan;
  final bool requiresAttention;

  PatternAlert({
    required this.symptom,
    required this.insight,
    required this.occurrences,
    required this.daySpan,
    required this.requiresAttention,
  });
}

// ✅ NearbyFacility — unified model used by both services and screens
class NearbyFacility {
  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final String type;
  final String phone;
  final double lat;
  final double lng;
  final bool isOpen24h;
  final double rating;
  final List<String> specialties;

  NearbyFacility({
    this.id = '',
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.type,
    this.phone = '',
    required this.lat,
    required this.lng,
    this.isOpen24h = false,
    this.rating = 0.0,
    this.specialties = const [],
  });
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> medications;
  final List<String> medicalHistory;
  final String preferredLanguage;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.bloodGroup,
    this.allergies = const [],
    this.medications = const [],
    this.medicalHistory = const [],
    this.preferredLanguage = 'en',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        age: json['age'] as int?,
        gender: json['gender'] as String?,
        bloodGroup: json['blood_group'] as String?,
        allergies: List<String>.from(json['allergies'] ?? []),
        medications: List<String>.from(json['medications'] ?? []),
        medicalHistory: List<String>.from(json['medical_history'] ?? []),
        preferredLanguage: json['preferred_language'] as String? ?? 'en',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'age': age,
        'gender': gender,
        'blood_group': bloodGroup,
        'allergies': allergies,
        'medications': medications,
        'medical_history': medicalHistory,
        'preferred_language': preferredLanguage,
      };
}
