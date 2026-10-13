import 'package:equatable/equatable.dart';

import '../../../../core/permissions/permission_keys.dart';

/// Lo que el usuario puede hacer en el gestor documental, segun los permisos de
/// su sesion (DTF M03 §3.1). La interfaz no concede nada: solo deja de ofrecer
/// lo que el servidor no permitiria (DEV-MOB-092).
///
/// Las claves de Ver y Cargar son las que el backend entrega hoy en
/// `/api/context/navigation` (`MODULO:ACCION`). La de Firmar es
/// `DOCUMENTOS:FIRMAR`. Las claves viven en
/// `core/permissions/permission_keys.dart`.
class DocumentAccess extends Equatable {
  const DocumentAccess({
    this.canView = false,
    this.canUpload = false,
    this.canSign = false,
  });

  static const none = DocumentAccess();

  /// Ver: consulta, ficha y vista previa.
  static const viewKey = PermissionKeys.documentsView;

  /// Cargar: ademas de Ver.
  static const uploadKey = PermissionKeys.documentsUpload;

  /// Firmar: ademas de Ver.
  static const signKey = PermissionKeys.documentsSign;

  /// Cargar y Firmar suponen Ver (§3.1: «Ver + Cargar», «Ver + Firmar»): sin
  /// Ver no se concede ninguna accion.
  factory DocumentAccess.fromPermissions(Iterable<String> permissions) {
    final set = permissions.toSet();
    final view = set.contains(viewKey);
    return DocumentAccess(
      canView: view,
      canUpload: view && set.contains(uploadKey),
      canSign: view && set.contains(signKey),
    );
  }

  final bool canView;
  final bool canUpload;
  final bool canSign;

  @override
  List<Object?> get props => [canView, canUpload, canSign];
}
