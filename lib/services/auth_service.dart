// PRODUCTION SECURITY NOTES:
//   • Passwords are NEVER stored locally. Firebase Auth manages credentials securely.
//   • In mock mode (Firebase unavailable), only a user profile JSON is persisted —
//     no password is ever written to disk.
//   • Before shipping: enable Email Enumeration Protection in Firebase console,
//     enable App Check to block unauthorized clients, and review Firestore rules.

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'firebase_service.dart';

class AuthService extends ChangeNotifier {
  static const _keyCurrentUser = 'auth_current_user';

  UserProfile? _currentUser;
  bool _isLoading = true;

  // Set once at construction from FirebaseService.isAvailable (which is already
  // resolved before runApp() calls ChangeNotifierProvider.create).
  final bool _isMockMode = !FirebaseService.isAvailable;

  StreamSubscription<User?>? _authSub;

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn           => _currentUser != null;
  bool get isLoading            => _isLoading;

  /// True when Firebase is unavailable and the app is running in offline demo mode.
  bool get isMockMode => _isMockMode;

  AuthService() { _init(); }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    if (_isMockMode) {
      await _loadMockSession();
      return;
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _handleAuthStateChange(user);
    });
  }

  Future<void> _handleAuthStateChange(User? user) async {
    if (user == null) {
      _currentUser = null;
      _isLoading   = false;
      notifyListeners();
      return;
    }
    _currentUser = await _fetchOrBuildProfile(user);
    _isLoading   = false;
    notifyListeners();
  }

  // ── Email/password login ──────────────────────────────────────────────────────

  Future<String?> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    if (_isMockMode) {
      return _mockLogin(email: email, password: password, rememberMe: rememberMe);
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: password,
      );
      // authStateChanges fires → _handleAuthStateChange updates _currentUser.
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return 'Sign in failed. Please try again.';
    }
  }

  // ── Email/password sign-up ────────────────────────────────────────────────────

  Future<String?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_isMockMode) {
      return _mockSignUp(fullName: fullName, email: email, password: password);
    }
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      await user.updateDisplayName(fullName);
      await _createFirestoreUser(
        uid:          user.uid,
        fullName:     fullName,
        email:        email,
        authProvider: 'email',
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return 'Sign up failed. Please try again.';
    }
  }

  // ── Google sign-in ────────────────────────────────────────────────────────────

  Future<String?> signInWithGoogle() async {
    if (_isMockMode) {
      return 'Google sign-in requires Firebase. The app is running in offline demo mode.';
    }
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user   = result.user!;

      if (result.additionalUserInfo?.isNewUser == true) {
        await _createFirestoreUser(
          uid:          user.uid,
          fullName:     user.displayName ?? googleUser.displayName ?? 'User',
          email:        user.email ?? googleUser.email,
          photoUrl:     user.photoURL,
          authProvider: 'google',
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return 'Google sign-in failed. Please try again.';
    }
  }

  // ── Password reset ────────────────────────────────────────────────────────────

  Future<String?> sendPasswordReset(String email) async {
    if (_isMockMode) return null; // caller handles the demo-mode message

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return 'Could not send reset email. Please try again.';
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    if (_isMockMode) {
      _currentUser = null;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCurrentUser);
      return;
    }
    if (_currentUser?.authProvider == 'google') {
      await GoogleSignIn().signOut();
    }
    await FirebaseAuth.instance.signOut();
    // authStateChanges fires null → _handleAuthStateChange handles the rest.
  }

  // ── Firestore helpers ─────────────────────────────────────────────────────────

  Future<void> _createFirestoreUser({
    required String uid,
    required String fullName,
    required String email,
    String? photoUrl,
    required String authProvider,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName':          fullName,
        'email':             email,
        'photoUrl':          photoUrl,
        'authProvider':      authProvider,
        'createdAt':         FieldValue.serverTimestamp(),
        'isPro':             false,
        'savedVehicleCount': 0,
      });
    } catch (_) {
      // Non-fatal — Firebase Auth user exists even if Firestore write fails.
    }
  }

  Future<UserProfile> _fetchOrBuildProfile(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        final d = doc.data()!;
        return UserProfile(
          id:           user.uid,
          fullName:     d['fullName']     as String? ?? user.displayName ?? 'User',
          email:        d['email']        as String? ?? user.email ?? '',
          photoUrl:     d['photoUrl']     as String?,
          authProvider: d['authProvider'] as String? ?? 'email',
          createdAt:    (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
    } catch (_) {
      // Firestore unavailable — fall back to Firebase Auth fields.
    }
    return UserProfile(
      id:           user.uid,
      fullName:     user.displayName ?? _nameFromEmail(user.email ?? ''),
      email:        user.email ?? '',
      photoUrl:     user.photoURL,
      authProvider: 'email',
      createdAt:    user.metadata.creationTime ?? DateTime.now(),
    );
  }

  // ── Mock fallback ─────────────────────────────────────────────────────────────

  Future<void> _loadMockSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = UserProfile.tryFromJsonString(prefs.getString(_keyCurrentUser));
    _isLoading   = false;
    notifyListeners();
  }

  Future<String?> _mockLogin({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final profile = UserProfile(
      id:           'mock_${email.hashCode.abs()}',
      fullName:     _nameFromEmail(email),
      email:        email,
      authProvider: 'email',
      createdAt:    DateTime.now(),
    );
    _currentUser = profile;
    notifyListeners();
    if (rememberMe) await _persistMockSession(profile);
    return null;
  }

  Future<String?> _mockSignUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final profile = UserProfile(
      id:           'mock_${DateTime.now().millisecondsSinceEpoch}',
      fullName:     fullName,
      email:        email,
      authProvider: 'email',
      createdAt:    DateTime.now(),
    );
    _currentUser = profile;
    notifyListeners();
    await _persistMockSession(profile);
    return null;
  }

  Future<void> _persistMockSession(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, jsonEncode(profile.toJson()));
  }

  // ── Firebase error → friendly message ────────────────────────────────────────

  static String _mapError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found'         => 'No account found with this email.',
      'wrong-password'         => 'Incorrect password. Please try again.',
      'invalid-credential'     => 'Incorrect email or password.',
      'email-already-in-use'   => 'An account already exists with this email.',
      'weak-password'          => 'Password is too weak. Use at least 6 characters.',
      'invalid-email'          => 'Please enter a valid email address.',
      'network-request-failed' => 'No internet connection. Check your network.',
      'too-many-requests'      => 'Too many attempts. Please wait and try again.',
      'user-disabled'          => 'This account has been disabled.',
      'operation-not-allowed'  => 'This sign-in method is not enabled in Firebase console.',
      _                        => 'Something went wrong. Please try again.',
    };
  }

  static String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._+\-]'), ' ');
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
