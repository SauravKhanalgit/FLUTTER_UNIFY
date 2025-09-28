import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../common/platform_detector.dart';
import '../../common/event_emitter.dart';
import '../unify.dart';

/// Authentication provider types
enum AuthProvider {
  google,
  apple,
  facebook,
  twitter,
  github,
  microsoft,
  firebase,
  oauth,
  webauthn,
  native,
  custom,
}

/// Authentication result
class AuthResult {
  final bool success;
  final UnifiedUser? user;
  final String? error;
  final String? idToken;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? metadata;

  const AuthResult({
    required this.success,
    this.user,
    this.error,
    this.idToken,
    this.accessToken,
    this.refreshToken,
    this.metadata,
  });

  factory AuthResult.success(
    UnifiedUser user, {
    String? idToken,
    String? accessToken,
    String? refreshToken,
    Map<String, dynamic>? metadata,
  }) {
    return AuthResult(
      success: true,
      user: user,
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
      metadata: metadata,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult(
      success: false,
      error: error,
    );
  }
}

/// Unified user representation
class UnifiedUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final bool emailVerified;
  final bool isAnonymous;
  final DateTime? creationTime;
  final DateTime? lastSignInTime;
  final Map<String, dynamic>? customClaims;
  final List<AuthProvider> linkedProviders;

  const UnifiedUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.emailVerified = false,
    this.isAnonymous = false,
    this.creationTime,
    this.lastSignInTime,
    this.customClaims,
    this.linkedProviders = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'isAnonymous': isAnonymous,
      'creationTime': creationTime?.toIso8601String(),
      'lastSignInTime': lastSignInTime?.toIso8601String(),
      'customClaims': customClaims,
      'linkedProviders': linkedProviders.map((p) => p.name).toList(),
    };
  }

  factory UnifiedUser.fromJson(Map<String, dynamic> json) {
    return UnifiedUser(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      phoneNumber: json['phoneNumber'],
      emailVerified: json['emailVerified'] ?? false,
      isAnonymous: json['isAnonymous'] ?? false,
      creationTime: json['creationTime'] != null
          ? DateTime.parse(json['creationTime'])
          : null,
      lastSignInTime: json['lastSignInTime'] != null
          ? DateTime.parse(json['lastSignInTime'])
          : null,
      customClaims: json['customClaims'],
      linkedProviders: (json['linkedProviders'] as List?)
              ?.map((p) => AuthProvider.values.firstWhere(
                    (provider) => provider.name == p,
                    orElse: () => AuthProvider.custom,
                  ))
              .toList() ??
          [],
    );
  }
}

/// Unified authentication module following the new architecture
///
/// This provides reactive authentication state management with
/// adapter support for different backends (Firebase, custom OAuth, etc.)
///
/// Example:
/// ```dart
/// // Listen to auth state changes (reactive)
/// Unify.auth.onAuthStateChanged.listen((user) {
///   if (user != null) {
///     navigateToHome();
///   } else {
///     navigateToLogin();
///   }
/// });
///
/// // Sign in with different providers
/// final result = await Unify.auth.signInWithGoogle();
/// final result = await Unify.auth.signInWithApple();
/// final result = await Unify.auth.signInWithBiometrics();
/// ```
class UnifiedAuth extends EventEmitter {
  static UnifiedAuth? _instance;
  static UnifiedAuth get instance => _instance ??= UnifiedAuth._();

  UnifiedAuth._();

  bool _isInitialized = false;
  UnifiedUser? _currentUser;
  AuthConfig _config = const AuthConfig();
  AuthAdapter? _adapter;

  // Reactive streams
  final StreamController<UnifiedUser?> _authStateController =
      StreamController<UnifiedUser?>.broadcast();
  final StreamController<AuthEvent> _authEventController =
      StreamController<AuthEvent>.broadcast();

  /// Stream of authentication state changes
  ///
  /// This is the primary reactive stream for auth state.
  /// Emits whenever the user signs in, signs out, or their
  /// information changes.
  Stream<UnifiedUser?> get onAuthStateChanged => _authStateController.stream;

  /// Stream of authentication events
  ///
  /// Emits detailed authentication events like sign-in attempts,
  /// errors, token refreshes, etc. Useful for analytics and debugging.
  Stream<AuthEvent> get onAuthEvent => _authEventController.stream;

  /// Current authenticated user
  UnifiedUser? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Check if module is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize authentication system
  Future<bool> initialize(AuthConfig config) async {
    if (_isInitialized) return true;

    try {
      _config = config;

      // Initialize with adapter if provided
      if (_adapter != null) {
        await _adapter!.initialize();
      }

      // Restore previous session if enabled
      if (_config.persistSession) {
        await _restoreSession();
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ UnifiedAuth initialized');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UnifiedAuth initialization failed: $e');
      }
      return false;
    }
  }

  /// Set custom adapter (configurable backend)
  void setAdapter(AuthAdapter adapter) {
    _adapter = adapter;
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    return await _signInWithProvider(AuthProvider.google);
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    return await _signInWithProvider(AuthProvider.apple);
  }

  /// Sign in with Facebook
  Future<AuthResult> signInWithFacebook() async {
    return await _signInWithProvider(AuthProvider.facebook);
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      _emitAuthEvent(AuthEvent(
        type: AuthEventType.signInAttempt,
        provider: AuthProvider.firebase,
        data: {'email': email},
      ));

      AuthResult result;
      if (_adapter != null) {
        result = await _adapter!.signInWithEmailAndPassword(email, password);
      } else {
        result = await _defaultSignInWithEmail(email, password);
      }

      if (result.success) {
        await _setCurrentUser(result.user!);
        _emitAuthEvent(AuthEvent(
          type: AuthEventType.signInSuccess,
          provider: AuthProvider.firebase,
          user: result.user,
        ));
      } else {
        _emitAuthEvent(AuthEvent(
          type: AuthEventType.signInFailure,
          provider: AuthProvider.firebase,
          error: result.error,
        ));
      }

      return result;
    } catch (e) {
      final error = e.toString();
      _emitAuthEvent(AuthEvent(
        type: AuthEventType.signInFailure,
        provider: AuthProvider.firebase,
        error: error,
      ));
      return AuthResult.failure(error);
    }
  }

  /// Sign in with biometrics
  Future<AuthResult> signInWithBiometrics() async {
    if (!_config.enableBiometrics || !_isBiometricsSupported()) {
      return AuthResult.failure('Biometrics not supported or disabled');
    }

    try {
      _emitAuthEvent(AuthEvent(
        type: AuthEventType.signInAttempt,
        provider: AuthProvider.native,
      ));

      final result = await _signInWithBiometricsImpl();

      if (result.success) {
        await _setCurrentUser(result.user!);
        _emitAuthEvent(AuthEvent(
          type: AuthEventType.signInSuccess,
          provider: AuthProvider.native,
          user: result.user,
        ));
      }

      return result;
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// Sign in anonymously
  Future<AuthResult> signInAnonymously() async {
    try {
      final user = UnifiedUser(
        id: 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        isAnonymous: true,
        creationTime: DateTime.now(),
        lastSignInTime: DateTime.now(),
      );

      await _setCurrentUser(user);

      _emitAuthEvent(AuthEvent(
        type: AuthEventType.signInSuccess,
        provider: AuthProvider.custom,
        user: user,
      ));

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    try {
      _emitAuthEvent(AuthEvent(
        type: AuthEventType.signOutAttempt,
        user: _currentUser,
      ));

      bool success = true;

      if (_adapter != null) {
        success = await _adapter!.signOut();
      } else {
        success = await _defaultSignOut();
      }

      if (success) {
        await _setCurrentUser(null);
        _emitAuthEvent(AuthEvent(
          type: AuthEventType.signOutSuccess,
        ));
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out failed: $e');
      }
      return false;
    }
  }

  /// Refresh authentication token
  Future<AuthResult> refreshToken() async {
    if (_currentUser == null) {
      return AuthResult.failure('No user signed in');
    }

    try {
      if (_adapter != null) {
        return await _adapter!.refreshToken();
      } else {
        return await _defaultRefreshToken();
      }
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// Check if provider is available on current platform
  bool isProviderAvailable(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.webauthn:
        return kIsWeb;
      case AuthProvider.apple:
        return PlatformDetector.isIOS || PlatformDetector.isMacOS || kIsWeb;
      case AuthProvider.google:
      case AuthProvider.facebook:
      case AuthProvider.twitter:
      case AuthProvider.github:
      case AuthProvider.microsoft:
      case AuthProvider.oauth:
        return true;
      case AuthProvider.native:
        return !kIsWeb;
      case AuthProvider.firebase:
      case AuthProvider.custom:
        return true;
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    return {
      'signInAttempts': 0, // Would track actual metrics
      'signInSuccesses': 0,
      'signInFailures': 0,
      'tokenRefreshes': 0,
      'sessionDuration': 0,
    };
  }

  // Internal methods
  Future<void> _setCurrentUser(UnifiedUser? user) async {
    _currentUser = user;
    _authStateController.add(user);

    // Persist session if enabled
    if (_config.persistSession) {
      await _persistSession(user);
    }
  }

  void _emitAuthEvent(AuthEvent event) {
    _authEventController.add(event);

    // Also emit via EventEmitter for backwards compatibility
    emit('auth-event', event.toJson());
  }

  Future<AuthResult> _signInWithProvider(AuthProvider provider) async {
    if (!isProviderAvailable(provider)) {
      return AuthResult.failure('Provider not available on this platform');
    }

    try {
      _emitAuthEvent(AuthEvent(
        type: AuthEventType.signInAttempt,
        provider: provider,
      ));

      AuthResult result;
      if (_adapter != null) {
        result = await _adapter!.signInWithProvider(provider);
      } else {
        result = await _defaultSignInWithProvider(provider);
      }

      if (result.success) {
        await _setCurrentUser(result.user!);
        _emitAuthEvent(AuthEvent(
          type: AuthEventType.signInSuccess,
          provider: provider,
          user: result.user,
        ));
      } else {
        _emitAuthEvent(AuthEvent(
          type: AuthEventType.signInFailure,
          provider: provider,
          error: result.error,
        ));
      }

      return result;
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  bool _isBiometricsSupported() {
    return PlatformDetector.isMobile || PlatformDetector.isDesktop;
  }

  // Default implementations (can be overridden by adapters)
  Future<AuthResult> _defaultSignInWithEmail(
      String email, String password) async {
    // Simplified implementation
    return AuthResult.failure('Not implemented');
  }

  Future<AuthResult> _defaultSignInWithProvider(AuthProvider provider) async {
    // Simplified implementation
    return AuthResult.failure('Not implemented');
  }

  Future<AuthResult> _signInWithBiometricsImpl() async {
    // Platform-specific biometric authentication
    return AuthResult.failure('Not implemented');
  }

  Future<bool> _defaultSignOut() async {
    return true;
  }

  Future<AuthResult> _defaultRefreshToken() async {
    return AuthResult.failure('Not implemented');
  }

  Future<void> _restoreSession() async {
    // Restore previous authentication session
  }

  Future<void> _persistSession(UnifiedUser? user) async {
    // Persist authentication session
  }

  /// Dispose resources
  Future<void> dispose() async {
    await Future.wait([
      _authStateController.close(),
      _authEventController.close(),
    ]);

    await _adapter?.dispose();

    _currentUser = null;
    _isInitialized = false;
  }
}

/// Authentication event for detailed tracking
class AuthEvent {
  final AuthEventType type;
  final AuthProvider? provider;
  final UnifiedUser? user;
  final String? error;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  AuthEvent({
    required this.type,
    this.provider,
    this.user,
    this.error,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'provider': provider?.name,
      'user': user?.toJson(),
      'error': error,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Authentication event types
enum AuthEventType {
  signInAttempt,
  signInSuccess,
  signInFailure,
  signOutAttempt,
  signOutSuccess,
  signOutFailure,
  tokenRefresh,
  sessionExpired,
  biometricPrompt,
  biometricSuccess,
  biometricFailure,
}
