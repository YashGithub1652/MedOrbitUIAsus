// lib/screens/appointments/appointment_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/appointments'),
        ),
        title: const Text(
          'Appointment Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: CrevaColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Text('Appointment $appointmentId - Coming Soon'),
      ),
    );
  }
}
