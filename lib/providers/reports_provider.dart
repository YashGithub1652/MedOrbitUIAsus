import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/report_model.dart';
import '../services/ollama_service.dart';

// ── Image Analysis Service (uses Ollama locally) ──────────────────
class ImageAnalysisService {
  final OllamaService _ollama = OllamaService();

  Future<Map<String, dynamic>> analyzeReport(File imageFile) async {
    return await _ollama.analyzeReport(imageFile);
  }

  Future<Map<String, dynamic>> analyzeScan(
      File imageFile, String scanType) async {
    return await _ollama.analyzeScan(imageFile, scanType);
  }

  void dispose() {}
}

// ── Service Provider ──────────────────────────────────────────────
final imageAnalysisServiceProvider = Provider<ImageAnalysisService>((ref) {
  final service = ImageAnalysisService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Reports Provider ──────────────────────────────────────────────
final reportsProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<List<MedicalReport>>>(
  (ref) => ReportsNotifier(ref.watch(imageAnalysisServiceProvider)),
);

class ReportsNotifier extends StateNotifier<AsyncValue<List<MedicalReport>>> {
  final ImageAnalysisService _analysisService;

  ReportsNotifier(this._analysisService) : super(const AsyncValue.loading()) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final reports = <MedicalReport>[
        MedicalReport(
          id: '1',
          title: 'Complete Blood Count',
          type: 'lab_report',
          date: DateTime(2024, 12, 15),
          hasAbnormalValues: true,
          abnormalParameters: ['WBC', 'Hemoglobin'],
          analysis: {
            'summary':
                'CBC results show slight anemia with low hemoglobin levels. WBC count is mildly elevated suggesting possible infection.',
            'risk_level': 'warning',
            'recommendations': [
              'Consult your doctor about the low hemoglobin',
              'Increase iron-rich foods in your diet',
              'Consider follow-up blood test in 4 weeks',
            ],
            'abnormal_values': [
              {
                'parameter': 'Hemoglobin',
                'value': '10.2',
                'normal_range': '13.5-17.5 g/dL',
                'severity': 'medium',
              },
              {
                'parameter': 'WBC',
                'value': '11.8',
                'normal_range': '4.5-11.0 x10³/µL',
                'severity': 'low',
              },
            ],
          },
        ),
        MedicalReport(
          id: '2',
          title: 'Lipid Profile',
          type: 'lab_report',
          date: DateTime(2024, 11, 28),
          hasAbnormalValues: false,
          abnormalParameters: [],
          analysis: {
            'summary':
                'All lipid values are within normal range. Cholesterol levels look healthy.',
            'risk_level': 'normal',
            'recommendations': [
              'Continue your current diet',
              'Regular exercise is beneficial',
            ],
            'abnormal_values': [],
          },
        ),
        MedicalReport(
          id: '3',
          title: 'Chest X-Ray',
          type: 'scan',
          date: DateTime(2024, 12, 10),
          hasAbnormalValues: false,
          abnormalParameters: [],
          analysis: {
            'scan_type': 'X-Ray',
            'analysis':
                'Clear lung fields bilaterally. No acute cardiopulmonary abnormality.',
            'findings': [
              'Lung fields: Clear bilaterally',
              'Heart: Normal size',
              'No pleural effusion',
              'No pneumothorax',
            ],
            'status': 'normal',
            'confidence': 0.87,
            'recommendations': ['No follow-up imaging needed at this time'],
          },
        ),
      ];
      state = AsyncValue.data(reports);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<MedicalReport?> addReport(File imageFile, String type) async {
    try {
      Map<String, dynamic> result;
      if (type == 'lab_report') {
        result = await _analysisService.analyzeReport(imageFile);
      } else {
        result = await _analysisService.analyzeScan(imageFile, 'X-Ray');
      }

      if (result['success'] == true) {
        final analysisData = result['analysis'] as Map<String, dynamic>?;
        final abnormalValues = (analysisData?['abnormal_values'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        final report = MedicalReport(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: type == 'lab_report' ? 'Lab Report' : 'Medical Scan',
          type: type,
          date: DateTime.now(),
          imagePath: imageFile.path,
          extractedData: result['parameters'] as Map<String, dynamic>?,
          analysis: analysisData,
          hasAbnormalValues: abnormalValues.isNotEmpty,
          abnormalParameters: abnormalValues
              .map((v) => v['parameter'] as String? ?? '')
              .where((p) => p.isNotEmpty)
              .toList(),
        );

        state.whenData((reports) {
          state = AsyncValue.data([report, ...reports]);
        });

        return report;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteReport(String id) async {
    state.whenData((reports) {
      state = AsyncValue.data(
        reports.where((r) => r.id != id).toList(),
      );
    });
  }

  Future<void> refresh() async {
    await _loadReports();
  }
}
