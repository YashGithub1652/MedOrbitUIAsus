// lib/screens/reports/scan_analyzer_screen.dart

import 'package:creva/providers/reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../config/theme.dart';

class ScanAnalyzerScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final String scanType;

  const ScanAnalyzerScreen({
    super.key,
    required this.imageFile,
    this.scanType = 'X-Ray',
  });

  @override
  ConsumerState<ScanAnalyzerScreen> createState() => _ScanAnalyzerScreenState();
}

class _ScanAnalyzerScreenState extends ConsumerState<ScanAnalyzerScreen> {
  bool _isAnalyzing = true;
  bool _isSaving = false;
  Map<String, dynamic>? _fullResult;
  Map<String, dynamic>? _analysisData;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    try {
      final analysisService = ref.read(imageAnalysisServiceProvider);
      final result = await analysisService.analyzeScan(
        widget.imageFile,
        widget.scanType,
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          if (result['success'] == true) {
            _fullResult = result;
            // The analysis map is nested under 'analysis' key
            _analysisData = result['analysis'] as Map<String, dynamic>?;
          } else {
            _error = result['error'] as String? ?? 'Analysis failed';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _error = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _saveReport() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(reportsProvider.notifier).addReport(
            widget.imageFile,
            'scan',
          );
      if (mounted) {
        _showSuccessSnackBar('Scan saved to records successfully!');
        context.go('/reports');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: CrevaColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: CrevaColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/reports'),
        ),
        title: Text(
          '${widget.scanType} Analysis',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: CrevaColors.textPrimary,
          ),
        ),
        actions: [
          if (!_isAnalyzing && _analysisData != null)
            IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: CrevaColors.textPrimary),
              onPressed: () {
                // Share functionality
              },
            ),
        ],
      ),
      body: _isAnalyzing
          ? _buildAnalyzingView()
          : _error.isNotEmpty
              ? _buildErrorView()
              : _buildResultsView(),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ANALYZING VIEW
  // ══════════════════════════════════════════════════════════════════
  Widget _buildAnalyzingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Scanner
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: CrevaColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation(CrevaColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'AI Analyzing Scan...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: CrevaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our AI is carefully examining your scan\nfor detailed medical insights',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CrevaColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Progress Steps
            _buildProgressStep('📷 Processing image quality', true),
            _buildProgressStep('🔍 Identifying anatomical structures', true),
            _buildProgressStep('🤖 Running AI analysis', false),
            _buildProgressStep('📋 Generating report', false),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? CrevaColors.success : CrevaColors.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : Icons.circle,
              size: 14,
              color: isDone ? Colors.white : CrevaColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color:
                  isDone ? CrevaColors.textPrimary : CrevaColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ERROR VIEW
  // ══════════════════════════════════════════════════════════════════
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: CrevaColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: CrevaColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analysis Failed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CrevaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CrevaColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CrevaColors.error.withOpacity(0.2)),
              ),
              child: Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: CrevaColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/reports'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CrevaColors.primary,
                      side: const BorderSide(color: CrevaColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAnalyzing = true;
                        _error = '';
                      });
                      _performAnalysis();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CrevaColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // RESULTS VIEW
  // ══════════════════════════════════════════════════════════════════
  Widget _buildResultsView() {
    final analysis = _analysisData ?? {};
    final status = analysis['status'] as String? ?? 'requires_review';
    final findings = (analysis['findings'] as List?)?.cast<String>() ?? [];
    final recommendations =
        (analysis['recommendations'] as List?)?.cast<String>() ?? [];
    final confidence = analysis['confidence'] as double? ?? 0.0;
    final analysisText = analysis['analysis'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Image Preview ──────────────────────────────────────────
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                width: double.infinity,
                color: Colors.black87,
                child: Image.file(
                  widget.imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Scan type overlay
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      widget.scanType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Status & Confidence Row ────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(status),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildConfidenceCard(confidence),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── AI Analysis Summary ────────────────────────────────────
        if (analysisText.isNotEmpty) ...[
          const _SectionHeader(title: 'AI Analysis', icon: Icons.psychology),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CrevaColors.primary.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                )
              ],
            ),
            child: Text(
              analysisText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: CrevaColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Key Findings ───────────────────────────────────────────
        if (findings.isNotEmpty) ...[
          _SectionHeader(
            title: 'Key Findings (${findings.length})',
            icon: Icons.search,
          ),
          const SizedBox(height: 12),
          ...findings.asMap().entries.map(
                (entry) => _buildFindingItem(entry.value, entry.key),
              ),
          const SizedBox(height: 24),
        ],

        // ── Recommendations ────────────────────────────────────────
        if (recommendations.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recommendations (${recommendations.length})',
            icon: Icons.lightbulb_outline,
          ),
          const SizedBox(height: 12),
          ...recommendations.map((rec) => _buildRecommendationItem(rec)),
          const SizedBox(height: 24),
        ],

        // ── Disclaimer ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CrevaColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: CrevaColors.warning.withOpacity(0.3),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: CrevaColors.warning,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ This is an AI-assisted preliminary analysis only. '
                  'Please consult a qualified radiologist or medical '
                  'professional for accurate diagnosis and treatment decisions.',
                  style: TextStyle(
                    fontSize: 12,
                    color: CrevaColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Action Buttons ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/reports'),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Discard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CrevaColors.textSecondary,
                  side: const BorderSide(color: CrevaColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveReport,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_alt, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save to Records'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrevaColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusCard(String status) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CrevaColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                _getStatusIcon(status),
                size: 18,
                color: _getStatusColor(status),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(status),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(double confidence) {
    final percentage = (confidence * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrevaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confidence',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CrevaColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.bar_chart,
                size: 18,
                color: CrevaColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CrevaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: CrevaColors.border,
              color: CrevaColors.primary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingItem(String finding, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: CrevaColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CrevaColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              finding,
              style: const TextStyle(
                fontSize: 13,
                color: CrevaColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CrevaColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CrevaColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: CrevaColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 13,
                color: CrevaColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return CrevaColors.success;
      case 'abnormal':
        return CrevaColors.error;
      default:
        return CrevaColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return Icons.check_circle;
      case 'abnormal':
        return Icons.error;
      default:
        return Icons.warning_amber;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHARED WIDGET: Section Header
// ═══════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: CrevaColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: CrevaColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: CrevaColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
