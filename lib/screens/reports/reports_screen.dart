// lib/screens/reports/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../providers/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedScanFilter = 'All';
  final List<String> _scanFilters = [
    'All',
    'X-Ray',
    'MRI',
    'CT Scan',
    'Ultrasound'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════
  // IMAGE PICKING
  // ════════════════════════════════════════════════════════════════════
  Future<void> _pickReport() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image != null && mounted) {
      context.push('/reports/analyze', extra: File(image.path));
    }
  }

  Future<void> _pickScan(ImageSource source, String scanType) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (image != null && mounted) {
      context.push(
        '/scan/analyze?type=$scanType',
        extra: File(image.path),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: CrevaColors.textPrimary,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text(
          'Medical Reports & Scans',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: CrevaColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_outlined,
              color: CrevaColors.textPrimary,
            ),
            onPressed: () {
              // search
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: CrevaColors.primary,
                indicatorWeight: 3,
                labelColor: CrevaColors.primary,
                unselectedLabelColor: CrevaColors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: '📄  Reports'),
                  Tab(text: '🩻  Scans'),
                ],
              ),
              const Divider(height: 1, color: CrevaColors.border),
            ],
          ),
        ),
      ),

      // ── Body ──────────────────────────────────────────────────────
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildScansTab(),
        ],
      ),

      // ── FAB ───────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadOptions,
        backgroundColor: CrevaColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text(
          'Upload',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // REPORTS TAB
  // ════════════════════════════════════════════════════════════════════
  Widget _buildReportsTab() {
    final reportsAsync = ref.watch(reportsProvider);

    return reportsAsync.when(
      data: (reports) {
        final labReports =
            reports.where((r) => r.type == 'lab_report').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats Card
            _buildStatsCard(
              total: reports.length,
              thisMonth: reports
                  .where((r) => r.date.month == DateTime.now().month)
                  .length,
              abnormal: reports.where((r) => r.hasAbnormalValues).length,
            ),
            const SizedBox(height: 20),

            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CrevaColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: CrevaColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (labReports.isEmpty)
              _buildEmptyState(
                icon: Icons.description_outlined,
                title: 'No Reports Yet',
                subtitle:
                    'Upload your first medical report\nto get AI analysis',
                buttonLabel: 'Upload Report',
                onTap: _pickReport,
              )
            else
              ...labReports.map(
                (report) => _buildReportCard(
                  title: report.title,
                  date: _formatDate(report.date),
                  type: report.type,
                  hasAbnormal: report.hasAbnormalValues,
                  abnormalCount: report.abnormalParameters.length,
                  onTap: () => context.go('/reports/detail/${report.id}'),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(CrevaColors.primary),
        ),
      ),
      error: (e, _) => _buildError(e.toString()),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // SCANS TAB
  // ════════════════════════════════════════════════════════════════════
  Widget _buildScansTab() {
    final reportsAsync = ref.watch(reportsProvider);

    return reportsAsync.when(
      data: (reports) {
        var scans = reports.where((r) => r.type == 'scan').toList();

        if (_selectedScanFilter != 'All') {
          scans = scans
              .where((r) =>
                  (r.analysis?['scan_type'] as String? ?? '') ==
                  _selectedScanFilter)
              .toList();
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Scan Type Filter
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _scanFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _scanFilters[index];
                  final isSelected = _selectedScanFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedScanFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CrevaColors.primary
                            : CrevaColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? CrevaColors.primary
                              : CrevaColors.border,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : CrevaColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Upload Scan Options
            _buildScanUploadGrid(),
            const SizedBox(height: 20),

            const Text(
              'Recent Scans',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CrevaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (scans.isEmpty)
              _buildEmptyState(
                icon: Icons.document_scanner_outlined,
                title: 'No Scans Yet',
                subtitle: 'Upload your X-ray, MRI or CT scan\nfor AI analysis',
                buttonLabel: 'Upload Scan',
                onTap: () => _pickScan(ImageSource.gallery, 'X-Ray'),
              )
            else
              ...scans.map(
                (scan) => _buildScanCard(
                  title: scan.title,
                  date: _formatDate(scan.date),
                  type: scan.analysis?['scan_type'] as String? ?? 'Scan',
                  status: scan.analysis?['status'] as String? ?? 'Analyzed',
                  onTap: () => context.go('/scan/detail/${scan.id}'),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(CrevaColors.primary),
        ),
      ),
      error: (e, _) => _buildError(e.toString()),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // UPLOAD GRID FOR SCANS
  // ════════════════════════════════════════════════════════════════════
  Widget _buildScanUploadGrid() {
    final scanTypes = [
      {
        'label': 'X-Ray',
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFF06B6D4),
      },
      {
        'label': 'MRI',
        'icon': Icons.scanner_outlined,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'label': 'CT Scan',
        'icon': Icons.radar_outlined,
        'color': const Color(0xFFF59E0B),
      },
      {
        'label': 'Ultrasound',
        'icon': Icons.monitor_heart_outlined,
        'color': const Color(0xFF10B981),
      },
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: scanTypes.map((type) {
        final color = type['color'] as Color;
        return GestureDetector(
          onTap: () => _pickScan(
            ImageSource.gallery,
            type['label'] as String,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type['icon'] as IconData,
                  color: color,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  type['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // STATS CARD
  // ════════════════════════════════════════════════════════════════════
  Widget _buildStatsCard({
    required int total,
    required int thisMonth,
    required int abnormal,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '$total', Icons.folder_outlined),
          _buildStatDivider(),
          _buildStatItem(
              'This Month', '$thisMonth', Icons.calendar_today_outlined),
          _buildStatDivider(),
          _buildStatItem('Abnormal', '$abnormal', Icons.warning_amber_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.white24,
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // REPORT CARD
  // ════════════════════════════════════════════════════════════════════
  Widget _buildReportCard({
    required String title,
    required String date,
    required String type,
    required bool hasAbnormal,
    required int abnormalCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CrevaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: hasAbnormal
              ? Border.all(
                  color: CrevaColors.warning.withOpacity(0.5),
                  width: 1.5,
                )
              : Border.all(color: CrevaColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasAbnormal
                    ? CrevaColors.warning.withOpacity(0.1)
                    : CrevaColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasAbnormal
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: hasAbnormal ? CrevaColors.warning : CrevaColors.success,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CrevaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Lab Report',
                        style: TextStyle(
                          fontSize: 12,
                          color: CrevaColors.textSecondary,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: CrevaColors.textTertiary),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CrevaColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (hasAbnormal) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CrevaColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$abnormalCount abnormal value${abnormalCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CrevaColors.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: CrevaColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // SCAN CARD
  // ════════════════════════════════════════════════════════════════════
  Widget _buildScanCard({
    required String title,
    required String date,
    required String type,
    required String status,
    required VoidCallback onTap,
  }) {
    final isNormal = status.toLowerCase() == 'normal';
    final statusColor = isNormal ? CrevaColors.success : CrevaColors.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CrevaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CrevaColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Scan thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                color: Color(0xFF06B6D4),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CrevaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CrevaColors.textSecondary,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: CrevaColors.textTertiary),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CrevaColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: CrevaColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: CrevaColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 45, color: CrevaColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CrevaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: CrevaColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(buttonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: CrevaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: CrevaColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: CrevaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // UPLOAD OPTIONS BOTTOM SHEET
  // ════════════════════════════════════════════════════════════════════
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CrevaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CrevaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Upload Medical Document',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CrevaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose document type to upload',
                style: TextStyle(
                  fontSize: 13,
                  color: CrevaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Options
              _buildUploadOption(
                icon: Icons.description_outlined,
                title: 'Lab Report / Prescription',
                subtitle: 'PDF or image of your medical report',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  _pickReport();
                },
              ),
              const SizedBox(height: 12),
              _buildUploadOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take Photo of Scan',
                subtitle: 'Camera - X-ray, MRI, CT scan',
                color: const Color(0xFF06B6D4),
                onTap: () {
                  Navigator.pop(context);
                  _showScanTypeSelector(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildUploadOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose Scan from Gallery',
                subtitle: 'Select existing scan image',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  _showScanTypeSelector(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CrevaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CrevaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // SCAN TYPE SELECTOR
  // ════════════════════════════════════════════════════════════════════
  void _showScanTypeSelector(ImageSource source) {
    final scanTypes = [
      {
        'label': 'X-Ray',
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFF06B6D4)
      },
      {
        'label': 'MRI',
        'icon': Icons.scanner_outlined,
        'color': const Color(0xFF8B5CF6)
      },
      {
        'label': 'CT Scan',
        'icon': Icons.radar_outlined,
        'color': const Color(0xFFF59E0B)
      },
      {
        'label': 'Ultrasound',
        'icon': Icons.monitor_heart_outlined,
        'color': const Color(0xFF10B981)
      },
      {
        'label': 'Mammogram',
        'icon': Icons.favorite_outlined,
        'color': const Color(0xFFEF4444)
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: CrevaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CrevaColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Scan Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CrevaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...scanTypes.map((type) {
                final color = type['color'] as Color;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      type['icon'] as IconData,
                      color: color,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    type['label'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CrevaColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: CrevaColors.textTertiary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickScan(source, type['label'] as String);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════
  String _formatDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
