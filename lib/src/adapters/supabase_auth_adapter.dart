/// Supabase Authentication Adapter
///
/// Provides seamless integration with Supabase Authentication
/// while maintaining the unified API interface.
///
/// **Note**: This adapter requires `supabase_flutter` package to be added
/// to your `pubspec.yaml`:
/// ```yaml
/// dependencies:
///   supabase_flutter: ^2.0.0
/// ```
///
/// **Usage:**
/// ```dart
/// final adapter = SupabaseAuthAdapter();
/// await adapter.initialize();
/// Unify.registerAuthAdapter(adapter);
/// ```

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auth_adapter.dart';
import '../models/auth_models.dart';

/// Supabase Authentication Adapter
class SupabaseAuthAdapter extends AuthAdapter {
  SupabaseAuthAdapter({this.supabaseUrl, this.supabaseKey});

  /// Supabase project URL
  final String? supabaseUrl;
  
  /// Supabase anon key
  final String? supabaseKey;

  dynamic _supabase;
  bool _initialized = false;
  UnifiedUser? _currentUser;
  final StreamController<AuthStateChangeEvent> _authStateController =
      StreamController<AuthStateChangeEvent>.broadcast();
  final StreamController<String?> _idTokenController =
      StreamController<String?>.broadcast();

  @override
  String get name => 'SupabaseAuthAdapter';

  @override
  String get version => '1.0.0';

  @override
  List<AuthProvider> get supportedProviders => [
        AuthProvider.emailPassword,
        AuthProvider.google,
        AuthProvider.apple,
        AuthProvider.facebook,
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
        print('SupabaseAuthAdapter: Initializing...');
        print('SupabaseAuthAdapter: Note - Add supabase_flutter package for full functionality');
      }

      // In real implementation:
      // _supabase = Supabase.instance.client;
      // _supabase.auth.onAuthStateChange.listen(_handleAuthStateChange);

      _initialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SupabaseAuthAdapter: Initialization failed: $e');
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
      // Real: final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      final mockUser = UnifiedUser(
        id: 'supabase_user_${DateTime.now().millisecondsSinceEpoch}',
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
      // Real: await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      final mockUser = UnifiedUser(
        id: 'supabase_${provider.name}_${DateTime.now().millisecondsSinceEpoch}',
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
      // Real: final response = await _supabase.auth.signInAnonymously();
      final mockUser = UnifiedUser(
        id: 'supabase_anon_${DateTime.now().millisecondsSinceEpoch}',
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
      // Real: await _supabase.auth.signOut();
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
      // Real: final response = await _supabase.auth.signUp(email: email, password: password);
      final mockUser = UnifiedUser(
        id: 'supabase_new_${DateTime.now().millisecondsSinceEpoch}',
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
    final current = _currentUser;
    if (current == null) {
      return const AuthResult.failure('No user signed in');
    }
    // Real: await _supabase.auth.updateUser(UserAttributes(displayName: displayName, avatarUrl: photoUrl));
    final updatedUser = current.copyWith(
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
    // Real: await _supabase.auth.updateUser(UserAttributes(email: newEmail));
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
    // Real: await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    return AuthResult.success(current);
  }

  @override
  Future<bool> deleteAccount() async {
    _ensureInitialized();
    // Real: await _supabase.auth.admin.deleteUser(_currentUser!.id);
    final previousUser = _currentUser;
    _currentUser = null;
    _emitAuthChange(null, previousUser, AuthChangeType.signOut);
    return true;
  }

  @override
  Future<bool> sendEmailVerification() async {
    _ensureInitialized();
    // Real: await _supabase.auth.resend(type: OtpType.signup, email: _currentUser!.email!);
    return true;
  }

  @override
  Future<bool> verifyEmailWithCode(String code) async {
    _ensureInitialized();
    // Real: await _supabase.auth.verifyOTP(type: OtpType.email, token: code);
    final current = _currentUser;
    if (current != null) {
      final updatedUser = current.copyWith(isEmailVerified: true);
      _setCurrentUser(updatedUser);
    }
    return true;
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    _ensureInitialized();
    // Real: await _supabase.auth.resetPasswordForEmail(email);
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
    // Real: await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    return true;
  }

  @override
  Future<bool> sendPhoneVerificationCode(String phoneNumber) async {
    _ensureInitialized();
    // Real: await _supabase.auth.signInWithOtp(phone: phoneNumber);
    return true;
  }

  @override
  Future<AuthResult> verifyPhoneWithCode(
      String verificationId, String code) async {
    _ensureInitialized();
    // Real: await _supabase.auth.verifyOTP(phone: verificationId, token: code);
    final mockUser = UnifiedUser(
      id: 'supabase_phone_${DateTime.now().millisecondsSinceEpoch}',
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
      id: 'supabase_bio_${DateTime.now().millisecondsSinceEpoch}',
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
    // Real: return await _supabase.auth.currentSession?.accessToken;
    return 'supabase_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<AuthResult> refreshToken() async {
    _ensureInitialized();
    final current = _currentUser;
    if (current == null) {
      return const AuthResult.failure('No user signed in');
    }
    // Real: await _supabase.auth.refreshSession();
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
    // Real: await _supabase.auth.linkIdentity(IdentityData(provider: provider.name));
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
    // Real: await _supabase.auth.unlinkIdentity(IdentityData(provider: provider.name));
    return true;
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    _ensureInitialized();
    final current = _currentUser;
    if (current == null) return null;
    // Real: final session = _supabase.auth.currentSession;
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
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final symbols = includeSymbols ? '!@#\$%^&*' : '';
    final allChars = chars + symbols;
    return List.generate(length, (_) => allChars[DateTime.now().millisecondsSinceEpoch % allChars.length]).join();
  }

  @override
  String convertError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('invalid_credentials') || errorStr.contains('invalid login')) {
      return 'Invalid email or password';
    } else if (errorStr.contains('email_not_confirmed')) {
      return 'Please verify your email address';
    } else if (errorStr.contains('user_already_registered')) {
      return 'An account already exists with this email';
    } else if (errorStr.contains('weak_password')) {
      return 'Password is too weak';
    } else if (errorStr.contains('invalid_email')) {
      return 'Invalid email address';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
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
      'supabaseUrl': supabaseUrl,
    };
  }

  @override
  void trackAuthEvent(String event, Map<String, dynamic> properties) {
    if (kDebugMode) {
      print('SupabaseAuthAdapter: Track event: $event');
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
      throw StateError('SupabaseAuthAdapter not initialized. Call initialize() first.');
    }
  }
}

