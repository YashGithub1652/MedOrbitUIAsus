// lib/screens/health/health_records_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _records = [
    {
      'title': 'Annual Physical Exam',
      'doctor': 'Dr. Sarah Johnson',
      'date': 'Dec 15, 2024',
      'type': 'Consultation',
      'status': 'Completed',
      'icon': Icons.medical_services_outlined,
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Blood Test Results',
      'doctor': 'City Lab Center',
      'date': 'Nov 28, 2024',
      'type': 'Lab Result',
      'status': 'Normal',
      'icon': Icons.biotech_outlined,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Chest X-Ray',
      'doctor': 'RadiologyPlus',
      'date': 'Oct 10, 2024',
      'type': 'Imaging',
      'status': 'Normal',
      'icon': Icons.document_scanner_outlined,
      'color': const Color(0xFF06B6D4),
    },
    {
      'title': 'Cardiology Consultation',
      'doctor': 'Dr. Michael Brown',
      'date': 'Sep 5, 2024',
      'type': 'Specialist',
      'status': 'Follow-up',
      'icon': Icons.favorite_outlined,
      'color': const Color(0xFFEF4444),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text(
          'Health Records',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: CrevaColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CrevaColors.primary,
          labelColor: CrevaColors.primary,
          unselectedLabelColor: CrevaColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Labs'),
            Tab(text: 'Imaging'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordsList(_records),
          _buildRecordsList(
            _records.where((r) => r['type'] == 'Lab Result').toList(),
          ),
          _buildRecordsList(
            _records.where((r) => r['type'] == 'Imaging').toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 80,
              color: CrevaColors.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              'No records found',
              style: TextStyle(
                fontSize: 16,
                color: CrevaColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final color = record['color'] as Color;
    final status = record['status'] as String;
    final statusColor = status == 'Normal' || status == 'Completed'
        ? CrevaColors.success
        : status == 'Follow-up'
            ? CrevaColors.warning
            : CrevaColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(16),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              record['icon'] as IconData,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CrevaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record['doctor'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CrevaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      record['date'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CrevaColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: CrevaColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arrow
          const Icon(
            Icons.chevron_right,
            color: CrevaColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
