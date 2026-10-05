// lib/screens/vitals/vital_history_screen.dart

import 'package:flutter/material.dart';

class VitalHistoryScreen extends StatelessWidget {
  final String vitalType;

  const VitalHistoryScreen({
    super.key,
    required this.vitalType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$vitalType History'),
      ),
      body: Center(
        child: Text('History for $vitalType'),
      ),
    );
  }
}
