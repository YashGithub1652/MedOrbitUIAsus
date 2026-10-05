// lib/screens/symptoms/symptom_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/symptom_models.dart';
import '../../providers/symptom_provider.dart' hide SymptomEntry;
import 'doctor_handoff_screen.dart';

class SymptomAnalysisScreen extends ConsumerWidget {
  final SymptomEntry entry;
  const SymptomAnalysisScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(symptomProvider);
    final analysis = entry.analysis;
    final riskColor = _riskColor(entry.riskLevel);
    final riskLabel = _riskLabel(entry.riskLevel);

    return Scaffold(
      backgroundColor: CrevaColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: riskColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (analysis != null)
                IconButton(
                  icon: const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Doctor Handoff',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoctorHandoffScreen(entry: entry),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      riskColor,
                      riskColor.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RiskBadge(risk: entry.riskLevel),
                        const SizedBox(height: 8),
                        Text(
                          riskLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Severity: ${entry.severityScore}/10 '
                          '• ${entry.duration.label}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Emergency action
                if (entry.riskLevel == RiskLevel.emergency ||
                    entry.riskLevel == RiskLevel.high)
                  _EmergencyActionCard(risk: entry.riskLevel),

                // Reported symptoms
                _SectionCard(
                  title: 'Reported Symptoms',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children:
                        entry.symptoms.map((s) => _SymptomTag(s)).toList(),
                  ),
                ),

                if (analysis != null) ...[
                  // Clinical summary
                  _SectionCard(
                    title: 'Clinical Summary',
                    child: Text(
                      analysis.summary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CrevaColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),

                  // Red flags
                  if (analysis.redFlags.isNotEmpty)
                    _SectionCard(
                      title: 'Red Flags',
                      titleColor: CrevaColors.error,
                      child: Column(
                        children: analysis.redFlags.map((f) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: CrevaColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: CrevaColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Possible conditions
                  _SectionCard(
                    title: 'Possible Conditions',
                    subtitle: 'AI analysis — not a diagnosis',
                    child: Column(
                      children: analysis.conditions
                          .asMap()
                          .entries
                          .map((e) => _ConditionTile(
                                condition: e.value,
                                rank: e.key + 1,
                              ))
                          .toList(),
                    ),
                  ),

                  // Specialist
                  _SpecialistCard(
                    specialist: analysis.specialistType,
                    onBook: () =>
                        _showBookingSheet(context, analysis.specialistType),
                  ),

                  // Recommendations
                  _SectionCard(
                    title: 'Recommendations',
                    child: Column(
                      children: analysis.recommendations
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: CrevaColors.primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: CrevaColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: CrevaColors.textPrimary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  // Pattern insights
                  if (analysis.patternInsights.isNotEmpty)
                    _SectionCard(
                      title: 'Pattern Insights',
                      titleColor: const Color(0xFF8B5CF6),
                      child: Column(
                        children: analysis.patternInsights.map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.auto_graph,
                                  color: Color(0xFF8B5CF6),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: CrevaColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],

                // ── Nearby Facilities ────────────────────────────────────
                _NearbyFacilitiesSection(
                  state: state,
                 onRefresh: () =>
                      ref.read(symptomProvider.notifier).findNearbyDoctors(
                            analysis?.specialistType, // REMOVE "specialistType:" label
                          ),
                ),

                // Disclaimer
                _DisclaimerCard(),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
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

  String _riskLabel(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:
        return 'Low Risk — Monitor at Home';
      case RiskLevel.medium:
        return 'Moderate Risk — See a Doctor Soon';
      case RiskLevel.high:
        return 'High Risk — Seek Care Today';
      case RiskLevel.emergency:
        return 'Emergency — Get Help Now';
    }
  }

  void _showBookingSheet(BuildContext context, String specialist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingBottomSheet(specialist: specialist),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RiskBadge extends StatelessWidget {
  final RiskLevel risk;
  const _RiskBadge({required this.risk});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    switch (risk) {
      case RiskLevel.low:
        label = 'LOW RISK';
        icon = Icons.check_circle_outline;
        break;
      case RiskLevel.medium:
        label = 'MODERATE RISK';
        icon = Icons.info_outline;
        break;
      case RiskLevel.high:
        label = 'HIGH RISK';
        icon = Icons.warning_outlined;
        break;
      case RiskLevel.emergency:
        label = 'EMERGENCY';
        icon = Icons.emergency_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyActionCard extends StatelessWidget {
  final RiskLevel risk;
  const _EmergencyActionCard({required this.risk});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CrevaColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_hospital, color: CrevaColors.error),
              const SizedBox(width: 8),
              Text(
                risk == RiskLevel.emergency
                    ? 'CALL EMERGENCY NOW'
                    : 'SEEK CARE TODAY',
                style: const TextStyle(
                  color: CrevaColors.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            risk == RiskLevel.emergency
                ? 'Your symptoms indicate a potential emergency. '
                    'Do not wait — call emergency services immediately.'
                : 'Your symptoms are serious. '
                    'Please see a doctor or urgent care center today.',
            style: const TextStyle(
              fontSize: 13,
              color: CrevaColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              // Indian emergency number is 112, change as needed
              final uri = Uri.parse('tel:112');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: CrevaColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Call Emergency Services',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: titleColor ?? CrevaColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: CrevaColors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SymptomTag extends StatelessWidget {
  final String label;
  const _SymptomTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CrevaColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CrevaColors.primary.withOpacity(0.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CrevaColors.primary,
        ),
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final PossibleCondition condition;
  final int rank;
  const _ConditionTile({required this.condition, required this.rank});

  Color _urgencyColor(String u) {
    switch (u) {
      case 'Emergency':
        return CrevaColors.urgencyEmergency;
      case 'Urgent':
        return const Color(0xFFEF4444);
      case 'Soon':
        return const Color(0xFFF59E0B);
      case 'Monitor':
        return CrevaColors.success;
      default:
        return CrevaColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (condition.probability * 100).round();
    final urgencyColor = _urgencyColor(condition.urgency);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CrevaColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrevaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? CrevaColors.primary
                      : CrevaColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: rank == 1 ? Colors.white : CrevaColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name
              Expanded(
                child: Text(
                  condition.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CrevaColors.textPrimary,
                  ),
                ),
              ),
              // Urgency badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  condition.urgency,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: urgencyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Probability bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: condition.probability,
              backgroundColor: CrevaColors.border,
              color: CrevaColors.primary,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  condition.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CrevaColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct% match',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CrevaColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final String specialist;
  final VoidCallback onBook;
  const _SpecialistCard({required this.specialist, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CrevaColors.primary.withOpacity(0.08),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CrevaColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CrevaColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Specialist',
                  style: TextStyle(
                    fontSize: 11,
                    color: CrevaColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialist,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CrevaColors.primary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onBook,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: CrevaColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Book',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nearby Facilities Section ─────────────────────────────────────────────────
class _NearbyFacilitiesSection extends StatelessWidget {
  final SymptomState state;
  final VoidCallback onRefresh;

  const _NearbyFacilitiesSection({
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Facilities',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CrevaColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onRefresh,
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: CrevaColors.primary,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Find Near Me',
                    style: TextStyle(
                      color: CrevaColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Loading
        if (state.isLoadingLocation)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CrevaColors.primary,
              ),
            ),
          )

        // Empty state
        else if (state.nearbyFacilities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CrevaColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  color: CrevaColors.textTertiary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap "Find Near Me" to locate\nhospitals and clinics',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CrevaColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CrevaColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Find Nearby',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )

        // Facilities list
        else
          ...state.nearbyFacilities
              .map((f) => _FacilityCard(facility: f))
              .toList(), // ✅ FIXED: Missing .toList()

        const SizedBox(height: 12),
      ],
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final NearbyFacility facility;
  const _FacilityCard({required this.facility});

  Color get _typeColor {
    switch (facility.type) {
      case 'urgent_care':
        return const Color(0xFFF59E0B);
      case 'hospital':
        return CrevaColors.primary;
      default:
        return CrevaColors.success;
    }
  }

  IconData get _typeIcon {
    switch (facility.type) {
      case 'urgent_care':
        return Icons.local_pharmacy;
      case 'hospital':
        return Icons.local_hospital;
      default:
        return Icons.medical_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CrevaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CrevaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CrevaColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 11,
                      color: CrevaColors.textTertiary,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '${facility.distanceKm} km • ${facility.address}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CrevaColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (facility.isOpen24h) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CrevaColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '24h',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: CrevaColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (facility.rating > 0) ...[
                      const Icon(
                        Icons.star,
                        size: 11,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        facility.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: CrevaColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Column(
            children: [
              // Call button
              if (facility.phone.isNotEmpty)
                _ActionBtn(
                  icon: Icons.call,
                  color: CrevaColors.primary,
                  onTap: () async {
                    final uri = Uri.parse('tel:${facility.phone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              const SizedBox(height: 6),
              // Directions button
              _ActionBtn(
                icon: Icons.directions,
                color: const Color(0xFFF59E0B),
                onTap: () async {
                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1'
                    '&query=${facility.lat},${facility.lng}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrevaColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: CrevaColors.textTertiary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This AI analysis is for informational purposes only and '
              'does not constitute medical advice, diagnosis, or treatment. '
              'Always consult a qualified healthcare professional.',
              style: TextStyle(
                fontSize: 11,
                color: CrevaColors.textTertiary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment Booking ───────────────────────────────────────────────────────
class _BookingBottomSheet extends StatefulWidget {
  final String specialist;
  const _BookingBottomSheet({required this.specialist});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00 AM';
  bool _booked = false;

  final _times = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  String _weekday(int w) {
    const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return d[(w - 1).clamp(0, 6)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CrevaColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (_booked)
            Expanded(
              child: _BookingConfirmed(
                specialist: widget.specialist,
                date: _selectedDate,
                time: _selectedTime,
                onDone: () => Navigator.pop(context),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book ${widget.specialist}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CrevaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select date and time',
                      style: TextStyle(
                        fontSize: 13,
                        color: CrevaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date picker
                    const Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 14,
                        itemBuilder: (_, i) {
                          final date =
                              DateTime.now().add(Duration(days: i + 1));
                          final isSelected = date.day == _selectedDate.day &&
                              date.month == _selectedDate.month;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedDate = date),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CrevaColors.primary
                                    : CrevaColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? CrevaColors.primary
                                      : CrevaColors.border,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _weekday(date.weekday),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? Colors.white70
                                          : CrevaColors.textTertiary,
                                    ),
                                  ),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : CrevaColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Time slots
                    const Text(
                      'Select Time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.5,
                      children: _times.map((t) {
                        final isSelected = t == _selectedTime;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTime = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CrevaColors.primary
                                  : CrevaColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? CrevaColors.primary
                                    : CrevaColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : CrevaColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Confirm button
                    GestureDetector(
                      onTap: () => setState(() => _booked = true),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: CrevaColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Confirm Appointment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingConfirmed extends StatelessWidget {
  final String specialist;
  final DateTime date;
  final String time;
  final VoidCallback onDone;

  const _BookingConfirmed({
    required this.specialist,
    required this.date,
    required this.time,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CrevaColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: CrevaColors.success,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Appointment Confirmed!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: CrevaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$specialist\n${date.day}/${date.month}/${date.year} at $time',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: CrevaColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onDone,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: CrevaColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}