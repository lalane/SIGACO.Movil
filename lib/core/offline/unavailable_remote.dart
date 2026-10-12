import 'operation.dart';
import 'sync_engine.dart';

/// Hasta que el backend publique los endpoints de sincronizacion, nada se
/// puede enviar: toda operacion se queda en la cola y se reintenta mas tarde.
/// Se sustituye por el cliente real de cada tipo de registro (documentos,
/// firmas...) sin tocar el resto.
class UnavailableSyncRemote implements SyncRemote {
  const UnavailableSyncRemote();

  @override
  Future<SyncOutcome> send(PendingOperation operation) async =>
      const SyncRetryLater(
        'El servicio de sincronizacion todavia no esta disponible',
        retryAfter: Duration(minutes: 5),
      );
}
