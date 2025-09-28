/// 🔐 Authentication Models
///
/// Data structures for the unified authentication system.
/// These models provide a consistent interface across all
/// authentication providers and platforms.

import 'package:meta/meta.dart';

/// Authentication result wrapper
///
/// Similar to Result pattern in functional programming,
/// this provides a clean way to handle auth operations.
@immutable
class AuthResult {
  /// Create a successful authentication result
  const AuthResult.success(UnifiedUser user)
      : success = true,
        user = user,
        error = null,
        errorCode = null;

  /// Create a failed authentication result
  const AuthResult.failure(String error, {String? errorCode})
      : success = false,
        user = null,
        error = error,
        errorCode = errorCode;

  /// Whether the authentication was successful
  final bool success;

  /// The authenticated user (if successful)
  final UnifiedUser? user;

  /// Error message (if failed)
  final String? error;

  /// Platform-specific error code (if failed)
  final String? errorCode;

  /// Whether this result represents a failure
  bool get isFailure => !success;

  @override
  String toString() {
    if (success) {
      return 'AuthResult.success(user: ${user?.displayName ?? user?.email ?? 'Anonymous'})';
    } else {
      return 'AuthResult.failure(error: $error, code: $errorCode)';
    }
  }
}

/// Unified user model that works across all auth providers
///
/// This abstraction allows switching between Firebase, Supabase,
/// Auth0, or any custom authentication backend without changing
/// your app code.
@immutable
class UnifiedUser {
  const UnifiedUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.providers = const [],
    this.customClaims = const {},
    this.createdAt,
    this.lastSignInAt,
    this.metadata = const {},
  });

  /// Unique user identifier
  final String id;

  /// User's email address
  final String? email;

  /// User's display name
  final String? displayName;

  /// User's profile photo URL
  final String? photoUrl;

  /// User's phone number
  final String? phoneNumber;

  /// Whether the email is verified
  final bool isEmailVerified;

  /// Whether the phone number is verified
  final bool isPhoneVerified;

  /// List of authentication providers used
  final List<AuthProvider> providers;

  /// Custom claims/attributes for the user
  final Map<String, dynamic> customClaims;

  /// When the user account was created
  final DateTime? createdAt;

  /// When the user last signed in
  final DateTime? lastSignInAt;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// Whether this is an anonymous user
  bool get isAnonymous =>
      providers.isEmpty || providers.contains(AuthProvider.anonymous);

  /// Primary display identifier (name, email, or ID)
  String get primaryIdentifier => displayName ?? email ?? phoneNumber ?? id;

  /// Create a copy with updated values
  UnifiedUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    List<AuthProvider>? providers,
    Map<String, dynamic>? customClaims,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    Map<String, dynamic>? metadata,
  }) {
    return UnifiedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      providers: providers ?? this.providers,
      customClaims: customClaims ?? this.customClaims,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UnifiedUser(id: $id, email: $email, displayName: $displayName, isAnonymous: $isAnonymous)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Authentication providers supported by Flutter Unify
enum AuthProvider {
  /// Email and password authentication
  emailPassword,

  /// Google OAuth
  google,

  /// Apple Sign In
  apple,

  /// Facebook OAuth
  facebook,

  /// GitHub OAuth
  github,

  /// Twitter OAuth
  twitter,

  /// Microsoft OAuth
  microsoft,

  /// Anonymous authentication
  anonymous,

  /// Phone number authentication
  phone,

  /// Biometric authentication (Touch ID, Face ID, Fingerprint)
  biometric,

  /// Custom authentication provider
  custom,

  /// Single Sign-On (SSO)
  sso,

  /// Multi-factor authentication
  mfa,
}

/// Authentication state change event
@immutable
class AuthStateChangeEvent {
  const AuthStateChangeEvent({
    required this.user,
    required this.previousUser,
    required this.changeType,
    this.metadata = const {},
  });

  /// Current user (null if signed out)
  final UnifiedUser? user;

  /// Previous user state
  final UnifiedUser? previousUser;

  /// Type of change that occurred
  final AuthChangeType changeType;

  /// Additional metadata about the change
  final Map<String, dynamic> metadata;

  @override
  String toString() {
    return 'AuthStateChangeEvent(changeType: $changeType, user: ${user?.primaryIdentifier ?? 'null'})';
  }
}

/// Types of authentication state changes
enum AuthChangeType {
  /// User signed in
  signIn,

  /// User signed out
  signOut,

  /// User profile updated
  profileUpdate,

  /// User tokens refreshed
  tokenRefresh,

  /// User verification status changed
  verificationUpdate,

  /// User account linked/unlinked
  accountLink,

  /// Authentication error occurred
  error,
}

/// Biometric authentication types
enum BiometricType {
  /// No biometric authentication available
  none,

  /// Fingerprint authentication
  fingerprint,

  /// Face recognition (Face ID, Face Unlock)
  face,

  /// Iris recognition
  iris,

  /// Voice recognition
  voice,

  /// General biometric (multiple types available)
  multiple,
}

/// Sign-in credentials for different providers
@immutable
abstract class AuthCredential {
  const AuthCredential({
    required this.provider,
    this.metadata = const {},
  });

  /// The authentication provider
  final AuthProvider provider;

  /// Additional metadata
  final Map<String, dynamic> metadata;
}

/// Email and password credentials
@immutable
class EmailPasswordCredential extends AuthCredential {
  const EmailPasswordCredential({
    required this.email,
    required this.password,
    super.metadata,
  }) : super(provider: AuthProvider.emailPassword);

  final String email;
  final String password;
}

/// OAuth credentials
@immutable
class OAuthCredential extends AuthCredential {
  const OAuthCredential({
    required super.provider,
    required this.accessToken,
    this.idToken,
    this.refreshToken,
    super.metadata,
  });

  final String accessToken;
  final String? idToken;
  final String? refreshToken;
}

/// Phone number credentials
@immutable
class PhoneCredential extends AuthCredential {
  const PhoneCredential({
    required this.phoneNumber,
    required this.verificationCode,
    this.verificationId,
    super.metadata,
  }) : super(provider: AuthProvider.phone);

  final String phoneNumber;
  final String verificationCode;
  final String? verificationId;
}

/// Biometric credentials
@immutable
class BiometricCredential extends AuthCredential {
  const BiometricCredential({
    required this.biometricType,
    this.reason = 'Authenticate to continue',
    super.metadata,
  }) : super(provider: AuthProvider.biometric);

  final BiometricType biometricType;
  final String reason;
}

/// Session information
@immutable
class AuthSession {
  const AuthSession({
    required this.id,
    required this.user,
    required this.createdAt,
    required this.expiresAt,
    this.refreshToken,
    this.accessToken,
    this.isActive = true,
    this.deviceInfo = const {},
  });

  /// Unique session identifier
  final String id;

  /// User associated with this session
  final UnifiedUser user;

  /// When the session was created
  final DateTime createdAt;

  /// When the session expires
  final DateTime expiresAt;

  /// Refresh token for extending the session
  final String? refreshToken;

  /// Access token for API calls
  final String? accessToken;

  /// Whether the session is currently active
  final bool isActive;

  /// Device information for this session
  final Map<String, dynamic> deviceInfo;

  /// Whether the session is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Time remaining until expiration
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  @override
  String toString() {
    return 'AuthSession(id: $id, user: ${user.primaryIdentifier}, isActive: $isActive, isExpired: $isExpired)';
  }
}

/// Multi-factor authentication challenge
@immutable
class MFAChallenge {
  const MFAChallenge({
    required this.id,
    required this.type,
    required this.method,
    this.hint,
    this.expiresAt,
    this.metadata = const {},
  });

  /// Challenge identifier
  final String id;

  /// Type of MFA challenge
  final MFAType type;

  /// Method for completing the challenge
  final String method;

  /// Hint for the user (e.g., "Enter code sent to ***@email.com")
  final String? hint;

  /// When the challenge expires
  final DateTime? expiresAt;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// Whether the challenge is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Multi-factor authentication types
enum MFAType {
  /// SMS verification code
  sms,

  /// Email verification code
  email,

  /// Time-based one-time password (TOTP)
  totp,

  /// Push notification approval
  push,

  /// Biometric verification
  biometric,

  /// Hardware security key
  securityKey,

  /// Backup codes
  backupCode,
}

/// Account linking result
@immutable
class AccountLinkResult {
  const AccountLinkResult.success(UnifiedUser user)
      : success = true,
        user = user,
        error = null,
        conflictingAccount = null;

  const AccountLinkResult.failure(String error,
      {UnifiedUser? conflictingAccount})
      : success = false,
        user = null,
        error = error,
        conflictingAccount = conflictingAccount;

  final bool success;
  final UnifiedUser? user;
  final String? error;
  final UnifiedUser? conflictingAccount;

  bool get isFailure => !success;
}

/// Password policy requirements
@immutable
class PasswordPolicy {
  const PasswordPolicy({
    this.minLength = 8,
    this.maxLength = 128,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = true,
    this.forbidCommonPasswords = true,
    this.forbidPersonalInfo = true,
    this.maxAge,
    this.minAge,
  });

  final int minLength;
  final int maxLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  final bool forbidCommonPasswords;
  final bool forbidPersonalInfo;
  final Duration? maxAge;
  final Duration? minAge;

  /// Validate a password against this policy
  PasswordValidationResult validate(String password) {
    final errors = <String>[];

    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters long');
    }

    if (password.length > maxLength) {
      errors.add('Password must be no more than $maxLength characters long');
    }

    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }

    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }

    if (requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }

    if (requireSpecialChars &&
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Password must contain at least one special character');
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// Password validation result
@immutable
class PasswordValidationResult {
  const PasswordValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  final bool isValid;
  final List<String> errors;

  bool get isInvalid => !isValid;

  @override
  String toString() {
    if (isValid) {
      return 'PasswordValidationResult(valid)';
    } else {
      return 'PasswordValidationResult(invalid: ${errors.join(', ')})';
    }
  }
}
