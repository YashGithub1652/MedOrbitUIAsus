// lib/screens/symptoms/symptom_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/symptom_models.dart';
import '../../providers/symptom_provider.dart';

class SymptomHistoryTab extends ConsumerWidget {
  final ValueChanged<SymptomEntry> onSelectEntry;
  const SymptomHistoryTab({super.key, required this.onSelectEntry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(symptomProvider);

    if (state.history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 56, color: CrevaColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'No symptom history yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CrevaColors.textSecondary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your past symptom checks will appear here',
              style: TextStyle(
                fontSize: 13,
                color: CrevaColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pattern Section ──────────────────────────────────────────────
          if (state.patterns.isNotEmpty) ...[
            const Text(
              'Pattern Detection',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CrevaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...state.patterns.map((p) => _PatternCard(pattern: p)),
            const SizedBox(height: 20),
          ],

          // ── Timeline Section ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Symptom Timeline',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CrevaColors.textPrimary,
                ),
              ),
              Text(
                '${state.history.length} record${state.history.length > 1 ? "s" : ""}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CrevaColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.history.length,
            itemBuilder: (_, i) {
              final entry = state.history[i];
              return _HistoryTimelineTile(
                entry: entry,
                isLast: i == state.history.length - 1,
                onTap: () => onSelectEntry(entry),
                onDelete: () =>
                    ref.read(symptomProvider.notifier).deleteEntry(entry.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final PatternAlert pattern;
  const _PatternCard({required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pattern.requiresAttention
            ? const Color(0xFFFFF7ED)
            : CrevaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pattern.requiresAttention
              ? const Color(0xFFF97316)
              : CrevaColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pattern.requiresAttention
                ? Icons.warning_amber_rounded
                : Icons.auto_graph,
            color: pattern.requiresAttention
                ? const Color(0xFFF97316)
                : const Color(0xFF8B5CF6),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern.symptom.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: pattern.requiresAttention
                        ? const Color(0xFFF97316)
                        : const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pattern.insight,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CrevaColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pattern.occurrences}x in ${pattern.daySpan} days',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CrevaColors.textTertiary,
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

class _HistoryTimelineTile extends StatelessWidget {
  final SymptomEntry entry;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTimelineTile({
    required this.entry,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(entry.riskLevel);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: CrevaColors.border,
                      margin: const EdgeInsets.only(top: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CrevaColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CrevaColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(entry.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: CrevaColors.textTertiary,
                            ),
                          ),
                        ),
                        _RiskChip(risk: entry.riskLevel),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _confirmDelete(context),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: CrevaColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: entry.symptoms.take(4).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CrevaColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CrevaColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (entry.symptoms.length > 4) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${entry.symptoms.length - 4} more',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CrevaColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: CrevaColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.duration.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: CrevaColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.speed,
                          size: 12,
                          color: CrevaColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Severity ${entry.severityScore}/10',
                          style: const TextStyle(
                            fontSize: 11,
                            color: CrevaColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: CrevaColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Record?'),
        content: const Text(
          'This symptom record will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: CrevaColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:
        return CrevaColors.success;
      case RiskLevel.medium:
        return const Color(0xFFF59E0B);
      case RiskLevel.high:
        return const Color(0xFFEF4444);
      case RiskLevel.emergency:
        return CrevaColors.urgencyEmergency;
    }
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today, ${_time(d)}';
    if (diff == 1) return 'Yesterday, ${_time(d)}';
    return '${d.day}/${d.month}/${d.year} ${_time(d)}';
  }

  String _time(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

class _RiskChip extends StatelessWidget {
  final RiskLevel risk;
  const _RiskChip({required this.risk});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (risk) {
      case RiskLevel.low:
        label = 'Low';
        color = CrevaColors.success;
        break;
      case RiskLevel.medium:
        label = 'Medium';
        color = const Color(0xFFF59E0B);
        break;
      case RiskLevel.high:
        label = 'High';
        color = const Color(0xFFEF4444);
        break;
      case RiskLevel.emergency:
        label = 'Emergency';
        color = CrevaColors.urgencyEmergency;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
