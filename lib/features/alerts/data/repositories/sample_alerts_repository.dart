import '../../domain/entities/app_alert.dart';
import '../../domain/repositories/alerts_repository.dart';

/// Alertas de ejemplo para ver y probar la pantalla antes de que el backend las
/// publique. Apuntan a registros de los otros datos de ejemplo.
class SampleAlertsRepository implements AlertsRepository {
  SampleAlertsRepository({DateTime? now})
    : _alerts = _seed((now ?? DateTime.now()).toUtc());

  List<AppAlert> _alerts;

  static List<AppAlert> _seed(DateTime now) {
    AppAlert a(
      String id,
      String title,
      Duration age, {
      String? body,
      bool read = false,
      AlertSeverity severity = AlertSeverity.info,
      String? type,
      String? entity,
    }) => AppAlert(
      id: id,
      title: title,
      body: body,
      createdAt: now.subtract(age),
      read: read,
      severity: severity,
      entityType: type,
      entityId: entity,
    );
    return [
      a(
        'AL-1',
        'Ticket 0038 vencido',
        const Duration(minutes: 12),
        body:
            'Luminarias apagadas en el túnel norte pasó su plazo de atención.',
        severity: AlertSeverity.critical,
        type: 'TICKET',
        entity: 'T-0038',
      ),
      a(
        'AL-2',
        'Nuevo ticket asignado',
        const Duration(hours: 1, minutes: 5),
        body: 'Señal vertical caída km 148+000.',
        severity: AlertSeverity.warning,
        type: 'TICKET',
        entity: 'T-0037',
      ),
      a(
        'AL-3',
        'Accidente registrado en tu tramo',
        const Duration(hours: 3),
        body: 'Se levantó el accidente 0036 con heridos.',
        severity: AlertSeverity.critical,
        type: 'ACCIDENT',
        entity: 'A-0036',
      ),
      a(
        'AL-4',
        'Inspección programada para hoy',
        const Duration(hours: 5),
        severity: AlertSeverity.info,
        type: 'INSPECTION',
        entity: 'I-501',
        read: true,
      ),
      a(
        'AL-5',
        'Obra con atraso',
        const Duration(days: 1, hours: 2),
        body: 'La obra O-031 acumula atraso respecto del cronograma.',
        severity: AlertSeverity.warning,
        type: 'WORK',
        entity: 'O-031',
        read: true,
      ),
      a(
        'AL-6',
        'Mantenimiento del catálogo próximo a vencer',
        const Duration(days: 2),
        severity: AlertSeverity.info,
        read: true,
      ),
    ];
  }

  @override
  Future<List<AppAlert>> list() async => List.unmodifiable(_alerts);

  @override
  Future<void> markRead(String id) async {
    _alerts = [
      for (final a in _alerts) a.id == id ? a.copyWith(read: true) : a,
    ];
  }

  @override
  Future<void> markAllRead() async {
    _alerts = [for (final a in _alerts) a.copyWith(read: true)];
  }
}
