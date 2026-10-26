import 'operation.dart';
import 'sync_engine.dart';

/// Reparte cada operacion al cliente de su tipo de registro (documentos,
/// tickets...). Un tipo que nadie atiende se rechaza con un motivo claro en
/// lugar de quedarse reintentando para siempre.
class RoutedSyncRemote implements SyncRemote {
  const RoutedSyncRemote(this._byEntity);

  final Map<String, SyncRemote> _byEntity;

  @override
  Future<SyncOutcome> send(PendingOperation operation) {
    final remote = _byEntity[operation.entity];
    if (remote == null) {
      return Future.value(
        SyncRejected('La app no sabe enviar «${operation.entity}»'),
      );
    }
    return remote.send(operation);
  }
}
