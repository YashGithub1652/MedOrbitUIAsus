import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});
  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final List<_Med> _meds = [
    _Med(name: 'Lisinopril', dose: '10mg · With food', time: '8:00 AM', period: 'MORNING', taken: true, color: const Color(0xFF3B82F6)),
    _Med(name: 'Atorvastatin', dose: '20mg · After lunch', time: '1:00 PM', period: 'AFTERNOON', taken: false, color: const Color(0xFFF59E0B)),
    _Med(name: 'Metformin', dose: '500mg', time: '8:00 PM', period: 'EVENING', taken: false, color: const Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    final taken = _meds.where((m) => m.taken).length;
    final adherence = (taken / _meds.length * 100).round();

    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adherence ring card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CrevaColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80, height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: adherence / 100,
                          strokeWidth: 8,
                          backgroundColor: CrevaColors.border,
                          color: CrevaColors.primary,
                          strokeCap: StrokeCap.round,
                        ),
                        Text('$adherence%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: CrevaColors.textPrimary,
                          )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.local_fire_department, color: CrevaColors.warning, size: 18),
                          SizedBox(width: 4),
                          Text('14 DAY STREAK',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: CrevaColors.warning, letterSpacing: 0.5,
                            )),
                        ]),
                        SizedBox(height: 6),
                        Text("You're on a roll!",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        SizedBox(height: 4),
                        Text(
                          'Your adherence is 12% higher than last month. Keep it up!',
                          style: TextStyle(
                            fontSize: 12, color: CrevaColors.textSecondary, height: 1.4,
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Schedule header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Schedule",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CrevaColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('TUESDAY, OCT 24',
                    style: TextStyle(
                      fontSize: 10, color: CrevaColors.primary,
                      fontWeight: FontWeight.w700, letterSpacing: 0.5,
                    )),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._buildSchedule(),
            const SizedBox(height: 24),

            // All Medications header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All Medications',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All',
                    style: TextStyle(color: CrevaColors.primary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // AR scan card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: CrevaColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AR Smart Scan',
                          style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15,
                          )),
                        SizedBox(height: 4),
                        Text('Identify medication using your camera.',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Refill Scan', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Inventory tracking
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CrevaColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CrevaColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: CrevaColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inventory Tracking',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('3 medications running low. Auto refill is active.',
                          style: TextStyle(fontSize: 12, color: CrevaColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: CrevaColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: CrevaColors.surface,
        border: Border(top: BorderSide(color: CrevaColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, 'Home', () => context.go('/home')),
              _navItem(Icons.chat_outlined, 'Chat', () => context.go('/chat')),
              const SizedBox(width: 48),
              _navItem(Icons.favorite_outline, 'Vitals', () => context.go('/vitals')),
              _navItem(Icons.person_outline, 'Profile', () => context.go('/profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CrevaColors.textTertiary, size: 22),
            const SizedBox(height: 2),
            Text(label,
              style: const TextStyle(
                fontSize: 10,
                color: CrevaColors.textTertiary,
                fontWeight: FontWeight.w500,
              )),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSchedule() {
    final grouped = <String, List<_Med>>{};
    for (final m in _meds) {
      grouped.putIfAbsent(m.period, () => []).add(m);
    }
    final widgets = <Widget>[];
    for (final period in ['MORNING', 'AFTERNOON', 'EVENING']) {
      final list = grouped[period];
      if (list == null) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: _periodColor(period), shape: BoxShape.circle,
            )),
          const SizedBox(width: 8),
          Text(period,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: CrevaColors.textTertiary, letterSpacing: 0.5,
            )),
        ]),
      ));

      for (final med in list) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: med.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication, color: med.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(med.dose,
                        style: const TextStyle(fontSize: 12, color: CrevaColors.textSecondary)),
                    ],
                  ),
                ),
                Text(med.time,
                  style: const TextStyle(fontSize: 12, color: CrevaColors.textTertiary)),
                const SizedBox(width: 8),
                if (med.taken)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: CrevaColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Taken',
                      style: TextStyle(
                        color: CrevaColors.success, fontSize: 12, fontWeight: FontWeight.w600,
                      )),
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => med.taken = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: CrevaColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Mark as\nTaken',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.w600, height: 1.3,
                        )),
                    ),
                  ),
              ],
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  Color _periodColor(String p) {
    switch (p) {
      case 'MORNING': return const Color(0xFFF59E0B);
      case 'AFTERNOON': return CrevaColors.primary;
      default: return const Color(0xFF8B5CF6);
    }
  }
}

class _Med {
  final String name;
  final String dose;
  final String time;
  final String period;
  bool taken;
  final Color color;
  _Med({
    required this.name, required this.dose, required this.time,
    required this.period, required this.taken, required this.color,
  });
}
