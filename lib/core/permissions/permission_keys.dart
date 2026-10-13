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

  /// Inventario: consultar activos (tambien sirve de base del mapa).
  static const inventoryView = 'INVENTARIO:VISUALIZAR_CONTENIDO';
}
