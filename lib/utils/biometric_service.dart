import 'dart:io';
import 'package:local_auth/local_auth.dart';

/// Clean biometric service:
/// - Android → fingerprint only
/// - iPhone  → Face ID or Touch ID automatically
class BiometricService {
  static final _auth = LocalAuthentication();

  // ── Check if biometric is available ──────────────────────────────────────
  static Future<bool> isAvailable() async {
    try {
      final canCheck    = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final types = await _auth.getAvailableBiometrics();

      if (Platform.isAndroid) {
        // Android: only show if fingerprint is available
        return types.contains(BiometricType.fingerprint) ||
               types.contains(BiometricType.strong) ||
               types.contains(BiometricType.weak);
      } else {
        // iPhone: Face ID or Touch ID
        return types.isNotEmpty;
      }
    } catch (_) {
      return false;
    }
  }

  // ── Authenticate ──────────────────────────────────────────────────────────
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: Platform.isIOS
            ? 'Use Face ID or Touch ID to access Spendly'
            : 'Use your fingerprint to access Spendly',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Which icon to show ────────────────────────────────────────────────────
  static Future<BioIcon> getIcon() async {
    try {
      if (Platform.isIOS) {
        final types = await _auth.getAvailableBiometrics();
        if (types.contains(BiometricType.face)) return BioIcon.face;
        return BioIcon.fingerprint;
      }
      // Android always shows fingerprint
      return BioIcon.fingerprint;
    } catch (_) {
      return BioIcon.fingerprint;
    }
  }
}

enum BioIcon { fingerprint, face }
