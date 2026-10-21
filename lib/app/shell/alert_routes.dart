import '../../features/alerts/domain/entities/app_alert.dart';
import '../../features/navigation/domain/entities/mobile_module.dart';
import '../../features/navigation/domain/entities/navigation_entities.dart';

/// Los identificadores que se aceptan en una ruta: letras, numeros y `._-`. Un
/// valor que venga del servidor con otra cosa (barras, consultas, `..`) no se
/// convierte en una pantalla de la app.
final _safeId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$');

/// A que pantalla lleva una alerta, o nulo si solo informa o la persona no puede
/// ver ese modulo (el modulo de alertas no conoce a los demas: lo compone la
/// app). Es el destino de tocar la alerta en la lista y, mas adelante, de tocar
/// la notificacion del sistema.
String? alertRoute(AppAlert alert, NavigationMenu menu) {
  final type = alert.entityType?.trim().toUpperCase();
  final id = alert.entityId?.trim();
  if (type == null || id == null || !_safeId.hasMatch(id)) return null;
  bool has(MobileModule m) => m.isAvailableIn(menu);
  return switch (type) {
    'TICKET' => has(MobileModule.tickets) ? '/tickets/$id' : null,
    'ACCIDENT' => has(MobileModule.accidents) ? '/accidents/$id' : null,
    'INSPECTION' => has(MobileModule.inspections) ? '/inspections/$id' : null,
    'WORK' => has(MobileModule.works) ? '/works/$id' : null,
    'ASSET' => has(MobileModule.inventory) ? '/inventory/$id' : null,
    'MAINTENANCE' => has(MobileModule.maintenance) ? '/maintenance' : null,
    _ => null,
  };
}
