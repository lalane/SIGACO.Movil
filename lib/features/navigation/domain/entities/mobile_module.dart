import '../../../../core/permissions/permission_keys.dart';
import 'navigation_entities.dart';

/// Modulos de la app movil (BBP §7.2) y el modulo del catalogo funcional que
/// los habilita. La lista sale del backend (`/api/context/navigation`).
enum MobileModule {
  /// Supuesto pendiente de validar: el catalogo no tiene una funcion de mapa;
  /// se muestra a quien puede consultar el inventario (los activos son lo que
  /// se dibuja). `PANEL:PANEL_WEB` es solo de la web y no habilita el mapa.
  map(['INVENTARIO'], requiredPermissions: [PermissionKeys.inventoryView]),

  /// El panel no tiene permiso movil propio: se usa el modulo PANEL.
  dashboard(['PANEL']),
  accidents(['ANTT.ACCIDENTES']),
  maintenance(['MANTENIMIENTO']),
  inventory(['INVENTARIO']),
  reports(['REPORTES']),
  tickets(['TICKETS', 'MANTENIMIENTO.NUEVO_TICKET']),
  alerts(['ALERTAS_OPERATIVAS']),

  /// Gestor documental (M03): la tarjeta aparece solo si el menu trae el modulo
  /// y el usuario puede Ver; sin Ver no tendria nada que abrir.
  documents(
    ['DOCUMENTOS'],
    requiredPermissions: [PermissionKeys.documentsView],
  );

  const MobileModule(this.catalogCodes, {this.requiredPermissions = const []});

  /// Basta con que el usuario vea uno de estos codigos.
  final List<String> catalogCodes;

  /// Si no esta vacia, ademas hace falta alguno de estos permisos.
  final List<String> requiredPermissions;

  bool isAvailableIn(NavigationMenu menu) =>
      catalogCodes.any(menu.has) &&
      (requiredPermissions.isEmpty ||
          requiredPermissions.any(menu.permissions.contains));

  /// Modulos moviles visibles, en el orden del diseno v2.
  static List<MobileModule> availableIn(NavigationMenu menu) => [
    for (final m in MobileModule.values)
      if (m.isAvailableIn(menu)) m,
  ];
}
