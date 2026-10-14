import '../api/api_client.dart';
import '../api/api_failure.dart';
import 'concession_zone.dart';

/// De donde sale la zona horaria de una concesion cuando la marca no la trae
/// (DEV-MOB-057, RN-04: las fechas del negocio se muestran en la zona de la
/// concesion, no en la del telefono).
abstract interface class ConcessionZoneSource {
  /// La zona de [concessionId]; null si no se pudo saber (sin red, sin zona
  /// configurada): se usa la del telefono como respaldo.
  Future<ConcessionZone?> load(String concessionId);
}

/// Sin fuente (pruebas): la concesion no trae zona.
class NoConcessionZoneSource implements ConcessionZoneSource {
  const NoConcessionZoneSource();

  @override
  Future<ConcessionZone?> load(String concessionId) async => null;
}

/// La zona que el backend guarda por concesion para el gestor documental
/// (`/api/document-settings/concessions/{id}/time-zone`).
class ApiConcessionZoneSource implements ConcessionZoneSource {
  const ApiConcessionZoneSource(this._api);

  final ApiClient _api;

  @override
  Future<ConcessionZone?> load(String concessionId) async {
    try {
      final json = await _api.get(
        '/api/document-settings/concessions/$concessionId/time-zone',
      );
      return ConcessionZone.tryParse(json?['timeZone'] as String?);
    } on ApiFailure {
      return null;
    }
  }
}
