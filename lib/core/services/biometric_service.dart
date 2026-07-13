import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _keyEnabled = 'biometric_enabled';
  static const String _keyEmail = 'biometric_email';
  static const String _keyPassword = 'biometric_password';

  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to log in to Bedrock Abbottabad',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricsEnabled() async {
    final String? enabled = await _secureStorage.read(key: _keyEnabled);
    return enabled == 'true';
  }

  Future<void> enableBiometrics(String email, String password) async {
    await _secureStorage.write(key: _keyEnabled, value: 'true');
    await _secureStorage.write(key: _keyEmail, value: email);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  Future<void> disableBiometrics() async {
    await _secureStorage.write(key: _keyEnabled, value: 'false');
    await _secureStorage.delete(key: _keyEmail);
    await _secureStorage.delete(key: _keyPassword);
  }

  Future<Map<String, String>?> getStoredCredentials() async {
    final email = await _secureStorage.read(key: _keyEmail);
    final password = await _secureStorage.read(key: _keyPassword);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
