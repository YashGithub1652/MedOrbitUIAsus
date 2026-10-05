// lib/screens/health/insurance_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

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
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text(
          'Insurance',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: CrevaColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: CrevaColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                size: 50,
                color: CrevaColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Insurance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CrevaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 14,
                color: CrevaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
