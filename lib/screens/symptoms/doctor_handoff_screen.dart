// lib/screens/symptoms/doctor_handoff_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../models/symptom_models.dart';

class DoctorHandoffScreen extends StatelessWidget {
  final SymptomEntry entry;
  const DoctorHandoffScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final analysis = entry.analysis;
    final handoffText = _buildFullHandoff(entry);

    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        elevation: 0,
        leading: const BackButton(color: CrevaColors.textPrimary),
        title: const Text(
          'Doctor Handoff',
          style: TextStyle(
            color: CrevaColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined, color: CrevaColors.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: handoffText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Handoff note copied to clipboard'),
                  backgroundColor: CrevaColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CrevaColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CrevaColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.medical_information,
                      color: CrevaColors.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Share this handoff summary with your doctor or paste it in a patient portal.',
                      style: TextStyle(
                        fontSize: 12,
                        color: CrevaColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Handoff document
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CrevaColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Letterhead
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CrevaColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CREVA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI-Assisted Clinical Handoff',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: CrevaColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Patient-generated • AI-supported',
                              style: TextStyle(
                                fontSize: 11,
                                color: CrevaColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _HandoffSection(
                    label: 'DATE & TIME',
                    value: _formatFull(entry.timestamp),
                  ),
                  _HandoffSection(
                    label: 'CHIEF COMPLAINT',
                    value: entry.symptoms.join(', '),
                  ),
                  _HandoffSection(
                    label: 'DURATION',
                    value:
                        '${entry.duration.label} (approx. ${entry.duration.days} day${entry.duration.days > 1 ? "s" : ""})',
                  ),
                  _HandoffSection(
                    label: 'SEVERITY',
                    value: '${entry.severityScore}/10',
                  ),
                  if (entry.description.isNotEmpty)
                    _HandoffSection(
                      label: 'PATIENT DESCRIPTION',
                      value: entry.description,
                    ),
                  _HandoffSection(
                    label: 'RISK CLASSIFICATION',
                    value: entry.riskLevel.name.toUpperCase(),
                    valueColor: _riskColor(entry.riskLevel),
                  ),

                  if (analysis != null) ...[
                    const Divider(height: 24),
                    _HandoffSection(
                      label: 'AI CLINICAL SUMMARY',
                      value: analysis.summary,
                    ),
                    if (analysis.redFlags.isNotEmpty)
                      _HandoffSection(
                        label: 'RED FLAGS IDENTIFIED',
                        value: analysis.redFlags.map((f) => '• $f').join('\n'),
                        valueColor: CrevaColors.error,
                      ),
                    _HandoffSection(
                      label: 'DIFFERENTIAL DIAGNOSES',
                      value: analysis.conditions.asMap().entries.map((e) {
                        final c = e.value;
                        final pct = (c.probability * 100).round();
                        return '${e.key + 1}. ${c.name} ($pct%) — ${c.urgency}';
                      }).join('\n'),
                    ),
                    _HandoffSection(
                      label: 'RECOMMENDED SPECIALIST',
                      value: analysis.specialistType,
                    ),
                    _HandoffSection(
                      label: 'RECOMMENDATIONS',
                      value: analysis.recommendations
                          .asMap()
                          .entries
                          .map((e) => '${e.key + 1}. ${e.value}')
                          .join('\n'),
                    ),
                    if (analysis.aiGeneratedHandoff.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'FORMAL HANDOFF NOTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: CrevaColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CrevaColors.border),
                        ),
                        child: Text(
                          analysis.aiGeneratedHandoff,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CrevaColors.textPrimary,
                            height: 1.6,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],

                  const Divider(height: 24),
                  const Text(
                    'DISCLAIMER: This document is AI-generated and patient-reported. '
                    'It is not a substitute for clinical evaluation, diagnosis, or '
                    'treatment by a licensed medical professional.',
                    style: TextStyle(
                      fontSize: 10,
                      color: CrevaColors.textTertiary,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Copy button
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: handoffText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    backgroundColor: CrevaColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: CrevaColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Copy Full Handoff Note',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _buildFullHandoff(SymptomEntry e) {
    final a = e.analysis;
    final buf = StringBuffer();
    buf.writeln('=== CREVA AI CLINICAL HANDOFF ===');
    buf.writeln('Date: ${_formatFull(e.timestamp)}');
    buf.writeln('Chief Complaint: ${e.symptoms.join(", ")}');
    buf.writeln('Duration: ${e.duration.label}');
    buf.writeln('Severity: ${e.severityScore}/10');
    if (e.description.isNotEmpty) {
      buf.writeln('Description: ${e.description}');
    }
    buf.writeln('Risk Level: ${e.riskLevel.name.toUpperCase()}');
    if (a != null) {
      buf.writeln('\nClinical Summary:\n${a.summary}');
      if (a.redFlags.isNotEmpty) {
        buf.writeln(
            '\nRed Flags:\n${a.redFlags.map((f) => "• $f").join("\n")}');
      }
      buf.writeln('\nDifferential Diagnoses:');
      for (var i = 0; i < a.conditions.length; i++) {
        final c = a.conditions[i];
        buf.writeln(
            '${i + 1}. ${c.name} (${(c.probability * 100).round()}%) — ${c.urgency}');
      }
      buf.writeln('\nRecommended Specialist: ${a.specialistType}');
      buf.writeln(
          '\nRecommendations:\n${a.recommendations.asMap().entries.map((e) => "${e.key + 1}. ${e.value}").join("\n")}');
      if (a.aiGeneratedHandoff.isNotEmpty) {
        buf.writeln('\n--- Formal Note ---\n${a.aiGeneratedHandoff}');
      }
    }
    buf.writeln(
        '\nDISCLAIMER: AI-generated, patient-reported. Not a clinical diagnosis.');
    return buf.toString();
  }

  Color _riskColor(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:
        return CrevaColors.success;
      case RiskLevel.medium:
        return const Color(0xFFF59E0B);
      case RiskLevel.high:
        return const Color(0xFFEF4444);
      case RiskLevel.emergency:
        return CrevaColors.urgencyEmergency;
    }
  }

  String _formatFull(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month]} ${d.day}, ${d.year} at $h:$m $period';
  }
}

class _HandoffSection extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HandoffSection({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CrevaColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? CrevaColors.textPrimary,
              height: 1.5,
              fontWeight:
                  valueColor != null ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
