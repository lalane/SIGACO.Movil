/// Claves de permiso que el backend entrega en `/api/context/navigation`, con la
/// forma `FUNCION:ACCION` (semilla de autorizacion de SIGACO.Api, DTF M01 y M02
/// v3.2). Viven aqui para que los modulos las compartan sin importarse entre si.
abstract final class PermissionKeys {
  /// Gestor documental: consultar, abrir la ficha y la vista previa.
  static const documentsView = 'DOCUMENTOS:VISUALIZAR_CONTENIDO';

  /// Gestor documental: cargar documentos.
  static const documentsUpload = 'DOCUMENTOS:CARGAR_INFORMACION';

  /// Gestor documental: firmar una version (accion FIRMAR del backend; la
  /// reciben DIRECTOR_NOVA, GERENTE_NOVA y SUPERVISION).
  static const documentsSign = 'DOCUMENTOS:FIRMAR';

  /// Inventario: consultar activos (tambien sirve de base del mapa mientras el
  /// catalogo no publique el modulo SIG).
  static const inventoryView = 'INVENTARIO:VISUALIZAR_CONTENIDO';

  /// Inventario: dar de alta activos. El servidor acepta cualquiera de las dos
  /// (`AssetPermissions.Create` de SIGACO.Api): la del modulo y la del
  /// submodulo de inventario individual de Mantenimiento.
  static const inventoryCreate = [
    'INVENTARIO:CREAR_NUEVO_ELEMENTO',
    'MANTENIMIENTO.INVENTARIO_INDIVIDUAL:CREAR_NUEVO_ELEMENTO',
  ];

  /// SIG: ver el mapa (DTF M10: "SIG: Ver mapa", permiso nuevo propuesto en P11).
  /// La clave sigue la forma FUNCION:ACCION; hay que confirmarla cuando el
  /// backend la publique.
  static const sigView = 'SIG:VISUALIZAR_CONTENIDO';
}
