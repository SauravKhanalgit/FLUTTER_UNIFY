/// 🔌 Authentication Adapter Interface
///
/// This defines the pluggable authentication system that allows
/// developers to swap between different authentication backends
/// (Firebase, Supabase, Auth0, custom) without changing app code.
///
/// Similar to how Bloc has Repository pattern, this provides
/// a clean abstraction for authentication services.

import 'dart:async';
import '../models/auth_models.dart';

/// Base authentication adapter interface
///
/// All authentication backends must implement this interface
/// to be compatible with Flutter Unify's authentication system.
///
/// Example implementations:
/// - FirebaseAuthAdapter
/// - SupabaseAuthAdapter
/// - Auth0Adapter
/// - CustomAuthAdapter
abstract class AuthAdapter {
  /// Adapter name (for debugging and configuration)
  String get name;

  /// Adapter version
  String get version;

  /// Supported authentication providers
  List<AuthProvider> get supportedProviders;

  /// Whether this adapter supports offline authentication
  bool get supportsOfflineAuth => false;

  /// Whether this adapter supports biometric authentication
  bool get supportsBiometrics => false;

  /// Whether this adapter supports multi-factor authentication
  bool get supportsMFA => false;

  /// Initialize the authentication adapter
  ///
  /// This is called once when Unify is initialized.
  /// Use this to set up connections, load configurations, etc.
  Future<bool> initialize();

  /// Dispose of the adapter and clean up resources
  Future<void> dispose();

  // Core Authentication Methods

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(String email, String password);

  /// Sign in with authentication provider (Google, Apple, etc.)
  Future<AuthResult> signInWithProvider(AuthProvider provider,
      {Map<String, dynamic>? parameters});

  /// Sign in with custom credentials
  Future<AuthResult> signInWithCredential(AuthCredential credential);

  /// Sign in anonymously
  Future<AuthResult> signInAnonymously();

  /// Sign out current user
  Future<bool> signOut();

  /// Sign out from all devices
  Future<bool> signOutFromAllDevices();

  // User Management

  /// Create user with email and password
  Future<AuthResult> createUserWithEmailAndPassword(
      String email, String password);

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? customClaims,
  });

  /// Update user email
  Future<AuthResult> updateEmail(String newEmail);

  /// Update user password
  Future<AuthResult> updatePassword(String newPassword);

  /// Delete user account
  Future<bool> deleteAccount();

  // Email Verification

  /// Send email verification
  Future<bool> sendEmailVerification();

  /// Verify email with code
  Future<bool> verifyEmailWithCode(String code);

  // Password Reset

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email);

  /// Verify password reset code
  Future<bool> verifyPasswordResetCode(String code);

  /// Confirm password reset with new password
  Future<bool> confirmPasswordReset(String code, String newPassword);

  // Phone Authentication

  /// Send phone verification code
  Future<bool> sendPhoneVerificationCode(String phoneNumber);

  /// Verify phone with code
  Future<AuthResult> verifyPhoneWithCode(String verificationId, String code);

  // Biometric Authentication

  /// Check if biometric authentication is available
  Future<BiometricType> getBiometricType();

  /// Authenticate with biometrics
  Future<AuthResult> authenticateWithBiometrics(
      {String reason = 'Authenticate to continue'});

  // Multi-Factor Authentication

  /// Enroll in multi-factor authentication
  Future<bool> enrollMFA(MFAType type, {Map<String, dynamic>? parameters});

  /// Send MFA challenge
  Future<MFAChallenge> sendMFAChallenge(MFAType type);

  /// Verify MFA challenge
  Future<AuthResult> verifyMFAChallenge(String challengeId, String code);

  /// Disable MFA
  Future<bool> disableMFA(MFAType type);

  // Token Management

  /// Get current user's ID token
  Future<String?> getIdToken({bool forceRefresh = false});

  /// Refresh authentication tokens
  Future<AuthResult> refreshToken();

  /// Validate token
  Future<bool> validateToken(String token);

  // Account Linking

  /// Link account with provider
  Future<AccountLinkResult> linkWithProvider(AuthProvider provider,
      {Map<String, dynamic>? parameters});

  /// Link account with credential
  Future<AccountLinkResult> linkWithCredential(AuthCredential credential);

  /// Unlink account from provider
  Future<bool> unlinkFromProvider(AuthProvider provider);

  // Session Management

  /// Get current session information
  Future<AuthSession?> getCurrentSession();

  /// Get all active sessions
  Future<List<AuthSession>> getActiveSessions();

  /// Revoke session
  Future<bool> revokeSession(String sessionId);

  /// Revoke all other sessions
  Future<bool> revokeAllOtherSessions();

  // User State

  /// Get current authenticated user
  UnifiedUser? get currentUser;

  /// Whether user is currently signed in
  bool get isSignedIn => currentUser != null;

  /// Stream of authentication state changes
  Stream<AuthStateChangeEvent> get onAuthStateChanged;

  /// Stream of ID token changes
  Stream<String?> get onIdTokenChanged;

  // Utility Methods

  /// Validate email format
  bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  PasswordValidationResult validatePassword(String password,
      [PasswordPolicy? policy]) {
    final effectivePolicy = policy ?? const PasswordPolicy();
    return effectivePolicy.validate(password);
  }

  /// Generate secure password
  String generateSecurePassword({int length = 16, bool includeSymbols = true});

  // Error Handling

  /// Convert platform-specific error to unified error
  String convertError(dynamic error);

  /// Whether error is recoverable
  bool isRecoverableError(dynamic error);

  // Configuration

  /// Update adapter configuration
  Future<bool> updateConfiguration(Map<String, dynamic> config);

  /// Get current configuration
  Map<String, dynamic> getConfiguration();

  // Analytics & Monitoring

  /// Track authentication event
  void trackAuthEvent(String event, Map<String, dynamic> properties);

  /// Get authentication metrics
  Future<Map<String, dynamic>> getMetrics();
}

/// Mock authentication adapter for testing
///
/// This adapter simulates authentication operations without
/// requiring real backend services. Perfect for unit tests
/// and development.
class MockAuthAdapter extends AuthAdapter {
  MockAuthAdapter({
    this.shouldSucceed = true,
    this.simulateDelay = const Duration(milliseconds: 500),
    this.mockUser,
  });

  final bool shouldSucceed;
  final Duration simulateDelay;
  final UnifiedUser? mockUser;

  UnifiedUser? _currentUser;
  final StreamController<AuthStateChangeEvent> _authStateController =
      StreamController.broadcast();

  @override
  String get name => 'MockAuthAdapter';

  @override
  String get version => '1.0.0';

  @override
  List<AuthProvider> get supportedProviders => AuthProvider.values;

  @override
  bool get supportsOfflineAuth => true;

  @override
  bool get supportsBiometrics => true;

  @override
  bool get supportsMFA => true;

  @override
  Future<bool> initialize() async {
    await Future.delayed(simulateDelay);
    return true;
  }

  @override
  Future<void> dispose() async {
    await _authStateController.close();
  }

  @override
  Future<AuthResult> signInWithEmailAndPassword(
      String email, String password) async {
    await Future.delayed(simulateDelay);

    if (!shouldSucceed) {
      return const AuthResult.failure('Mock authentication failed');
    }

    final user = mockUser ??
        UnifiedUser(
          id: 'mock_user_123',
          email: email,
          displayName: 'Mock User',
          isEmailVerified: true,
          providers: [AuthProvider.emailPassword],
          createdAt: DateTime.now(),
          lastSignInAt: DateTime.now(),
        );

    _setCurrentUser(user);
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> signInWithProvider(AuthProvider provider,
      {Map<String, dynamic>? parameters}) async {
    await Future.delayed(simulateDelay);

    if (!shouldSucceed) {
      return const AuthResult.failure('Mock provider authentication failed');
    }

    final user = mockUser ??
        UnifiedUser(
          id: 'mock_user_provider_123',
          email: 'mock@example.com',
          displayName: 'Mock Provider User',
          isEmailVerified: true,
          providers: [provider],
          createdAt: DateTime.now(),
          lastSignInAt: DateTime.now(),
        );

    _setCurrentUser(user);
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> signInWithCredential(AuthCredential credential) async {
    await Future.delayed(simulateDelay);
    return signInWithProvider(credential.provider);
  }

  @override
  Future<AuthResult> signInAnonymously() async {
    await Future.delayed(simulateDelay);

    if (!shouldSucceed) {
      return const AuthResult.failure('Mock anonymous authentication failed');
    }

    final user = UnifiedUser(
      id: 'mock_anonymous_123',
      providers: [AuthProvider.anonymous],
      createdAt: DateTime.now(),
      lastSignInAt: DateTime.now(),
    );

    _setCurrentUser(user);
    return AuthResult.success(user);
  }

  @override
  Future<bool> signOut() async {
    await Future.delayed(simulateDelay);
    _setCurrentUser(null);
    return shouldSucceed;
  }

  @override
  Future<bool> signOutFromAllDevices() async {
    await Future.delayed(simulateDelay);
    _setCurrentUser(null);
    return shouldSucceed;
  }

  void _setCurrentUser(UnifiedUser? user) {
    final previousUser = _currentUser;
    _currentUser = user;

    final event = AuthStateChangeEvent(
      user: user,
      previousUser: previousUser,
      changeType: user != null ? AuthChangeType.signIn : AuthChangeType.signOut,
    );

    _authStateController.add(event);
  }

  @override
  UnifiedUser? get currentUser => _currentUser;

  @override
  Stream<AuthStateChangeEvent> get onAuthStateChanged =>
      _authStateController.stream;

  @override
  Stream<String?> get onIdTokenChanged =>
      onAuthStateChanged.map((event) => event.user?.id);

  // Simplified implementations for other required methods
  @override
  Future<AuthResult> createUserWithEmailAndPassword(
          String email, String password) =>
      signInWithEmailAndPassword(email, password);

  @override
  Future<AuthResult> updateProfile(
      {String? displayName,
      String? photoUrl,
      Map<String, dynamic>? customClaims}) async {
    await Future.delayed(simulateDelay);
    if (_currentUser == null)
      return const AuthResult.failure('No user signed in');

    final updatedUser = _currentUser!.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
      customClaims: customClaims,
    );

    _setCurrentUser(updatedUser);
    return AuthResult.success(updatedUser);
  }

  @override
  Future<AuthResult> updateEmail(String newEmail) async {
    await Future.delayed(simulateDelay);
    if (_currentUser == null)
      return const AuthResult.failure('No user signed in');

    final updatedUser = _currentUser!.copyWith(email: newEmail);
    _setCurrentUser(updatedUser);
    return AuthResult.success(updatedUser);
  }

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed
        ? AuthResult.success(_currentUser!)
        : const AuthResult.failure('Failed to update password');
  }

  @override
  Future<bool> deleteAccount() async {
    await Future.delayed(simulateDelay);
    if (shouldSucceed) _setCurrentUser(null);
    return shouldSucceed;
  }

  @override
  Future<bool> sendEmailVerification() async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<bool> verifyEmailWithCode(String code) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<bool> verifyPasswordResetCode(String code) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<bool> sendPhoneVerificationCode(String phoneNumber) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<AuthResult> verifyPhoneWithCode(
      String verificationId, String code) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed
        ? AuthResult.success(_currentUser ??
            UnifiedUser(id: 'phone_user', phoneNumber: '+1234567890'))
        : const AuthResult.failure('Phone verification failed');
  }

  @override
  Future<BiometricType> getBiometricType() async {
    await Future.delayed(simulateDelay);
    return BiometricType.fingerprint;
  }

  @override
  Future<AuthResult> authenticateWithBiometrics(
      {String reason = 'Authenticate to continue'}) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed
        ? AuthResult.success(_currentUser ?? UnifiedUser(id: 'biometric_user'))
        : const AuthResult.failure('Biometric authentication failed');
  }

  @override
  Future<bool> enrollMFA(MFAType type,
      {Map<String, dynamic>? parameters}) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<MFAChallenge> sendMFAChallenge(MFAType type) async {
    await Future.delayed(simulateDelay);
    if (!shouldSucceed) throw Exception('MFA challenge failed');

    return MFAChallenge(
      id: 'mock_challenge_123',
      type: type,
      method: 'email',
      hint: 'Enter code sent to mock@example.com',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<AuthResult> verifyMFAChallenge(String challengeId, String code) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed
        ? AuthResult.success(_currentUser!)
        : const AuthResult.failure('MFA verification failed');
  }

  @override
  Future<bool> disableMFA(MFAType type) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    await Future.delayed(simulateDelay);
    return _currentUser?.id;
  }

  @override
  Future<AuthResult> refreshToken() async {
    await Future.delayed(simulateDelay);
    return _currentUser != null
        ? AuthResult.success(_currentUser!)
        : const AuthResult.failure('No user to refresh token for');
  }

  @override
  Future<bool> validateToken(String token) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<AccountLinkResult> linkWithProvider(AuthProvider provider,
      {Map<String, dynamic>? parameters}) async {
    await Future.delayed(simulateDelay);
    if (_currentUser == null) {
      return const AccountLinkResult.failure('No user signed in');
    }

    if (!shouldSucceed) {
      return const AccountLinkResult.failure('Account linking failed');
    }

    final updatedUser = _currentUser!.copyWith(
      providers: [..._currentUser!.providers, provider],
    );

    _setCurrentUser(updatedUser);
    return AccountLinkResult.success(updatedUser);
  }

  @override
  Future<AccountLinkResult> linkWithCredential(
      AuthCredential credential) async {
    return linkWithProvider(credential.provider);
  }

  @override
  Future<bool> unlinkFromProvider(AuthProvider provider) async {
    await Future.delayed(simulateDelay);
    if (_currentUser == null) return false;

    if (shouldSucceed) {
      final updatedProviders =
          _currentUser!.providers.where((p) => p != provider).toList();
      final updatedUser = _currentUser!.copyWith(providers: updatedProviders);
      _setCurrentUser(updatedUser);
    }

    return shouldSucceed;
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    await Future.delayed(simulateDelay);
    if (_currentUser == null) return null;

    return AuthSession(
      id: 'mock_session_123',
      user: _currentUser!,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
    );
  }

  @override
  Future<List<AuthSession>> getActiveSessions() async {
    await Future.delayed(simulateDelay);
    final currentSession = await getCurrentSession();
    return currentSession != null ? [currentSession] : [];
  }

  @override
  Future<bool> revokeSession(String sessionId) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Future<bool> revokeAllOtherSessions() async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  String generateSecurePassword({int length = 16, bool includeSymbols = true}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final availableChars = includeSymbols ? chars + symbols : chars;

    return List.generate(
        length,
        (index) => availableChars[
            (DateTime.now().millisecondsSinceEpoch + index) %
                availableChars.length]).join();
  }

  @override
  String convertError(dynamic error) {
    return error.toString();
  }

  @override
  bool isRecoverableError(dynamic error) {
    return true;
  }

  @override
  Future<bool> updateConfiguration(Map<String, dynamic> config) async {
    await Future.delayed(simulateDelay);
    return shouldSucceed;
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'name': name,
      'version': version,
      'shouldSucceed': shouldSucceed,
      'simulateDelay': simulateDelay.inMilliseconds,
    };
  }

  @override
  void trackAuthEvent(String event, Map<String, dynamic> properties) {
    // Mock implementation - could log to console in debug mode
  }

  @override
  Future<Map<String, dynamic>> getMetrics() async {
    await Future.delayed(simulateDelay);
    return {
      'totalSignIns': 100,
      'totalSignUps': 50,
      'activeUsers': 25,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
