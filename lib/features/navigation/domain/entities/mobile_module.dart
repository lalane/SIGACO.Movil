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

  /// Supuesto pendiente de validar: el catalogo funcional del backend todavia
  /// no tiene estos dos; se usan los nombres de M08 y M06 del Blueprint.
  inspections(['INSPECCIONES']),
  works(['OBRAS', 'AVANCE_OBRAS']),

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

  bool isAvailableIn(NavigationMenu menu) {
    // El mapa lo decide el permiso "SIG: Ver mapa" y no el de inventario (DTF
    // M10, HU-MOB-10-01): en cuanto el menu trae el modulo SIG, manda su
    // permiso. Mientras no lo publique, se usa el de inventario (supuesto).
    if (this == MobileModule.map && menu.has('SIG')) {
      return menu.permissions.contains(PermissionKeys.sigView);
    }
    return _availableByCatalog(menu);
  }

  bool _availableByCatalog(NavigationMenu menu) =>
      catalogCodes.any(menu.has) &&
      (requiredPermissions.isEmpty ||
          requiredPermissions.any(menu.permissions.contains));

  /// Modulos moviles visibles, en el orden del diseno v2.
  static List<MobileModule> availableIn(NavigationMenu menu) => [
    for (final m in MobileModule.values)
      if (m.isAvailableIn(menu)) m,
  ];
}
