import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);

class NotificationState {
  final bool isLoading;
  final List<Map<String, dynamic>> notifications;
  final String? error;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? notifications,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error ?? this.error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  final _api = ApiService();
  final _firestore = FirebaseFirestore.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    // 1️⃣ Try backend first
    try {
      final data = await _api.getNotifications();
      final notifs = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      state = NotificationState(notifications: notifs);
      return;
    } catch (e) {
      debugPrint('Backend notifications failed, using Firestore: $e');
    }

    // 2️⃣ Firestore fallback
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final snap = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();

      final notifs = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      state = NotificationState(notifications: notifs);
    } catch (e) {
      debugPrint('Firestore notifications failed: $e');
      state = const NotificationState(notifications: []);
    }
  }

  Future<void> markRead(String id) async {
    // Optimistically update UI
    final updated = state.notifications.map((n) {
      if (n['id'] == id) return {...n, 'is_read': true};
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);

    // Try backend
    try {
      await _api.markNotificationRead(id);
      return;
    } catch (_) {}

    // Firestore fallback
    try {
      await _firestore
          .collection('notifications')
          .doc(id)
          .update({'is_read': true});
    } catch (e) {
      debugPrint('markRead Firestore failed: $e');
    }
  }
}