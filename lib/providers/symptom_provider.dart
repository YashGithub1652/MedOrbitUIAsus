import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom_models.dart';
import '../services/ollama_service.dart';
import '../services/location_service.dart';

// ══════════════════════════════════════════════════════════════════
// STATE CLASS
// ══════════════════════════════════════════════════════════════════
class SymptomState {
  final List<String> selectedSymptoms;
  final List<SymptomEntry> history;
  final List<PatternAlert> patterns; // Changed from SymptomPattern to PatternAlert
  final bool isLoading;
  final bool isAnalyzing;
  final bool isLoadingHospitals;
  final bool isLoadingLocation;
  final String? analysisResult;
  final String? error;
  final List<NearbyFacility> nearbyHospitals;
  final List<NearbyFacility> nearbyFacilities;
  final bool ollamaConnected;

  const SymptomState({
    this.selectedSymptoms = const [],
    this.history = const [],
    this.patterns = const [],
    this.isLoading = false,
    this.isAnalyzing = false,
    this.isLoadingHospitals = false,
    this.isLoadingLocation = false,
    this.analysisResult,
    this.error,
    this.nearbyHospitals = const [],
    this.nearbyFacilities = const [],
    this.ollamaConnected = false,
  });

  SymptomState copyWith({
    List<String>? selectedSymptoms,
    List<SymptomEntry>? history,
    List<PatternAlert>? patterns,
    bool? isLoading,
    bool? isAnalyzing,
    bool? isLoadingHospitals,
    bool? isLoadingLocation,
    String? analysisResult,
    String? error,
    List<NearbyFacility>? nearbyHospitals,
    List<NearbyFacility>? nearbyFacilities,
    bool? ollamaConnected,
    bool clearError = false,
  }) {
    return SymptomState(
      selectedSymptoms: selectedSymptoms ?? this.selectedSymptoms,
      history: history ?? this.history,
      patterns: patterns ?? this.patterns,
      isLoading: isLoading ?? this.isLoading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isLoadingHospitals: isLoadingHospitals ?? this.isLoadingHospitals,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      analysisResult: analysisResult ?? this.analysisResult,
      error: clearError ? null : (error ?? this.error),
      nearbyHospitals: nearbyHospitals ?? this.nearbyHospitals,
      nearbyFacilities: nearbyFacilities ?? this.nearbyFacilities,
      ollamaConnected: ollamaConnected ?? this.ollamaConnected,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// NOTIFIER CLASS
// ══════════════════════════════════════════════════════════════════
class SymptomNotifier extends StateNotifier<SymptomState> {
  final OllamaService _ollamaService = OllamaService();

  SymptomNotifier() : super(const SymptomState()) {
    checkAiStatus();
  }

  Future<void> checkAiStatus() async {
    final connected = await _ollamaService.checkConnection();
    state = state.copyWith(ollamaConnected: connected);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void deleteEntry(String id) {
    state = state.copyWith(
      history: state.history.where((e) => e.id != id).toList(),
    );
  }

  // FIXED: Matches named parameters used in symptoms_screen.dart
  Future<SymptomEntry?> analyzeSymptoms({
    required List<String> symptoms,
    required String description,
    required SymptomDuration duration,
    required int severity,
  }) async {
    state = state.copyWith(isAnalyzing: true, clearError: true);

    try {
      final jsonResponse = await _ollamaService.analyzeSymptoms(
        symptoms: symptoms,
        description: description,
        duration: duration.label,
        severity: severity,
        history: state.history,
      );

      // Create SymptomAnalysis from JSON
      final analysis = SymptomAnalysis.fromJson(jsonResponse);

      // Create SymptomEntry matching your model constructor
      final entry = SymptomEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symptoms: List<String>.from(symptoms),
        description: description,
        duration: duration,
        severityScore: severity,
        timestamp: DateTime.now(),
        analysis: analysis,
      );

      state = state.copyWith(
        isAnalyzing: false,
        history: [entry, ...state.history],
        analysisResult: analysis.summary,
      );

      return entry;
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: "AI Analysis failed. Please check Ollama connection.",
      );
      return null;
    }
  }

  // FIXED: Method used by symptom_analysis_screen.dart
   Future<void> findNearbyDoctors([String? specialistType]) async {
    state = state.copyWith(isLoadingLocation: true);

    final position = await LocationService.getCurrentPosition();

    if (position != null) {
      final results = await LocationService.getNearbyHospitals(
        lat: position.latitude,
        lng: position.longitude,
        specialistType: specialistType,
      );

      state = state.copyWith(
        nearbyFacilities: results,
        nearbyHospitals: results,
        isLoadingLocation: false,
      );
    } else {
      state = state.copyWith(
        isLoadingLocation: false,
        error: "Could not get your location.",
      );
    }
  }

  // Method used by scan_analyzer_screen.dart
  Future<void> fetchHospitals() async {
    await findNearbyDoctors(null);
  }
}

final symptomProvider =
    StateNotifierProvider<SymptomNotifier, SymptomState>((ref) {
  return SymptomNotifier();
});