import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Unified biometric authentication adapter
abstract class BiometricAdapter {
  Future<void> initialize();
  Future<bool> isDeviceSupported();
  Future<bool> canCheckBiometrics();
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<bool> authenticate({
    String localizedReason = 'Authenticate to continue',
    bool biometricOnly = true,
    bool stickyAuth = false,
    bool useErrorDialogs = true,
  });
  Future<void> cancelAuthentication();
}

class LocalAuthBiometricAdapter implements BiometricAdapter {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // No special init required for local_auth
    _initialized = true;
  }

  @override
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  @override
  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      if (kDebugMode) {
        print('Biometrics.getAvailableBiometrics error: $e');
      }
      return <BiometricType>[];
    }
  }

  @override
  Future<bool> authenticate({
    String localizedReason = 'Authenticate to continue',
    bool biometricOnly = true,
    bool stickyAuth = false,
    bool useErrorDialogs = true,
  }) async {
    try {
      final success = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
        ),
      );
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Biometrics.authenticate error: $e');
      }
      return false;
    }
  }

  @override
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      // ignore
    }
  }
}
