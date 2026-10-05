// lib/models/report_model.dart

class MedicalReport {
  final String id;
  final String title;
  final String type; // 'lab_report' | 'scan'
  final DateTime date;
  final String? imagePath;
  final Map<String, dynamic>? extractedData;
  final Map<String, dynamic>? analysis;
  final bool hasAbnormalValues;
  final List<String> abnormalParameters;

  const MedicalReport({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.imagePath,
    this.extractedData,
    this.analysis,
    this.hasAbnormalValues = false,
    this.abnormalParameters = const [],
  });

  // ── Copy With ──────────────────────────────────────────────────
  MedicalReport copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? date,
    String? imagePath,
    Map<String, dynamic>? extractedData,
    Map<String, dynamic>? analysis,
    bool? hasAbnormalValues,
    List<String>? abnormalParameters,
  }) {
    return MedicalReport(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      extractedData: extractedData ?? this.extractedData,
      analysis: analysis ?? this.analysis,
      hasAbnormalValues: hasAbnormalValues ?? this.hasAbnormalValues,
      abnormalParameters: abnormalParameters ?? this.abnormalParameters,
    );
  }

  // ── From JSON ──────────────────────────────────────────────────
  factory MedicalReport.fromJson(Map<String, dynamic> json) {
    return MedicalReport(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      imagePath: json['image_path'] as String?,
      extractedData: json['extracted_data'] as Map<String, dynamic>?,
      analysis: json['analysis'] as Map<String, dynamic>?,
      hasAbnormalValues: json['has_abnormal_values'] as bool? ?? false,
      abnormalParameters: (json['abnormal_parameters'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // ── To JSON ────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'extracted_data': extractedData,
      'analysis': analysis,
      'has_abnormal_values': hasAbnormalValues,
      'abnormal_parameters': abnormalParameters,
    };
  }

  @override
  String toString() {
    return 'MedicalReport(id: $id, title: $title, type: $type, date: $date)';
  }
}
