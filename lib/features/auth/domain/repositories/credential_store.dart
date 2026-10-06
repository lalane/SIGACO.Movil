typedef SavedCredentials = ({String email, String password});

/// Credenciales guardadas en el dispositivo. Hay dos usos que comparten el mismo
/// registro cifrado: "recordar correo y contrasena" (rellena el formulario) y
/// el acceso con biometria (exige huella o rostro para leerlo).
abstract interface class CredentialStore {
  bool get rememberEnabled;

  String? get rememberedEmail;

  Future<String?> readRememberedPassword();

  /// Guarda o borra lo recordado. Si la biometria sigue activa, el registro se conserva.
  Future<void> setRemembered({
    required bool remember,
    SavedCredentials? credentials,
  });

  bool get biometricEnabled;

  bool get biometricOfferDeclined;

  Future<void> declineBiometricOffer();
  Future<bool> deviceSupportsBiometrics();

  /// Pide biometria y, si se confirma, guarda las credenciales cifradas.
  Future<bool> enableBiometric(String reason, SavedCredentials credentials);

  /// Actualiza la contrasena guardada (por ejemplo tras cambiarla).
  Future<void> refreshStoredPassword(String password);

  Future<SavedCredentials?> readWithBiometric(String reason);

  Future<void> disableBiometric();

  /// La contrasena cambio fuera de la app (restablecimiento por enlace): la
  /// guardada ya no sirve. Se borra y se desactiva la biometria; el correo
  /// recordado se conserva para rellenar el formulario.
  Future<void> forgetPassword();
}
