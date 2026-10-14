import '../core/offline/operation.dart';
import '../core/offline/operation_queue.dart';
import '../core/offline/sync_engine.dart';
import '../features/navigation/domain/repositories/navigation_repository.dart';

/// Antes de enviar lo capturado sin conexion se revalida la sesion y los
/// permisos (DEV-MOB-094, DTF M03 §3.2): el telefono pudo pasar horas sin red,
/// y en ese tiempo la sesion pudo vencer, la cuenta bloquearse o un
/// administrador quitar un permiso.
///
///  - Si el servidor no confirma la sesion y el contexto (menu), no se envia
///    nada: lo pendiente se conserva y se reintenta mas tarde.
///  - La operacion cuyo permiso ya no existe no se envia: queda rechazada con un
///    motivo claro, para que la persona decida (CA-HU-MOB-03-02-04). El
///    servidor igual vuelve a validar cada operacion.
class SyncRevalidation {
  SyncRevalidation({
    required this.navigation,
    required this.queue,
    required this.requiredPermissions,
  });

  final NavigationRepository navigation;
  final OperationQueue queue;

  /// Por tipo de registro (`documento`...), los permisos que hacen falta todos.
  final Map<String, List<String>> requiredPermissions;

  static const withdrawnMessage =
      'Ya no tienes permiso para esta accion. Descartala o pide que te lo '
      'devuelvan.';

  Future<SyncGate> call(OfflineScope scope) async {
    final granted = <String>{};
    try {
      granted.addAll((await navigation.load()).permissions);
    } catch (_) {
      return SyncGate.hold;
    }
    final pending = await queue.list(
      scope,
      statuses: {OperationStatus.pending},
    );
    for (final op in pending) {
      final needed = requiredPermissions[op.entity];
      if (needed == null || needed.every(granted.contains)) continue;
      await queue.markRejected(op.id, error: withdrawnMessage);
    }
    return SyncGate.proceed;
  }
}
