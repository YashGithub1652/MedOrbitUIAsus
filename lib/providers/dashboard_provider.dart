import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);

class DashboardState {
  final bool isLoading;
  final Map<String, dynamic> data;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.data = const {},
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState());

  final _api = ApiService();
  final _firestore = FirebaseFirestore.instance;

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // 1️⃣ Try backend first
    try {
      final data = await _api.getDashboard();
      state = DashboardState(data: data);
      return;
    } catch (e) {
      debugPrint('Backend dashboard failed, falling back to Firestore: $e');
    }

    // 2️⃣ Fallback — build dashboard from Firestore
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      final vitalsSnap = await _firestore
          .collection('vitals')
          .where('user_id', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();

      final convsSnap = await _firestore
          .collection('conversations')
          .where('user_id', isEqualTo: uid)
          .get();

      final vitals = vitalsSnap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      state = DashboardState(
        data: {
          'avg_risk_score': 0.0,
          'total_records': vitals.length,
          'conversations_count': convsSnap.size,
          'vitals_history': vitals,
          'patterns': [],
        },
      );
    } catch (e) {
      debugPrint('Firestore dashboard failed: $e');
      // Return empty dashboard so UI still renders
      state = const DashboardState(
        data: {
          'avg_risk_score': 0.0,
          'total_records': 0,
          'conversations_count': 0,
          'vitals_history': [],
          'patterns': [],
        },
      );
    }
  }
}