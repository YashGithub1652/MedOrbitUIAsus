// lib/widgets/ollama_status_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/symptom_provider.dart';

class OllamaStatusWidget extends ConsumerWidget {
  const OllamaStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(symptomProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: state.ollamaConnected
            ? CrevaColors.success.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.ollamaConnected ? CrevaColors.success : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.ollamaConnected ? Icons.check_circle : Icons.warning_amber,
            size: 16,
            color: state.ollamaConnected ? CrevaColors.success : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            state.ollamaConnected ? 'AI Online' : 'AI Offline (Fallback Mode)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  state.ollamaConnected ? CrevaColors.success : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
