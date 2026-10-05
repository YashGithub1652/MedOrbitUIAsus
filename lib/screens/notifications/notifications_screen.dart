import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final notifs = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              for (final n in notifs.notifications) {
                if (!(n['is_read'] ?? false)) {
                  ref
                      .read(notificationProvider.notifier)
                      .markRead(n['id']?.toString() ?? '');
                }
              }
            },
            child: const Text('Mark All Read',
                style: TextStyle(
                    color: CrevaColors.primary, fontSize: 12)),
          ),
        ],
      ),
      body: notifs.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: CrevaColors.primary))
          : notifs.notifications.isEmpty
              ? _buildEmpty()
              : _buildList(notifs.notifications),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: CrevaColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none,
                size: 40, color: CrevaColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('All caught up!',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Health alerts and reminders\nwill appear here.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: CrevaColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> notifications) {
    // Group by date (simplified)
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _DateLabel(label: 'TODAY'),
        const SizedBox(height: 8),
        ...notifications.map((n) {
          final isRead = n['is_read'] ?? false;
          final type = n['type'] ?? '';

          return Dismissible(
            key: Key('notif_${n['id'] ?? notifications.indexOf(n)}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: CrevaColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: CrevaColors.success),
            ),
            onDismissed: (_) => ref
                .read(notificationProvider.notifier)
                .markRead(n['id']?.toString() ?? ''),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isRead
                    ? CrevaColors.surface
                    : CrevaColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRead
                      ? CrevaColors.border
                      : CrevaColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _typeColor(type).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _typeIcon(type),
                    color: _typeColor(type),
                    size: 22,
                  ),
                ),
                title: Text(
                  n['title'] ?? 'Notification',
                  style: TextStyle(
                    fontWeight: isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
                    fontSize: 14,
                    color: CrevaColors.textPrimary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    n['body'] ?? '',
                    style: const TextStyle(
                        fontSize: 12,
                        color: CrevaColors.textSecondary,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Now',
                        style: TextStyle(
                            fontSize: 10,
                            color: CrevaColors.textTertiary)),
                    const SizedBox(height: 6),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: CrevaColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Demo notifications when list is short
        if (notifications.length < 3) ...[
          const SizedBox(height: 8),
          const _DateLabel(label: 'YESTERDAY'),
          const SizedBox(height: 8),
          const _DemoNotif(
            icon: Icons.medication,
            color: CrevaColors.primary,
            title: 'Medication Reminder',
            body: 'Time to take Lisinopril 10mg with food.',
            time: '8:00 AM',
            isRead: true,
          ),
          const _DemoNotif(
            icon: Icons.favorite,
            color: CrevaColors.error,
            title: 'Vitals Alert',
            body:
                'Blood pressure reading 145/92 detected. Consider consulting your physician.',
            time: '11:30 AM',
            isRead: true,
          ),
        ],
      ],
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'medication_reminder':
        return CrevaColors.primary;
      case 'alert':
        return CrevaColors.error;
      case 'health_insight':
        return const Color(0xFF8B5CF6);
      case 'follow_up':
        return CrevaColors.success;
      default:
        return CrevaColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medication_reminder':
        return Icons.medication;
      case 'alert':
        return Icons.warning_amber;
      case 'health_insight':
        return Icons.lightbulb_outline;
      case 'follow_up':
        return Icons.event;
      default:
        return Icons.notifications_outlined;
    }
  }
}

class _DateLabel extends StatelessWidget {
  final String label;
  const _DateLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: CrevaColors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _DemoNotif extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final bool isRead;
  const _DemoNotif({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: const BorderSide(color: CrevaColors.border) as Border?,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(body,
            style: const TextStyle(
                fontSize: 12,
                color: CrevaColors.textSecondary,
                height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        trailing: Text(time,
            style: const TextStyle(
                fontSize: 10, color: CrevaColors.textTertiary)),
      ),
    );
  }
}