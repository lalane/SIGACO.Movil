import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/credential_store.dart';

/// Un solo registro cifrado (Keystore) con correo y contrasena. Lo usan dos
/// funciones independientes: recordar credenciales y acceso con biometria; el
/// registro se borra cuando ninguna de las dos esta activa.
/// Pendiente de ratificar por Seguridad.
class CredentialVault implements CredentialStore {
  CredentialVault(this._secure, this._prefs, this._auth);

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;
  final LocalAuthentication _auth;

  static const _kRemember = 'remember_enabled';
  static const _kRememberedEmail = 'remembered_email';
  static const _kBioEnabled = 'biometric_enabled';
  static const _kBioDeclined = 'biometric_offer_declined';
  static const _kEmail = 'credential_email';
  static const _kPassword = 'credential_password';

  @override
  bool get rememberEnabled => _prefs.getBool(_kRemember) ?? false;

  @override
  String? get rememberedEmail =>
      rememberEnabled ? _prefs.getString(_kRememberedEmail) : null;

  @override
  Future<String?> readRememberedPassword() async =>
      rememberEnabled ? _secure.read(key: _kPassword) : null;

  Future<void> _write(SavedCredentials c) async {
    await _secure.write(key: _kEmail, value: c.email);
    await _secure.write(key: _kPassword, value: c.password);
  }

  Future<void> _deleteIfUnused() async {
    if (rememberEnabled || biometricEnabled) return;
    await _secure.delete(key: _kEmail);
    await _secure.delete(key: _kPassword);
  }

  @override
  Future<void> setRemembered({
    required bool remember,
    SavedCredentials? credentials,
  }) async {
    if (remember && credentials != null) {
      await _write(credentials);
      await _prefs.setString(_kRememberedEmail, credentials.email);
      await _prefs.setBool(_kRemember, true);
    } else if (!remember) {
      await _prefs.setBool(_kRemember, false);
      await _prefs.remove(_kRememberedEmail);
      await _deleteIfUnused();
    }
  }

  @override
  bool get biometricEnabled => _prefs.getBool(_kBioEnabled) ?? false;

  @override
  bool get biometricOfferDeclined => _prefs.getBool(_kBioDeclined) ?? false;

  @override
  Future<void> declineBiometricOffer() => _prefs.setBool(_kBioDeclined, true);

  Future<void> _resetBiometricOffer() => _prefs.remove(_kBioDeclined);

  @override
  Future<bool> deviceSupportsBiometrics() async {
    try {
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _confirmIdentity(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> enableBiometric(
    String reason,
    SavedCredentials credentials,
  ) async {
    if (!await _confirmIdentity(reason)) return false;
    await _write(credentials);
    await _prefs.setBool(_kBioEnabled, true);
    return true;
  }

  @override
  Future<void> refreshStoredPassword(String password) async {
    if (!rememberEnabled && !biometricEnabled) return;
    final email = await _secure.read(key: _kEmail);
    if (email != null) await _write((email: email, password: password));
  }

  @override
  Future<SavedCredentials?> readWithBiometric(String reason) async {
    if (!biometricEnabled || !await _confirmIdentity(reason)) return null;
    final email = await _secure.read(key: _kEmail);
    final password = await _secure.read(key: _kPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  @override
  Future<void> disableBiometric() async {
    await _prefs.setBool(_kBioEnabled, false);
    await _deleteIfUnused();
  }

  @override
  Future<void> forgetPassword() async {
    await _prefs.setBool(_kBioEnabled, false);
    // Con la biometria apagada, el registro solo sirve si se recuerda el correo.
    await _secure.delete(key: _kPassword);
    await _deleteIfUnused();
    // Se vuelve a ofrecer la biometria con la nueva contrasena.
    await _resetBiometricOffer();
  }
}
