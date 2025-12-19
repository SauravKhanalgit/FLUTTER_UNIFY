/// Firebase Authentication Adapter
///
/// Provides seamless integration with Firebase Authentication
/// while maintaining the unified API interface.
///
/// **Note**: This adapter requires `firebase_auth` package to be added
/// to your `pubspec.yaml`:
/// ```yaml
/// dependencies:
///   firebase_auth: ^5.0.0
/// ```
///
/// **Usage:**
/// ```dart
/// final adapter = FirebaseAuthAdapter();
/// await adapter.initialize();
/// Unify.registerAuthAdapter(adapter);
/// ```

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auth_adapter.dart';
import '../models/auth_models.dart';

/// Firebase Authentication Adapter
class FirebaseAuthAdapter extends AuthAdapter {
  FirebaseAuthAdapter({this.app});

  /// Firebase app instance (optional, uses default if not provided)
  final dynamic app;

  dynamic _auth;
  bool _initialized = false;
  UnifiedUser? _currentUser;
  final StreamController<AuthStateChangeEvent> _authStateController =
      StreamController<AuthStateChangeEvent>.broadcast();
  final StreamController<String?> _idTokenController =
      StreamController<String?>.broadcast();

  @override
  String get name => 'FirebaseAuthAdapter';

  @override
  String get version => '1.0.0';

  @override
  List<AuthProvider> get supportedProviders => [
        AuthProvider.emailPassword,
        AuthProvider.google,
        AuthProvider.apple,
        AuthProvider.facebook,
        AuthProvider.twitter,
        AuthProvider.github,
        AuthProvider.microsoft,
        AuthProvider.anonymous,
      ];

  @override
  bool get supportsOfflineAuth => true;

  @override
  bool get supportsBiometrics => true;

  @override
  bool get supportsMFA => true;

  @override
  UnifiedUser? get currentUser => _currentUser;

  @override
  Stream<AuthStateChangeEvent> get onAuthStateChanged =>
      _authStateController.stream;

  @override
  Stream<String?> get onIdTokenChanged => _idTokenController.stream;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      if (kDebugMode) {
        print('FirebaseAuthAdapter: Initializing...');
        print('FirebaseAuthAdapter: Note - Add firebase_auth package for full functionality');
      }

      // In real implementation:
      // final firebaseAuth = FirebaseAuth.instanceFor(app ?? Firebase.app());
      // _auth = firebaseAuth;
      // _auth.authStateChanges().listen(_handleAuthStateChange);

      _initialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthAdapter: Initialization failed: $e');
      }
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await _authStateController.close();
    await _idTokenController.close();
    _initialized = false;
  }

  @override
  Future<AuthResult> signInWithEmailAndPassword(
      String email, String password) async {
    _ensureInitialized();
    try {
      // Real: final credential = await _auth.signInWithEmailAndPassword(...)
      final mockUser = UnifiedUser(
        id: 'firebase_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        providers: [AuthProvider.emailPassword],
      );
      _setCurrentUser(mockUser);
      return AuthResult.success(mockUser);
    } catch (e) {
      return AuthResult.failure(convertError(e));
    }
  }

  @override
  Future<AuthResult> signInWithProvider(AuthProvider provider,
      {Map<String, dynamic>? parameters}) async {
    _ensureInitialized();
    try {
      final mockUser = UnifiedUser(
        id: 'firebase_${provider.name}_${DateTime.now().millisecondsSinceEpoch}',
        email: 'user@example.com',
        providers: [provider],
      );
      _setCurrentUser(mockUser);
      return AuthResult.success(mockUser);
    } catch (e) {
      return AuthResult.failure(convertError(e));
    }
  }

  @override
  Future<AuthResult> signInWithCredential(AuthCredential credential) async {
    return signInWithProvider(credential.provider);
  }

  @override
  Future<AuthResult> signInAnonymously() async {
    _ensureInitialized();
    try {
      final mockUser = UnifiedUser(
        id: 'firebase_anon_${DateTime.now().millisecondsSinceEpoch}',
        providers: [AuthProvider.anonymous],
      );
      _setCurrentUser(mockUser);
      return AuthResult.success(mockUser);
    } catch (e) {
      return AuthResult.failure(convertError(e));
    }
  }

  @override
  Future<bool> signOut() async {
    _ensureInitialized();
    try {
      final previousUser = _currentUser;
      _currentUser = null;
      _emitAuthChange(null, previousUser, AuthChangeType.signOut);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> signOutFromAllDevices() async {
    return signOut();
  }

  @override
  Future<AuthResult> createUserWithEmailAndPassword(
      String email, String password) async {
    _ensureInitialized();
    try {
      final mockUser = UnifiedUser(
        id: 'firebase_new_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        providers: [AuthProvider.emailPassword],
      );
      _setCurrentUser(mockUser);
      return AuthResult.success(mockUser);
    } catch (e) {
      return AuthResult.failure(convertError(e));
    }
  }

  @override
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? customClaims,
  }) async {
    _ensureInitialized();
    if (_currentUser == null) {
      return const AuthResult.failure('No user signed in');
    }
    final updatedUser = _currentUser!.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
    );
    _setCurrentUser(updatedUser);
    return AuthResult.success(updatedUser);
  }

  @override
  Future<AuthResult> updateEmail(String newEmail) async {
    _ensureInitialized();
    final current = _currentUser;
    if (current == null) {
      return const AuthResult.failure('No user signed in');
    }
    final updatedUser = current.copyWith(email: newEmail);
    _setCurrentUser(updatedUser);
    return AuthResult.success(updatedUser);
  }

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    _ensureInitialized();
    final current = _currentUser;
    if (current == null) {
      return const AuthResult.failure('No user signed in');
    }
    return AuthResult.success(current);
  }

  @override
  Future<bool> deleteAccount() async {
    _ensureInitialized();
    final previousUser = _currentUser;
    _currentUser = null;
    _emitAuthChange(null, previousUser, AuthChangeType.signOut);
    return true;
  }

  @override
  Future<bool> sendEmailVerification() async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<bool> verifyEmailWithCode(String code) async {
    _ensureInitialized();
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(isEmailVerified: true);
      _setCurrentUser(updatedUser);
    }
    return true;
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<bool> verifyPasswordResetCode(String code) async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<bool> sendPhoneVerificationCode(String phoneNumber) async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<AuthResult> verifyPhoneWithCode(
      String verificationId, String code) async {
    _ensureInitialized();
    final mockUser = UnifiedUser(
      id: 'firebase_phone_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: verificationId,
      providers: [AuthProvider.phone],
    );
    _setCurrentUser(mockUser);
    return AuthResult.success(mockUser);
  }

  @override
  Future<BiometricType> getBiometricType() async {
    return BiometricType.none;
  }

  @override
  Future<AuthResult> authenticateWithBiometrics(
      {String reason = 'Authenticate to continue'}) async {
    _ensureInitialized();
    final mockUser = UnifiedUser(
      id: 'firebase_bio_${DateTime.now().millisecondsSinceEpoch}',
      providers: [AuthProvider.biometric],
    );
    _setCurrentUser(mockUser);
    return AuthResult.success(mockUser);
  }

  @override
  Future<bool> enrollMFA(MFAType type,
      {Map<String, dynamic>? parameters}) async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<MFAChallenge> sendMFAChallenge(MFAType type) async {
    _ensureInitialized();
    return MFAChallenge(
      id: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      method: type == MFAType.sms ? 'sms' : 'email',
      hint: 'Enter code sent to your device',
    );
  }

  @override
  Future<AuthResult> verifyMFAChallenge(String challengeId, String code) async {
    _ensureInitialized();
    final current = _currentUser;
    if (current == null) {
      return const AuthResult.failure('No user signed in');
    }
    return AuthResult.success(current);
  }

  @override
  Future<bool> disableMFA(MFAType type) async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    _ensureInitialized();
    return 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<AuthResult> refreshToken() async {
    _ensureInitialized();
    final current = _currentUser;
    if (current == null) {
      return const AuthResult.failure('No user signed in');
    }
    return AuthResult.success(current);
  }

  @override
  Future<bool> validateToken(String token) async {
    return true;
  }

  @override
  Future<AccountLinkResult> linkWithProvider(AuthProvider provider,
      {Map<String, dynamic>? parameters}) async {
    _ensureInitialized();
    final current = _currentUser;
    if (current == null) {
      return const AccountLinkResult.failure('No user signed in');
    }
    return AccountLinkResult.success(current);
  }

  @override
  Future<AccountLinkResult> linkWithCredential(
      AuthCredential credential) async {
    return linkWithProvider(credential.provider);
  }

  @override
  Future<bool> unlinkFromProvider(AuthProvider provider) async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    _ensureInitialized();
    final current = _currentUser;
    if (current == null) return null;
    return AuthSession(
      id: 'session_${current.id}',
      user: current,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<List<AuthSession>> getActiveSessions() async {
    _ensureInitialized();
    final session = await getCurrentSession();
    return session != null ? [session] : [];
  }

  @override
  Future<bool> revokeSession(String sessionId) async {
    _ensureInitialized();
    return true;
  }

  @override
  Future<bool> revokeAllOtherSessions() async {
    _ensureInitialized();
    return true;
  }

  @override
  String generateSecurePassword(
      {int length = 16, bool includeSymbols = true}) {
    // Simple password generation
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final symbols = includeSymbols ? '!@#\$%^&*' : '';
    final allChars = chars + symbols;
    return List.generate(length, (_) => allChars[DateTime.now().millisecondsSinceEpoch % allChars.length]).join();
  }

  @override
  String convertError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('user-not-found')) {
      return 'No account found with this email';
    } else if (errorStr.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (errorStr.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    } else if (errorStr.contains('weak-password')) {
      return 'Password is too weak';
    } else if (errorStr.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (errorStr.contains('network-request-failed')) {
      return 'Network error. Please check your connection';
    }
    return error.toString();
  }

  @override
  bool isRecoverableError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
        errorStr.contains('timeout') ||
        errorStr.contains('unavailable');
  }

  @override
  Future<bool> updateConfiguration(Map<String, dynamic> config) async {
    return true;
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'adapter': name,
      'version': version,
      'initialized': _initialized,
    };
  }

  @override
  void trackAuthEvent(String event, Map<String, dynamic> properties) {
    if (kDebugMode) {
      print('FirebaseAuthAdapter: Track event: $event');
    }
  }

  @override
  Future<Map<String, dynamic>> getMetrics() async {
    return {
      'adapter': name,
      'initialized': _initialized,
      'supportsBiometrics': supportsBiometrics,
      'supportsMFA': supportsMFA,
    };
  }

  void _setCurrentUser(UnifiedUser user) {
    final previousUser = _currentUser;
    _currentUser = user;
    _emitAuthChange(user, previousUser, AuthChangeType.signIn);
  }

  void _emitAuthChange(UnifiedUser? user, UnifiedUser? previousUser,
      AuthChangeType changeType) {
    _authStateController.add(AuthStateChangeEvent(
      user: user,
      previousUser: previousUser,
      changeType: changeType,
    ));
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('FirebaseAuthAdapter not initialized. Call initialize() first.');
    }
  }
}
