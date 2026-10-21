import '../core/offline/operation.dart';
import '../core/offline/operation_queue.dart';
import '../core/offline/sync_engine.dart';
import '../features/auth/domain/entities/auth_entities.dart';

/// Antes de enviar lo capturado sin conexion se revalida la sesion y los
/// permisos (DEV-MOB-094, DTF M03 §3.2): el telefono pudo pasar horas sin red,
/// y en ese tiempo la sesion pudo vencer, la cuenta bloquearse o un
/// administrador quitar un permiso.
///
///  - Se pregunta al servidor (POST /api/auth/session/revalidate). Si no
///    responde, o la cuenta ya no esta activa, o falta un paso (MFA, cambio de
///    contrasena), no se envia nada: lo pendiente se conserva y se reintenta
///    despues. Si la sesion fue revocada, el servidor responde 401 y la app
///    pide un nuevo acceso.
///  - La operacion cuyo permiso ya no existe no se envia: queda rechazada con un
///    motivo claro, para que la persona decida (CA-HU-MOB-03-02-04). El
///    servidor igual vuelve a validar cada operacion.
class SyncRevalidation {
  SyncRevalidation({
    required this.revalidate,
    required this.queue,
    required this.requiredPermissions,
  });

  /// Revalida la sesion en el servidor ([AuthRepository.revalidateSession]).
  final Future<SessionRevalidation> Function() revalidate;
  final OperationQueue queue;

  /// Por tipo de registro (`documento`...), los permisos que hacen falta todos.
  final Map<String, List<String>> requiredPermissions;

  static const withdrawnMessage =
      'Ya no tienes permiso para esta accion. Descartala o pide que te lo '
      'devuelvan.';

  Future<SyncGate> call(OfflineScope scope) async {
    final granted = <String>{};
    try {
      final session = await revalidate();
      if (!session.isActive || session.needsStep) return SyncGate.hold;
      granted.addAll(session.permissions);
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
