import '../../domain/entities/app_alert.dart';
import '../../domain/repositories/alerts_repository.dart';

/// Mientras el backend no publique las alertas de la persona, la pantalla dice
/// que no estan disponibles en lugar de inventar datos. Con `SAMPLE_ALERTS=true`
/// se usa `SampleAlertsRepository`.
class UnavailableAlertsRepository implements AlertsRepository {
  const UnavailableAlertsRepository();

  static const _error = AlertsException(AlertsError.notAvailable);

  @override
  Future<List<AppAlert>> list() => Future.error(_error);

  @override
  Future<void> markRead(String id) => Future.error(_error);

  @override
  Future<void> markAllRead() => Future.error(_error);
}
