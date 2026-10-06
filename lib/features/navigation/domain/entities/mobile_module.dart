import 'navigation_entities.dart';

/// Modulos de la app movil (BBP §7.2) y el modulo del catalogo funcional que
/// los habilita. La lista sale del backend (`/api/context/navigation`).
enum MobileModule {
  /// Supuesto pendiente de validar: el catalogo no tiene un modulo "Mapa";
  /// se muestra si el usuario ve Inventario o Panel.
  map(['INVENTARIO', 'PANEL']),
  dashboard(['PANEL']),
  accidents(['ANTT.ACCIDENTES']),
  maintenance(['MANTENIMIENTO']),
  inventory(['INVENTARIO']),
  reports(['REPORTES']),
  tickets(['TICKETS', 'MANTENIMIENTO.NUEVO_TICKET']),
  alerts(['ALERTAS_OPERATIVAS']);

  const MobileModule(this.catalogCodes);

  /// Basta con que el usuario vea uno de estos codigos.
  final List<String> catalogCodes;

  bool isAvailableIn(NavigationMenu menu) => catalogCodes.any(menu.has);

  /// Modulos moviles visibles, en el orden del diseno v2.
  static List<MobileModule> availableIn(NavigationMenu menu) => [
    for (final m in MobileModule.values)
      if (m.isAvailableIn(menu)) m,
  ];
}
