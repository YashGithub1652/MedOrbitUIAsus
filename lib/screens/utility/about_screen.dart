// lib/screens/utility/about_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About CREVA',
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
                Icons.favorite,
                size: 50,
                color: CrevaColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CREVA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: CrevaColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-Powered Healthcare Assistant',
              style: TextStyle(
                fontSize: 14,
                color: CrevaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: CrevaColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
