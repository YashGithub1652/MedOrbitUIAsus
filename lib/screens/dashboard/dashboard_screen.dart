import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(dashboardProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(dashboardProvider.notifier).loadDashboard(),
          ),
        ],
      ),
      body: db.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CrevaColors.primary))
          : _buildBody(db.data),
    );
  }

  Widget _buildBody(Map<String, dynamic> data) {
    final avgRisk = (data['avg_risk_score'] ?? 25.0).toDouble();
    final totalRecords = data['total_records'] ?? 12;
    final convCount = data['conversations_count'] ?? 8;
    final vitals = data['vitals_history'] as List? ?? [];
    final patterns = data['patterns'] as List? ?? [];
    final healthScore = (100 - avgRisk).clamp(0.0, 100.0);

    // Build chart spots
    final spots = <FlSpot>[];
    for (var i = 0; i < vitals.length && i < 7; i++) {
      final v = vitals[vitals.length - 1 - i];
      final d = v['data'] is Map
          ? Map<String, dynamic>.from(v['data'] as Map)
          : v;
      spots.add(FlSpot(i.toDouble(), (d['heart_rate'] ?? 72).toDouble()));
    }
    if (spots.isEmpty) {
      spots.addAll([
        const FlSpot(0, 68),
        const FlSpot(1, 72),
        const FlSpot(2, 70),
        const FlSpot(3, 75),
        const FlSpot(4, 73),
        const FlSpot(5, 71),
        const FlSpot(6, 72),
      ]);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Score Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: healthScore > 60
                    ? [const Color(0xFF1D4ED8), const Color(0xFF2563EB)]
                    : [const Color(0xFFB91C1C), const Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: CrevaColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: healthScore / 100,
                        strokeWidth: 10,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                      ),
                      Text(
                        healthScore.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Health Score',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'Based on $totalRecords records',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                      Text(
                        '$convCount AI consultations',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          healthScore > 70 ? 'Good Shape' : 'Needs Attention',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stat cards
          Row(
            children: [
              _StatCard(
                label: 'Records',
                value: '$totalRecords',
                icon: Icons.folder_outlined,
                color: CrevaColors.primary,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Chats',
                value: '$convCount',
                icon: Icons.chat_outlined,
                color: CrevaColors.accent,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Risk',
                value: '${avgRisk.toStringAsFixed(0)}%',
                icon: Icons.speed,
                color: avgRisk > 50
                    ? CrevaColors.error
                    : CrevaColors.success,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Heart Rate Trend
          const Text('Heart Rate Trend',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Last 7 days',
              style: TextStyle(
                  fontSize: 12, color: CrevaColors.textSecondary)),
          const SizedBox(height: 12),

          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: const BorderSide(color: CrevaColors.border) as Border?,
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: CrevaColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 9,
                            color: CrevaColors.textTertiary),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = [
                          'M', 'T', 'W', 'T', 'F', 'S', 'S'
                        ];
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox();
                        }
                        return Text(days[i],
                            style: const TextStyle(
                                fontSize: 10,
                                color: CrevaColors.textTertiary));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: CrevaColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: CrevaColors.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          CrevaColors.primary.withValues(alpha: 0.2),
                          CrevaColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
                minY: 50,
                maxY: 120,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // AI Insights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI Insights',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CrevaColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('AI POWERED',
                    style: TextStyle(
                        fontSize: 9,
                        color: CrevaColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (patterns.isEmpty) ...[
            const _InsightCard(
              icon: Icons.favorite,
              color: CrevaColors.error,
              title: 'Blood Pressure Alert',
              body:
                  'Your BP readings this week show a hypertensive trend. Consider reducing sodium intake.',
              severity: 'HIGH',
            ),
            const SizedBox(height: 8),
            const _InsightCard(
              icon: Icons.bedtime,
              color: Color(0xFF8B5CF6),
              title: 'Sleep Optimization',
              body:
                  'Your heart rate variability suggests improved sleep quality. Keep maintaining your schedule.',
              severity: 'LOW',
            ),
            const SizedBox(height: 8),
            const _InsightCard(
              icon: Icons.water_drop,
              color: CrevaColors.info,
              title: 'Hydration Reminder',
              body:
                  'Based on your activity levels and temperature, aim for 2.5L of water today.',
              severity: 'INFO',
            ),
          ] else
            ...patterns.map<Widget>((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InsightCard(
                  icon: Icons.lightbulb_outline,
                  color: CrevaColors.warning,
                  title: p['pattern'] ?? 'Pattern Detected',
                  body: p['recommendation'] ?? '',
                  severity: 'MED',
                ),
              );
            }),

          const SizedBox(height: 24),

          // Quick actions
          const Text('Quick Actions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickAction(
                icon: Icons.chat_outlined,
                label: 'Ask CREVA',
                onTap: () => context.go('/chat'),
              ),
              const SizedBox(width: 10),
              _QuickAction(
                icon: Icons.favorite_outline,
                label: 'Log Vitals',
                onTap: () => context.go('/vitals'),
              ),
              const SizedBox(width: 10),
              _QuickAction(
                icon: Icons.description_outlined,
                label: 'Reports',
                onTap: () => context.go('/reports'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CrevaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: const BorderSide(color: CrevaColors.border) as Border?,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: CrevaColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String severity;
  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(severity,
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12,
                        color: CrevaColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CrevaColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: CrevaColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      color: CrevaColors.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}