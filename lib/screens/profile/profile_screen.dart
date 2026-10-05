import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isDark = ref.watch(themeProvider);

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined,
                  size: 64, color: CrevaColors.textTertiary),
              const SizedBox(height: 16),
              const Text('Not signed in'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final name = user.name;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Edit',
                style: TextStyle(
                    color: CrevaColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: CrevaColors.success,
                            shape: BoxShape.circle,
                            // ✅ FIXED: Use Border.all() for BoxDecoration
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProfileBadge(
                          label: 'Premium', icon: Icons.star),
                      SizedBox(width: 10),
                      _ProfileBadge(
                          label: 'Verified', icon: Icons.verified),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const _SectionHeader(title: 'Health Information'),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: user.age != null
                        ? '${user.age} years'
                        : 'Not set',
                  ),
                  _InfoTile(
                    icon: Icons.wc,
                    label: 'Gender',
                    value: user.gender ?? 'Not set',
                  ),
                  _InfoTile(
                    icon: Icons.bloodtype_outlined,
                    label: 'Blood Group',
                    value: user.bloodGroup ?? 'Not set',
                  ),
                  _InfoTile(
                    icon: Icons.warning_amber_outlined,
                    label: 'Allergies',
                    value: user.allergies.isNotEmpty
                        ? user.allergies.join(', ')
                        : 'None',
                  ),
                  _InfoTile(
                    icon: Icons.medication_outlined,
                    label: 'Medications',
                    value: user.medications.isNotEmpty
                        ? user.medications.join(', ')
                        : 'None',
                  ),
                  _InfoTile(
                    icon: Icons.history_edu_outlined,
                    label: 'Medical History',
                    value: user.medicalHistory.isNotEmpty
                        ? user.medicalHistory.join(', ')
                        : 'None',
                    isLast: true,
                  ),
                  const SizedBox(height: 20),

                  const _SectionHeader(title: 'Settings'),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    label: 'Dark Mode',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) =>
                          ref.read(themeProvider.notifier).toggle(),
                      activeThumbColor: CrevaColors.primary,
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.go('/notifications'),
                  ),
                  _SettingsTile(
                    icon: Icons.security_outlined,
                    label: 'Privacy & Security',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () {},
                    isLast: true,
                  ),
                  const SizedBox(height: 20),

                  // ✅ FIXED: Removed invalid Border cast
                  Container(
                    decoration: BoxDecoration(
                      color: CrevaColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CrevaColors.border),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout,
                          color: CrevaColors.error),
                      title: const Text('Sign Out',
                          style: TextStyle(
                              color: CrevaColors.error,
                              fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right,
                          color: CrevaColors.error),
                      onTap: () async {
                        await ref
                            .read(authProvider.notifier)
                            .logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: CrevaColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              CrevaColors.error.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever,
                          color: CrevaColors.error),
                      title: const Text('Delete Account',
                          style: TextStyle(
                              color: CrevaColors.error,
                              fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right,
                          color: CrevaColors.error),
                      onTap: () => _showDeleteDialog(context, ref),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('CREVA v1.0.0 • Build 100',
                      style: TextStyle(
                          color: CrevaColors.textTertiary,
                          fontSize: 11)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
            'This action cannot be undone. All your health data will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Delete',
                style: TextStyle(color: CrevaColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ProfileBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: CrevaColors.textPrimary)),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        // ✅ FIXED: Proper Border usage
        border: Border(
          left: const BorderSide(color: CrevaColors.border),
          right: const BorderSide(color: CrevaColors.border),
          top: const BorderSide(color: CrevaColors.border),
          bottom: isLast
              ? const BorderSide(color: CrevaColors.border)
              : BorderSide.none,
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(
                bottom: Radius.circular(14))
            : BorderRadius.zero,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: CrevaColors.primary, size: 20),
        title: Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: CrevaColors.textTertiary,
                fontWeight: FontWeight.w600)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 14,
                color: CrevaColors.textPrimary,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        // ✅ FIXED: Proper Border usage
        border: Border(
          left: const BorderSide(color: CrevaColors.border),
          right: const BorderSide(color: CrevaColors.border),
          top: const BorderSide(color: CrevaColors.border),
          bottom: isLast
              ? const BorderSide(color: CrevaColors.border)
              : BorderSide.none,
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(
                bottom: Radius.circular(14))
            : BorderRadius.zero,
      ),
      child: ListTile(
        leading: Icon(icon, color: CrevaColors.primary, size: 20),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: trailing ??
            const Icon(Icons.chevron_right,
                color: CrevaColors.textTertiary, size: 18),
        onTap: onTap,
      ),
    );
  }
}