import 'dart:async';

import '../../../../core/files/local_file_store.dart';
import '../../../../core/offline/operation.dart';
import '../../../../core/offline/operation_queue.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'api_tickets_repository.dart';

/// Los tickets del servidor, con la captura que no se pierde sin red: si el
/// ticket o su seguimiento no pueden enviarse porque no hay conexion, quedan en
/// la cola local con su clave de idempotencia y salen por `/api/sync/operations`
/// cuando vuelve la red (MOB-016). Cualquier otro fallo se avisa como siempre.
///
/// Para armar un ticket sin red hace falta haber visto antes los tipos de ticket
/// y la carretera de la concesion: al abrir el formulario se aprenden.
class OfflineTicketsRepository implements TicketsRepository, ScopeBound {
  OfflineTicketsRepository(this._online, this._queue, this._files);

  final ApiTicketsRepository _online;
  final OperationQueue _queue;
  final LocalFileStore _files;
  OfflineScope? _scope;

  /// Tipos de operacion de la cola de tickets, con el nombre que les da el
  /// servidor (`SyncEntities`).
  static const ticketEntity = 'TICKET';
  static const followUpEntity = 'TICKET_FOLLOW_UP';

  /// Datos propios de la app dentro de lo que se guarda en la cola; no viajan al
  /// servidor.
  static const photosKey = '_photos';
  static const attendedKey = '_attended';
  static const atKey = '_at';
  static const latKey = '_lat';
  static const lngKey = '_lng';

  @override
  Future<void> bind(OfflineScope? scope) async {
    if (_scope != scope) _online.forget();
    _scope = scope;
  }

  @override
  Future<void> clear() async => _online.forget();

  @override
  Future<List<Ticket>> list() => _online.list();

  @override
  Future<Ticket> get(String id) => _online.get(id);

  @override
  Future<List<String>> categories() async {
    final labels = await _online.categories();
    // Se aprende la carretera mientras hay red, por si la captura sale sin ella.
    unawaited(_online.warmRoad().catchError((Object _) {}));
    return labels;
  }

  @override
  Future<Ticket> create(NewTicket draft) async {
    try {
      return await _online.create(draft);
    } on TicketsException catch (e) {
      final scope = _scope;
      if (e.error != TicketsError.network || scope == null) rethrow;
      final Map<String, Object?> body;
      try {
        body = await _online.ticketBody(draft);
      } catch (_) {
        // No se conocen los tipos o la carretera: no hay con que armarlo.
        rethrow;
      }
      final id = draft.clientId ?? '';
      final photos = await _keep(draft.photoPaths);
      await _queue.enqueue(
        scope,
        entity: ticketEntity,
        kind: OperationKind.insert,
        key: draft.clientId,
        capturedAt: draft.capturedAt,
        payload: {
          ...body,
          if (photos.isNotEmpty) photosKey: photos,
          if (draft.capturedAt != null)
            atKey: draft.capturedAt!.toUtc().toIso8601String(),
          latKey: ?draft.location?.latitude,
          lngKey: ?draft.location?.longitude,
        },
      );
      return Ticket(
        id: id,
        code: '',
        title: draft.title,
        status: TicketStatus.open,
        createdAt: draft.capturedAt ?? DateTime.now().toUtc(),
        description: draft.description,
        category: draft.category,
        kmLabel: draft.kmLabel,
        latitude: draft.location?.latitude,
        longitude: draft.location?.longitude,
        photoPaths: photos,
      );
    }
  }

  @override
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp) async {
    try {
      return await _online.addFollowUp(ticketId, followUp);
    } on TicketsException catch (e) {
      final scope = _scope;
      if (e.error != TicketsError.network || scope == null) rethrow;
      final photos = await _keep(followUp.photoPaths);
      await _queue.enqueue(
        scope,
        entity: followUpEntity,
        kind: OperationKind.insert,
        recordId: ticketId,
        capturedAt: followUp.at,
        payload: {
          ..._online.followUpBody(followUp),
          if (photos.isNotEmpty) photosKey: photos,
          attendedKey: followUp.status == TicketStatus.attended,
          atKey: followUp.at.toUtc().toIso8601String(),
        },
      );
      // El ticket que se ve no cambia hasta que el servidor reciba el
      // seguimiento; sin red tampoco se puede volver a pedir.
      try {
        return await _online.get(ticketId);
      } catch (_) {
        return Ticket(
          id: ticketId,
          code: '',
          title: '',
          status: TicketStatus.open,
          createdAt: followUp.at,
        );
      }
    }
  }

  /// Las fotos se copian a un lugar propio: las de la camara pueden ser
  /// temporales y la cola las necesita dias despues.
  Future<List<String>> _keep(List<String> paths) async {
    final kept = <String>[];
    for (final path in paths) {
      final name = path.split(RegExp(r'[\\/]')).last;
      try {
        kept.add(await _files.keep(path, name: name));
      } catch (_) {
        // Una foto que no se pudo copiar no detiene el ticket.
      }
    }
    return kept;
  }
}
