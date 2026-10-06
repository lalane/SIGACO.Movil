import '../entities/concession_branding.dart';

abstract interface class BrandingRepository {
  /// Marca de la concesion activa de la sesion, o null si no tiene (la app usa
  /// entonces los colores de SIGACO). Sin conexion devuelve la ultima guardada
  /// de esa concesion.
  Future<ConcessionBranding?> load(String concessionId);
}
