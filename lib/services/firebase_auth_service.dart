import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final _auth = fb.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  fb.User? get currentUser => _auth.currentUser;
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  // ── Load current user profile ─────────────────────────────────────────────
  Future<UserProfile> loadCurrentUserProfile() async {
    final fbUser = currentUser;
    if (fbUser == null) throw Exception('No user logged in');
    return _getOrCreateProfile(fbUser);
  }

  // ── Email / Password Login ────────────────────────────────────────────────
  Future<UserProfile> loginWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser == null) throw Exception('Login failed: no user returned');
      return await _getOrCreateProfile(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<UserProfile> registerWithEmail(Map<String, dynamic> formData) async {
    final email =
        (formData['email'] as String?)?.trim().toLowerCase() ?? '';
    final password = (formData['password'] as String?) ?? '';
    final name = (formData['name'] as String?)?.trim() ?? '';

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('Name, email and password are required.');
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser == null) throw Exception('Registration failed');
      await fbUser.updateDisplayName(name);

      final profile = UserProfile(
        id: fbUser.uid,
        name: name,
        email: email,
        age: formData['age'] != null
            ? int.tryParse(formData['age'].toString())
            : null,
        gender: formData['gender'],
        bloodGroup: formData['blood_group'],
        allergies: formData['allergies'] is List
            ? List<String>.from(formData['allergies'])
            : [],
        medications: formData['medications'] is List
            ? List<String>.from(formData['medications'])
            : [],
        medicalHistory: formData['medical_history'] is List
            ? List<String>.from(formData['medical_history'])
            : [],
      );

      await _saveProfile(fbUser.uid, profile);
      return profile;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<UserProfile> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Google sign-in cancelled');

      final googleAuth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final fbUser = cred.user;
      if (fbUser == null) throw Exception('Google sign-in failed');

      return await _getOrCreateProfile(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<void> updateProfile(UserProfile profile) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    await _firestore.collection('users').doc(uid).set(
      {
        ...profile.toJson()..remove('id'),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  Future<UserProfile> _getOrCreateProfile(fb.User fbUser) async {
    try {
      final doc =
          await _firestore.collection('users').doc(fbUser.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = fbUser.uid;
        return UserProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('Firestore read failed, using Firebase user data: $e');
    }

    // First-time or Firestore unavailable — build from Firebase user
    final profile = UserProfile(
      id: fbUser.uid,
      name: fbUser.displayName ??
          fbUser.email?.split('@').first ??
          'User',
      email: fbUser.email ?? '',
    );

    try {
      await _saveProfile(fbUser.uid, profile);
    } catch (e) {
      debugPrint('Could not save profile to Firestore: $e');
    }

    return profile;
  }

  Future<void> _saveProfile(String uid, UserProfile profile) async {
    final data = Map<String, dynamic>.from(profile.toJson())..remove('id');
    data['updated_at'] = FieldValue.serverTimestamp();
    data['created_at'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  String _mapFirebaseError(fb.FirebaseAuthException e) {
    debugPrint('FirebaseAuthException: code=${e.code} msg=${e.message}');
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'operation-not-allowed':
        return 'Sign-in method not enabled in Firebase console.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}