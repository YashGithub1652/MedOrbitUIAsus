import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth.user?.name ?? 'User';
    final firstName = name.split(' ').first;

    return Scaffold(
      backgroundColor: CrevaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          CrevaColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: CrevaColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CREVA',
                    style: TextStyle(
                      color: CrevaColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.go('/notifications'),
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: CrevaColors.textPrimary),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: CrevaColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Greeting ─────────────────────────────────────────────────
              const Text(
                'DAILY BRIEFING',
                style: TextStyle(
                  color: CrevaColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Good Morning, $firstName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: CrevaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your vitals are looking stable today. You have 2 medications scheduled for this afternoon.',
                style: TextStyle(
                  fontSize: 13,
                  color: CrevaColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // ── Health Score Ring ─────────────────────────────────────────
              const Center(
                child: _HealthScoreRing(score: 85),
              ),
              const SizedBox(height: 20),

              // ── Emergency Button ──────────────────────────────────────────
              GestureDetector(
                onTap: () => context.go('/emergency'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: CrevaColors.urgencyEmergency,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '⚡ EMERGENCY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Today's Summary ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Summary",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => context.go('/dashboard'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'View History',
                      style:
                          TextStyle(color: CrevaColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const _SummaryCard(
                icon: Icons.medication,
                iconBg: Color(0xFFEFF6FF),
                iconColor: CrevaColors.primary,
                label: 'NEXT MED',
                title: 'Metformin • 2:00 PM',
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: _MetricMiniCard(
                      label: 'BLOOD SUGAR',
                      value: '114',
                      unit: 'g/dL',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _MetricMiniCard(
                      label: 'DAILY STEPS',
                      value: '4,281',
                      unit: 'stp',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Health Domains ────────────────────────────────────────────
              const Text(
                'Health Domains',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _DomainIcon(
                    icon: Icons.psychology_outlined,
                    label: 'Symptom',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.go('/symptoms'),
                  ),
                  _DomainIcon(
                    icon: Icons.medication_outlined,
                    label: 'Meds',
                    color: const Color(0xFFEC4899),
                    onTap: () => context.go('/medications'),
                  ),
                  _DomainIcon(
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan',
                    color: const Color(0xFF06B6D4),
                    onTap: () => context.go('/reports'), // ✅ Updated
                  ),
                  _DomainIcon(
                    icon: Icons.self_improvement,
                    label: 'Mental',
                    color: const Color(0xFF10B981),
                    onTap: () => context.go('/chat?mode=mental'),
                  ),
                  _DomainIcon(
                    icon: Icons.restaurant_menu,
                    label: 'Diet',
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.go('/chat?mode=diet'),
                  ),
                  _DomainIcon(
                    icon: Icons.fitness_center,
                    label: 'Fitness',
                    color: const Color(0xFFEF4444),
                    onTap: () => context.go('/chat?mode=fitness'),
                  ),
                  _DomainIcon(
                    icon: Icons.favorite_outlined,
                    label: 'Vitals',
                    color: const Color(0xFF3B82F6),
                    onTap: () => context.go('/vitals'),
                  ),
                  _DomainIcon(
                    icon: Icons.emergency_outlined,
                    label: 'Emergency',
                    color: const Color(0xFFDC2626),
                    onTap: () => context.go('/emergency'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Activity ───────────────────────────────────────────
              const Text(
                'Recent Activity',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const _ActivityItem(
                color: CrevaColors.primary,
                title: 'Morning Medication Taken',
                subtitle: 'Lisinopril · 8:00 AM',
                time: '8:00 AM',
              ),
              const _ActivityItem(
                color: CrevaColors.success,
                title: 'Automatic Vital Scan',
                subtitle: 'Eagle Watch · 7:15 AM',
                time: '7:15 AM',
              ),
              const _ActivityItem(
                color: Color(0xFFF59E0B),
                title: '5k Achieved Today!',
                subtitle: 'Daily goal added · 7:00 PM',
                time: '7:00 PM',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      // ── Bottom Nav ──────────────────────────────────────────────────────
      bottomNavigationBar: _CrevaBottomNav(
        current: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          switch (i) {
            case 0:
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/vitals');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}

// ── Health Score Ring ─────────────────────────────────────────────────────────
class _HealthScoreRing extends StatelessWidget {
  final int score;
  const _HealthScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: CrevaColors.border,
              color: CrevaColors.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: CrevaColors.textPrimary,
                ),
              ),
              const Text(
                'HEALTH\nSCORE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: CrevaColors.textTertiary,
                  letterSpacing: 0.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String title;

  const _SummaryCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(14),
        // ✅ FIXED: Use Border() not BorderSide cast
        border: const Border(
          left: BorderSide(color: CrevaColors.primary, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: CrevaColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Metric Mini Card ──────────────────────────────────────────────────────────
class _MetricMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricMiniCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: CrevaColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: CrevaColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CrevaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Domain Icon ───────────────────────────────────────────────────────────────
class _DomainIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DomainIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CrevaColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Activity Item ─────────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: CrevaColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            time,
            style:
                const TextStyle(fontSize: 11, color: CrevaColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _CrevaBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _CrevaBottomNav({
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CrevaColors.surface,
        border: Border(top: BorderSide(color: CrevaColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                active: current == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.chat_outlined,
                activeIcon: Icons.chat,
                label: 'Chat',
                active: current == 1,
                onTap: () => onTap(1),
              ),
              _NavAddButton(onTap: () {}),
              _NavItem(
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: 'Vitals',
                active: current == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                active: current == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? CrevaColors.primary : CrevaColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? CrevaColors.primary : CrevaColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NavAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: CrevaColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
