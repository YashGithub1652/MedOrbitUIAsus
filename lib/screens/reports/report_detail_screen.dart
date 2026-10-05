// lib/screens/reports/report_detail_screen.dart

import 'package:creva/models/report_model.dart';
import 'package:creva/providers/reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class ReportDetailScreen extends ConsumerWidget {
  final String reportId;
  final bool isScan;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    this.isScan = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

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
          isScan ? 'Scan Details' : 'Report Details',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: CrevaColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: CrevaColors.error),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          final report = reports.where((r) => r.id == reportId).firstOrNull;

          if (report == null) {
            return _buildNotFound(context);
          }

          return _buildReportDetails(context, report);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(CrevaColors.primary),
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 60, color: CrevaColors.error),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                style: const TextStyle(color: CrevaColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.find_in_page_outlined,
            size: 80,
            color: CrevaColors.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Report Not Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CrevaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This report may have been deleted',
            style: TextStyle(color: CrevaColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/reports'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CrevaColors.primary,
            ),
            child: const Text('Go to Reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetails(BuildContext context, MedicalReport report) {
    final analysis = report.analysis ?? {};
    final hasAbnormal = report.hasAbnormalValues;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Report Header ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isScan
                          ? Icons.document_scanner_outlined
                          : Icons.description_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.date.toString().split(' ')[0],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasAbnormal
                      ? CrevaColors.warning.withOpacity(0.3)
                      : CrevaColors.success.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasAbnormal ? Icons.warning_amber : Icons.check_circle,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasAbnormal
                          ? '${report.abnormalParameters.length} Abnormal Values'
                          : 'All Values Normal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Analysis Summary ───────────────────────────────────────
        if (analysis['summary'] != null) ...[
          const _DetailSectionHeader(
              title: 'AI Summary', icon: Icons.psychology),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CrevaColors.border),
            ),
            child: Text(
              analysis['summary'] as String,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: CrevaColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Abnormal Values ────────────────────────────────────────
        if (report.hasAbnormalValues &&
            report.abnormalParameters.isNotEmpty) ...[
          _DetailSectionHeader(
            title: 'Abnormal Parameters (${report.abnormalParameters.length})',
            icon: Icons.warning_amber,
          ),
          const SizedBox(height: 12),
          ...report.abnormalParameters.map(
            (param) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CrevaColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CrevaColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: CrevaColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    param,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CrevaColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Recommendations ────────────────────────────────────────
        if (analysis['recommendations'] != null) ...[
          const _DetailSectionHeader(
            title: 'Recommendations',
            icon: Icons.lightbulb_outline,
          ),
          const SizedBox(height: 12),
          ...(analysis['recommendations'] as List).cast<String>().map(
                (rec) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CrevaColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: CrevaColors.primary.withOpacity(0.15)),
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
                          rec,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CrevaColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 24),
        ],

        // ── Disclaimer ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CrevaColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CrevaColors.warning.withOpacity(0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: CrevaColors.warning, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This AI analysis is for informational purposes only. '
                  'Consult a healthcare professional for medical advice.',
                  style: TextStyle(
                    fontSize: 12,
                    color: CrevaColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CrevaColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // await ref.read(reportsProvider.notifier).deleteReport(reportId);
      context.go('/reports');
    }
  }
}

class _DetailSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DetailSectionHeader({required this.title, required this.icon});

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
