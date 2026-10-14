import 'package:flutter_bloc/flutter_bloc.dart';

import 'concession_zone.dart';

/// Zona horaria de la concesion activa, disponible para cualquier modulo sin
/// que dependa del modulo de marca. La compone la app (`SessionLifecycle`):
/// null antes de iniciar sesion o si la concesion no la trae.
///
/// Tiene dos fuentes: la marca de la concesion (DTF de Configuracion), que manda
/// cuando existe, y la zona que el backend guarda para el gestor documental,
/// que sirve de respaldo. Sin ninguna se usa la del telefono.
class ConcessionZoneCubit extends Cubit<ConcessionZone?> {
  ConcessionZoneCubit() : super(null);

  ConcessionZone? _fromBranding;
  ConcessionZone? _fallback;

  /// La zona de la marca de la concesion.
  void set(ConcessionZone? zone) {
    _fromBranding = zone;
    _publish();
  }

  /// La zona del servidor para esta concesion; solo se usa si la marca no trae.
  void setFallback(ConcessionZone? zone) {
    _fallback = zone;
    _publish();
  }

  void _publish() {
    final zone = _fromBranding ?? _fallback;
    if (zone?.id != state?.id) emit(zone);
  }
}
