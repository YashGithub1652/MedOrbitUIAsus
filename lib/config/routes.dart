import 'package:creva/screens/emergency/emergency_contacts_screen.dart';
import 'package:creva/screens/emergency/emergency_screen.dart';
import 'package:creva/screens/emergency/emergency_sos_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

// Core Screens
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/vitals/vitals_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/medications/medications_screen.dart';

// Reports & Symptoms
import '../screens/reports/reports_screen.dart';
import '../screens/reports/report_detail_screen.dart';
import '../screens/reports/scan_analyzer_screen.dart'; // ✅ Corrected path
import '../screens/symptoms/symptoms_screen.dart';

// Emergency (Create this file if it doesn't exist)
// import '../screens/emergency/emergency_screen.dart'; 

final appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('No route defined for ${state.uri.path}')),
  ),
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    
    // ✅ ADDED: Emergency Route
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencySOSScreen(), // Redirecting to Symptoms for now, or your EmergencyScreen
    ),

    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'];
        final chatMode = switch (mode) {
          'mental' => ChatMode.mental,
          'diet' => ChatMode.diet,
          'fitness' => ChatMode.fitness,
          _ => ChatMode.general,
        };
        return ChatScreen(mode: chatMode);
      },
    ),
    GoRoute(
      path: '/vitals',
      builder: (_, __) => const VitalsScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (_, __) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/reports/detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReportDetailScreen(reportId: id, isScan: false);
      },
    ),
    GoRoute(
      path: '/reports/analyze',
      builder: (context, state) {
        final file = state.extra as File?;
        if (file == null) return const ReportsScreen();
        return ScanAnalyzerScreen(
          imageFile: file,
          scanType: 'Lab Report',
        );
      },
    ),
    GoRoute(
      path: '/scan/detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReportDetailScreen(reportId: id, isScan: true);
      },
    ),
    GoRoute(
      path: '/scan/analyze',
      builder: (context, state) {
        final file = state.extra as File?;
        final scanType = state.uri.queryParameters['type'] ?? 'X-Ray';
        if (file == null) return const ReportsScreen();
        return ScanAnalyzerScreen(
          imageFile: file,
          scanType: scanType,
        );
      },
    ),
    GoRoute(
      path: '/medications',
      builder: (_, __) => const MedicationsScreen(),
    ),
    GoRoute(
      path: '/symptoms',
      builder: (_, __) => const SymptomsScreen(),
    ),
  ],
);