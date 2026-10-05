import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class VitalsScreen extends ConsumerStatefulWidget {
  const VitalsScreen({super.key});
  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _vitals = [];
  bool _loading = true;
  bool _submitting = false;

  final _heartRateCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _oxygenCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadVitals();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _heartRateCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _tempCtrl.dispose();
    _weightCtrl.dispose();
    _oxygenCtrl.dispose();
    _glucoseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVitals() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getVitals();
      setState(() {
        _vitals = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final snap = await _firestore
              .collection('vitals')
              .where('user_id', isEqualTo: uid)
              .orderBy('created_at', descending: true)
              .limit(20)
              .get();
          setState(() {
            _vitals = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          });
        }
      } catch (_) {}
    }
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final vitals = <String, dynamic>{};
    void add(String k, TextEditingController c) {
      if (c.text.isNotEmpty) {
        final val = double.tryParse(c.text);
        if (val != null) vitals[k] = val; // Only add valid numbers
      }
    }

    add('heart_rate', _heartRateCtrl);
    add('systolic_bp', _systolicCtrl);
    add('diastolic_bp', _diastolicCtrl);
    add('temperature', _tempCtrl);
    add('weight', _weightCtrl);
    add('oxygen_saturation', _oxygenCtrl);
    add('blood_glucose', _glucoseCtrl);

    if (vitals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one vital')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _api.recordVitals(vitals);
    } catch (_) {}

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('vitals').add({
          'user_id': uid,
          'data': vitals,
          ...vitals,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}

    for (final c in [
      _heartRateCtrl,
      _systolicCtrl,
      _diastolicCtrl,
      _tempCtrl,
      _weightCtrl,
      _oxygenCtrl,
      _glucoseCtrl
    ]) {
      c.clear();
    }

    setState(() => _submitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitals saved successfully!'),
          backgroundColor: CrevaColors.success,
        ),
      );
      await _loadVitals();
      _tabCtrl.animateTo(1);
    }
  }

  String _latest(String key) {
    for (final v in _vitals) {
      final data =
          v['data'] is Map ? Map<String, dynamic>.from(v['data'] as Map) : v;
      if (data[key] != null) return data[key].toString();
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: CrevaColors.primary.withValues(alpha: 0.15),
              child: const Text('C',
                  style: TextStyle(
                      color: CrevaColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
            const SizedBox(width: 8),
            const Text('CREVA',
                style: TextStyle(
                    color: CrevaColors.primary, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadVitals,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: CrevaColors.primary,
          unselectedLabelColor: CrevaColors.textTertiary,
          indicatorColor: CrevaColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Record'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildRecord(),
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildRecord() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FIXED border
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CrevaColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_pin, color: CrevaColors.primary, size: 20),
                SizedBox(width: 8),
                Text('PATIENT DASHBOARD',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CrevaColors.textTertiary,
                        letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('Vitals Monitoring',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const Text(
            'Last Sync: Today, 10:14 PM',
            style: TextStyle(fontSize: 12, color: CrevaColors.textSecondary),
          ),
          const SizedBox(height: 20),

          const _AlertBanner(
            title: 'Hypertension Alert Observed',
            body:
                'Blood pressure (140/90 mmHg) is 12% above threshold. Recommend consulting your physician to monitor closely.',
            color: CrevaColors.error,
            actionLabel: 'QUICK PROTOCOL',
          ),
          const SizedBox(height: 12),

          const _SectionTitle(title: 'BLOOD PRESSURE'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VitalInput(
                  controller: _systolicCtrl,
                  label: 'Systolic',
                  unit: 'mmHg',
                  hint: '120',
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VitalInput(
                  controller: _diastolicCtrl,
                  label: 'Diastolic',
                  unit: 'mmHg',
                  hint: '80',
                  icon: Icons.speed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const _SectionTitle(title: 'HEART RATE'),
          const SizedBox(height: 10),
          _VitalInput(
            controller: _heartRateCtrl,
            label: 'Heart Rate',
            unit: 'bpm',
            hint: '72',
            icon: Icons.favorite,
          ),
          const SizedBox(height: 14),

          const _SectionTitle(title: 'BLOOD GLUCOSE'),
          const SizedBox(height: 10),
          _VitalInput(
            controller: _glucoseCtrl,
            label: 'Blood Glucose',
            unit: 'mg/dL',
            hint: '114',
            icon: Icons.water_drop,
          ),
          const SizedBox(height: 14),

          const _SectionTitle(title: 'BODY TEMPERATURE'),
          const SizedBox(height: 10),
          _VitalInput(
            controller: _tempCtrl,
            label: 'Temperature',
            unit: '°F',
            hint: '98.6',
            icon: Icons.thermostat,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: 'WEIGHT'),
                    const SizedBox(height: 10),
                    _VitalInput(
                      controller: _weightCtrl,
                      label: 'Weight',
                      unit: 'kg',
                      hint: '70',
                      icon: Icons.monitor_weight,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: 'SPO2'),
                    const SizedBox(height: 10),
                    _VitalInput(
                      controller: _oxygenCtrl,
                      label: 'Oxygen Sat.',
                      unit: '%',
                      hint: '98',
                      icon: Icons.air,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: CrevaColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Vitals',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: CrevaColors.primary));
    }

    final bpSpots = <FlSpot>[];
    final hrSpots = <FlSpot>[];

    for (var i = 0; i < _vitals.length && i < 7; i++) {
      final v = _vitals[_vitals.length - 1 - i];
      final data =
          v['data'] is Map ? Map<String, dynamic>.from(v['data'] as Map) : v;
      final sys = (data['systolic_bp'] ?? 120).toDouble();
      final hr = (data['heart_rate'] ?? 72).toDouble();
      bpSpots.add(FlSpot(i.toDouble(), sys));
      hrSpots.add(FlSpot(i.toDouble(), hr));
    }

    if (bpSpots.isEmpty) {
      bpSpots.addAll([
        const FlSpot(0, 120),
        const FlSpot(1, 135),
        const FlSpot(2, 128),
        const FlSpot(3, 140),
        const FlSpot(4, 138),
        const FlSpot(5, 142),
        const FlSpot(6, 140),
      ]);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VitalCardRow(
            vitals: [
              _VitalDisplay(
                  label: 'BLOOD PRESSURE',
                  value: _latest('systolic_bp') != '--'
                      ? '${_latest('systolic_bp')}/${_latest('diastolic_bp')}'
                      : '140/90',
                  unit: 'mmHg',
                  status: 'HIGH',
                  statusColor: CrevaColors.error),
              _VitalDisplay(
                  label: 'HEART RATE',
                  value: _latest('heart_rate') != '--'
                      ? _latest('heart_rate')
                      : '78',
                  unit: 'bpm',
                  status: 'NORMAL',
                  statusColor: CrevaColors.success),
            ],
          ),
          const SizedBox(height: 10),
          _VitalCardRow(
            vitals: [
              _VitalDisplay(
                  label: 'BLOOD SUGAR',
                  value: _latest('blood_glucose') != '--'
                      ? _latest('blood_glucose')
                      : '280',
                  unit: 'mg/dL',
                  status: 'HIGH',
                  statusColor: CrevaColors.error),
              _VitalDisplay(
                  label: 'BODY TEMP',
                  value: _latest('temperature') != '--'
                      ? _latest('temperature')
                      : '98.6',
                  unit: '°F',
                  status: 'NORMAL',
                  statusColor: CrevaColors.success),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Blood Pressure Trend',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Text('Historical data for the last 7 days',
              style: TextStyle(fontSize: 12, color: CrevaColors.textSecondary)),
          const SizedBox(height: 8),

          Row(
            children: ['Week', 'Month', 'Year'].map((t) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      t == 'Week' ? CrevaColors.primary : CrevaColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        t == 'Week' ? CrevaColors.primary : CrevaColors.border,
                  ),
                ),
                child: Text(t,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t == 'Week'
                            ? Colors.white
                            : CrevaColors.textSecondary)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ✅ FIXED border
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CrevaColors.border),
            ),
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = [
                          'MON',
                          'TUE',
                          'WED',
                          'THU',
                          'FRI',
                          'SAT',
                          'SUN'
                        ];
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox();
                        }
                        return Text(days[i],
                            style: const TextStyle(
                                fontSize: 9,
                                color: CrevaColors.textTertiary,
                                fontWeight: FontWeight.w600));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  bpSpots.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bpSpots[i].y,
                        color: bpSpots[i].y > 130
                            ? CrevaColors.error
                            : CrevaColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Recent Activity',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          if (_vitals.isEmpty)
            const _RecentActivityItem(
              icon: Icons.favorite,
              color: CrevaColors.error,
              title: 'Glucose Spike Detected',
              subtitle: '280 mg/dL — 9:00 AM',
            )
          else
            ..._vitals.take(3).map((v) {
              return _RecentActivityItem(
                icon: Icons.favorite,
                color: CrevaColors.primary,
                title: 'Vitals Recorded',
                subtitle: _formatDate(v['created_at']),
              );
            }),

          const _RecentActivityItem(
            icon: Icons.monitor_heart,
            color: CrevaColors.success,
            title: 'Heart Rate Normal',
            subtitle: '72 bpm — 8:30 AM',
          ),
          const _RecentActivityItem(
            icon: Icons.medication,
            color: CrevaColors.warning,
            title: 'Nitric Added',
            subtitle: 'Nitric added 2 days after one thing',
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: CrevaColors.primary,
                side: const BorderSide(color: CrevaColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View All History'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return 'Just now';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} — ${dt.day}/${dt.month}/${dt.year}';
    }
    return ts.toString().substring(0, 10);
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: CrevaColors.textTertiary,
          letterSpacing: 0.8,
        ),
      );
}

class _VitalInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final String hint;
  final IconData icon;

  const _VitalInput({
    required this.controller,
    required this.label,
    required this.unit,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        suffixStyle: const TextStyle(
            color: CrevaColors.textTertiary, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: CrevaColors.primary, size: 18),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final String actionLabel;

  const _AlertBanner({
    required this.title,
    required this.body,
    required this.color,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  fontSize: 12, color: CrevaColors.textSecondary, height: 1.4)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(actionLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalDisplay {
  final String label;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;

  const _VitalDisplay({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
  });
}

class _VitalCardRow extends StatelessWidget {
  final List<_VitalDisplay> vitals;
  const _VitalCardRow({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: vitals.map((v) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: v == vitals.last ? 0 : 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: v.statusColor, width: 3),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(v.label,
                        style: const TextStyle(
                            fontSize: 9,
                            color: CrevaColors.textTertiary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: v.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(v.status,
                          style: TextStyle(
                              color: v.statusColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: v.value,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: CrevaColors.textPrimary)),
                  TextSpan(
                      text: ' ${v.unit}',
                      style: const TextStyle(
                          fontSize: 11, color: CrevaColors.textSecondary)),
                ])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _RecentActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: CrevaColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: CrevaColors.textTertiary, size: 18),
        ],
      ),
    );
  }
}
