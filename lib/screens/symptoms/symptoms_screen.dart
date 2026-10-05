// lib/screens/symptoms/symptoms_screen.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/symptom_models.dart';
import '../../providers/symptom_provider.dart' hide SymptomDuration;
import 'symptom_analysis_screen.dart';
import 'symptom_history_screen.dart';

class SymptomsScreen extends ConsumerStatefulWidget {
  const SymptomsScreen({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  final List<String> _selectedSymptoms = [];
  SymptomDuration _duration = SymptomDuration.today;
  double _severity = 3.0;
  String _activeGroup = 'General';
  String _searchQuery = '';

  final Map<String, List<String>> _symptomGroups = {
    'General': [
      'Fever',
      'Fatigue',
      'Chills',
      'Night Sweats',
      'Weight Loss',
      'Loss of Appetite',
      'Weakness',
    ],
    'Head & Neuro': [
      'Headache',
      'Dizziness',
      'Confusion',
      'Fainting',
      'Blurred Vision',
      'Memory Issues',
      'Numbness',
    ],
    'Respiratory': [
      'Cough',
      'Shortness of Breath',
      'Chest Pain',
      'Wheezing',
      'Sore Throat',
      'Runny Nose',
      'Congestion',
    ],
    'GI Tract': [
      'Nausea',
      'Vomiting',
      'Diarrhea',
      'Constipation',
      'Abdominal Pain',
      'Bloating',
      'Heartburn',
    ],
    'Muscles': [
      'Joint Pain',
      'Muscle Ache',
      'Back Pain',
      'Swelling',
      'Weakness',
      'Stiffness',
      'Cramps',
    ],
    'Skin': [
      'Rash',
      'Itching',
      'Hives',
      'Jaundice',
      'Bruising',
      'Swollen Lymph Nodes',
      'Redness',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<String> get _filteredSymptoms {
    if (_searchQuery.isEmpty) {
      return _symptomGroups[_activeGroup] ?? [];
    }
    return _symptomGroups.values
        .expand((list) => list)
        .where((s) => s.toLowerCase().contains(_searchQuery))
        .toSet()
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedSymptoms.isEmpty) {
      _showSnack('Please select at least one symptom', isError: true);
      return;
    }

    final entry = await ref.read(symptomProvider.notifier).analyzeSymptoms(
          symptoms: _selectedSymptoms,
          description: _descCtrl.text.trim(),
          duration: _duration,
          severity: _severity.round(),
        );

    if (entry != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SymptomAnalysisScreen(entry: entry),
        ),
      );
    } else if (mounted) {
      final error = ref.read(symptomProvider).error;
      if (error != null) _showSnack(error, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? CrevaColors.error : CrevaColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(symptomProvider);

    // Show errors from provider
    ref.listen(symptomProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _showSnack(next.error!, isError: true);
        ref.read(symptomProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        elevation: 0,
        // ✅ Updated leading button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CrevaColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Symptom Checker',
          style: TextStyle(
            color: CrevaColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),

        actions: [
          // Ollama Status Indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _OllamaStatusBadge(connected: state.ollamaConnected),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: CrevaColors.primary,
          unselectedLabelColor: CrevaColors.textTertiary,
          indicatorColor: CrevaColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Check Symptoms'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCheckerTab(state),
          SymptomHistoryTab(
            onSelectEntry: (entry) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SymptomAnalysisScreen(entry: entry),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Checker Tab ───────────────────────────────────────────────────────────
  Widget _buildCheckerTab(SymptomState state) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Status Banner
              _AIStatusBanner(
                connected: state.ollamaConnected,
              ),
              const SizedBox(height: 12),

              // Emergency Banner
              _EmergencyBanner(),
              const SizedBox(height: 16),

              // Pattern Alerts
              if (state.patterns.any((p) => p.requiresAttention)) ...[
                _PatternAlertBanner(patterns: state.patterns),
                const SizedBox(height: 12),
              ],

              // Selected Symptoms
              if (_selectedSymptoms.isNotEmpty) ...[
                _SelectedSymptomsChips(
                  symptoms: _selectedSymptoms,
                  onRemove: (s) => setState(
                    () => _selectedSymptoms.remove(s),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Search Bar
              _SearchBar(controller: _searchCtrl),
              const SizedBox(height: 12),

              // Category Filter
              if (_searchQuery.isEmpty)
                _CategoryFilter(
                  groups: _symptomGroups,
                  active: _activeGroup,
                  onSelect: (g) => setState(() => _activeGroup = g),
                ),
              const SizedBox(height: 12),

              // Symptom Grid
              _SymptomGrid(
                symptoms: _filteredSymptoms,
                selected: _selectedSymptoms,
                onToggle: (s) {
                  setState(() {
                    if (_selectedSymptoms.contains(s)) {
                      _selectedSymptoms.remove(s);
                    } else {
                      _selectedSymptoms.add(s);
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // Description
              const _SectionHeader(label: 'Describe Your Symptoms'),
              const SizedBox(height: 8),
              _DescriptionField(controller: _descCtrl),
              const SizedBox(height: 20),

              // Duration
              const _SectionHeader(label: 'Duration'),
              const SizedBox(height: 8),
              _DurationSelector(
                selected: _duration,
                onSelect: (d) => setState(() => _duration = d),
              ),
              const SizedBox(height: 20),

              // Severity
              _SectionHeader(
                label: 'Severity: ${_severity.round()}/10',
                badge: _severityLabel(_severity.round()),
                badgeColor: _severityColor(_severity.round()),
              ),
              const SizedBox(height: 4),
              _SeveritySlider(
                value: _severity,
                onChanged: (v) => setState(() => _severity = v),
              ),
              const SizedBox(height: 28),

              // Analyze Button
              _AnalyzeButton(
                count: _selectedSymptoms.length,
                isLoading: state.isAnalyzing,
                onTap: _submit,
              ),
            ],
          ),
        ),

        // Loading Overlay
        if (state.isAnalyzing) _LoadingOverlay(),
      ],
    );
  }

  String _severityLabel(int s) {
    if (s <= 2) return 'Mild';
    if (s <= 4) return 'Moderate';
    if (s <= 6) return 'Significant';
    if (s <= 8) return 'Severe';
    return 'Critical';
  }

  Color _severityColor(int s) {
    if (s <= 2) return CrevaColors.success;
    if (s <= 4) return const Color(0xFFF59E0B);
    if (s <= 6) return const Color(0xFFEF4444);
    return CrevaColors.urgencyEmergency;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _OllamaStatusBadge extends StatelessWidget {
  final bool connected;
  const _OllamaStatusBadge({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: connected
            ? CrevaColors.success.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: connected ? CrevaColors.success : Colors.orange,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: connected ? CrevaColors.success : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            connected ? 'AI On' : 'AI Off',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: connected ? CrevaColors.success : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIStatusBanner extends StatelessWidget {
  final bool connected;
  const _AIStatusBanner({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: connected
            ? CrevaColors.success.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connected
              ? CrevaColors.success.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.smart_toy_outlined : Icons.smart_toy,
            color: connected ? CrevaColors.success : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Ollama AI Ready' : 'Ollama Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: connected ? CrevaColors.success : Colors.orange,
                  ),
                ),
                Text(
                  connected
                      ? 'AI-powered clinical analysis active'
                      : 'Run "ollama serve" on your computer for AI analysis',
                  style: TextStyle(
                    fontSize: 11,
                    color: connected
                        ? CrevaColors.success.withOpacity(0.8)
                        : Colors.orange.withOpacity(0.8),
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

class _EmergencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrevaColors.error.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.emergency, color: CrevaColors.error, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chest pain, difficulty breathing or loss of consciousness? '
              'Call emergency services immediately.',
              style: TextStyle(
                fontSize: 11,
                color: CrevaColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternAlertBanner extends StatelessWidget {
  final List<PatternAlert> patterns;
  const _PatternAlertBanner({required this.patterns});

  @override
  Widget build(BuildContext context) {
    final critical = patterns.firstWhere((p) => p.requiresAttention);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF97316)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_graph, color: Color(0xFFF97316), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '⚠ Pattern: ${critical.insight}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9A3412),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedSymptomsChips extends StatelessWidget {
  final List<String> symptoms;
  final ValueChanged<String> onRemove;
  const _SelectedSymptomsChips({
    required this.symptoms,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${symptoms.length} selected',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CrevaColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: symptoms.map((s) {
            return Chip(
              label: Text(s),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => onRemove(s),
              backgroundColor: CrevaColors.primary.withOpacity(0.1),
              deleteIconColor: CrevaColors.primary,
              labelStyle: const TextStyle(
                color: CrevaColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search symptoms...',
        hintStyle: const TextStyle(
          color: CrevaColors.textTertiary,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: CrevaColors.textTertiary,
          size: 20,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: controller.clear,
              )
            : null,
        filled: true,
        fillColor: CrevaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrevaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrevaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: CrevaColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final Map<String, List<String>> groups;
  final String active;
  final ValueChanged<String> onSelect;

  const _CategoryFilter({
    required this.groups,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: groups.keys.map((g) {
          final isActive = g == active;
          return GestureDetector(
            onTap: () => onSelect(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive ? CrevaColors.primary : CrevaColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? CrevaColors.primary : CrevaColors.border,
                ),
              ),
              child: Text(
                g,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : CrevaColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SymptomGrid extends StatelessWidget {
  final List<String> symptoms;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _SymptomGrid({
    required this.symptoms,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (symptoms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No symptoms found',
            style: TextStyle(color: CrevaColors.textTertiary),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.map((s) {
        final isSelected = selected.contains(s);
        return GestureDetector(
          onTap: () => onToggle(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: isSelected ? CrevaColors.primary : CrevaColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? CrevaColors.primary : CrevaColors.border,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: CrevaColors.primary.withOpacity(0.25),
                        blurRadius: 6,
                      )
                    ]
                  : [],
            ),
            child: Text(
              s,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : CrevaColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? badge;
  final Color? badgeColor;

  const _SectionHeader({
    required this.label,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: CrevaColors.textPrimary,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: (badgeColor ?? CrevaColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor ?? CrevaColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(fontSize: 13, height: 1.5),
      decoration: InputDecoration(
        hintText: 'e.g., Headache started 3 days ago, worse in morning, '
            'throbbing pain on left side...',
        hintStyle: const TextStyle(
          color: CrevaColors.textTertiary,
          fontSize: 13,
        ),
        filled: true,
        fillColor: CrevaColors.surface,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrevaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrevaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: CrevaColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final SymptomDuration selected;
  final ValueChanged<SymptomDuration> onSelect;
  const _DurationSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SymptomDuration.values.map((d) {
        final isSelected = d == selected;
        return GestureDetector(
          onTap: () => onSelect(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? CrevaColors.primary : CrevaColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? CrevaColors.primary : CrevaColors.border,
              ),
            ),
            child: Text(
              d.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : CrevaColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SeveritySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _SeveritySlider({required this.value, required this.onChanged});

  Color _color(int v) {
    if (v <= 3) return CrevaColors.success;
    if (v <= 5) return const Color(0xFFF59E0B);
    if (v <= 7) return const Color(0xFFEF4444);
    return CrevaColors.urgencyEmergency;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: _color(value.round()),
            inactiveTrackColor: CrevaColors.border,
            thumbColor: _color(value.round()),
            overlayColor: _color(value.round()).withOpacity(0.2),
          ),
          child: Slider(
            min: 1,
            max: 10,
            divisions: 9,
            value: value,
            onChanged: onChanged,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mild',
                style: TextStyle(
                  fontSize: 10,
                  color: CrevaColors.textTertiary,
                ),
              ),
              Text(
                'Critical',
                style: TextStyle(
                  fontSize: 10,
                  color: CrevaColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final int count;
  final bool isLoading;
  final VoidCallback onTap;

  const _AnalyzeButton({
    required this.count,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [CrevaColors.border, CrevaColors.border]
                : [
                    CrevaColors.primary,
                    const Color(0xFF1D4ED8),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: CrevaColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.biotech,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      count > 0
                          ? 'Analyze $count Symptom${count > 1 ? "s" : ""}'
                          : 'Select Symptoms to Analyze',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: CrevaColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: CrevaColors.primary,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Analyzing Symptoms',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: CrevaColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Running AI clinical analysis...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: CrevaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
