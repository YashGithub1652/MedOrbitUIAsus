// lib/screens/symptoms/symptom_detail_screen.dart

import 'package:flutter/material.dart';

class SymptomDetailScreen extends StatelessWidget {
  final String symptomId;

  const SymptomDetailScreen({
    super.key,
    required this.symptomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Details'),
      ),
      body: Center(
        child: Text('Details for symptom $symptomId'),
      ),
    );
  }
}
