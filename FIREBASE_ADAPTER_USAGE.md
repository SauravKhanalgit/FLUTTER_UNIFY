# 🔥 Firebase Auth Adapter - Usage Guide

## Quick Start

### 1. Add Firebase Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter_unify: ^1.0.5
  firebase_auth: ^5.0.0
  firebase_core: ^3.0.0
```

### 2. Initialize Firebase

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Flutter Unify
  await Unify.initialize();
  
  // Register Firebase Auth Adapter
  final firebaseAdapter = FirebaseAuthAdapter();
  await firebaseAdapter.initialize();
  Unify.registerAuthAdapter(firebaseAdapter);
  
  runApp(MyApp());
}
```

### 3. Use Unified API

```dart
// Now use Unify.auth - works exactly like Firebase Auth!
await Unify.auth.signInWithEmailAndPassword('user@example.com', 'password');

// Listen to auth state changes
Unify.auth.onAuthStateChanged.listen((event) {
  if (event.user != null) {
    print('User signed in: ${event.user!.email}');
  } else {
    print('User signed out');
  }
});
```

## Features

### ✅ All Firebase Auth Methods Supported

- Email/Password authentication
- OAuth providers (Google, Apple, Facebook, etc.)
- Anonymous authentication
- Phone authentication
- Biometric authentication
- Multi-factor authentication (MFA)
- Account linking
- Session management

### ✅ Unified API Benefits

- **Zero Lock-in**: Switch from Firebase to Supabase/Auth0 without code changes
- **Consistent**: Same API across all platforms
- **Reactive**: Stream-based auth state changes
- **Type-safe**: Full null safety and type checking

## Examples

### Email/Password

```dart
// Sign up
final result = await Unify.auth.createUserWithEmailAndPassword(
  'user@example.com',
  'password123',
);

if (result.success) {
  print('User created: ${result.user?.email}');
}

// Sign in
final signInResult = await Unify.auth.signInWithEmailAndPassword(
  'user@example.com',
  'password123',
);
```

### OAuth Providers

```dart
// Sign in with Google
await Unify.auth.signInWithProvider(AuthProvider.google);

// Sign in with Apple
await Unify.auth.signInWithProvider(AuthProvider.apple);
```

### Biometric Authentication

```dart
// Check if biometrics available
final biometricType = await Unify.auth.getBiometricType();
if (biometricType != BiometricType.none) {
  // Authenticate with biometrics
  final result = await Unify.auth.authenticateWithBiometrics(
    reason: 'Authenticate to access your account',
  );
}
```

### Multi-Factor Authentication

```dart
// Enroll in MFA
await Unify.auth.enrollMFA(MFAType.totp);

// Send challenge
final challenge = await Unify.auth.sendMFAChallenge(MFAType.totp);

// Verify challenge
await Unify.auth.verifyMFAChallenge(challenge.id, '123456');
```

## Migration from Firebase Auth

If you're currently using Firebase Auth directly:

### Before (Firebase Auth)
```dart
final auth = FirebaseAuth.instance;
await auth.signInWithEmailAndPassword(email: email, password: password);
auth.authStateChanges().listen((user) { ... });
```

### After (Flutter Unify)
```dart
await Unify.auth.signInWithEmailAndPassword(email, password);
Unify.auth.onAuthStateChanged.listen((event) { ... });
```

**Benefits:**
- Same functionality
- Can switch providers later
- Unified with other Unify features
- Better error handling

## Error Handling

```dart
try {
  final result = await Unify.auth.signInWithEmailAndPassword(email, password);
  if (!result.success) {
    // Handle error
    print('Error: ${result.error}');
  }
} catch (e) {
  // Handle exception
  print('Exception: $e');
}
```

## Next Steps

1. **Add Firebase package** to your `pubspec.yaml`
2. **Initialize Firebase** in your app
3. **Register adapter** with Unify
4. **Start using** `Unify.auth` API

That's it! You now have Firebase Auth through the unified API! 🎉

