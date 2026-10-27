import '../../../../core/api/api_client.dart';
import '../../../../core/offline/api_sync_remote.dart';
import '../../../../core/offline/operation.dart';
import '../../domain/entities/ticket.dart';
import '../repositories/api_tickets_repository.dart';
import '../repositories/offline_tickets_repository.dart';

/// Envia al servidor los tickets y seguimientos capturados sin conexion (ver
/// [ApiSyncRemote]). Las fotos no viajan en el lote: se suben al ticket ya
/// creado.
class TicketsSyncRemote extends ApiSyncRemote {
  TicketsSyncRemote(
    ApiClient api,
    this._tickets,
    Future<String?> Function() deviceIdentifier,
  ) : super(api, deviceIdentifier);

  final ApiTicketsRepository _tickets;

  @override
  Set<String> get entities => const {
    OfflineTicketsRepository.ticketEntity,
    OfflineTicketsRepository.followUpEntity,
  };

  /// Las fotos y el estado que siguen a lo ya registrado.
  @override
  Future<void> afterApplied(PendingOperation op, String? recordId) async {
    final photos = [
      for (final p
          in (op.payload[OfflineTicketsRepository.photosKey] as List?) ??
              const [])
        if (p is String) p,
    ];
    final at = DateTime.tryParse(
      '${op.payload[OfflineTicketsRepository.atKey] ?? ''}',
    );
    if (op.entity == OfflineTicketsRepository.ticketEntity) {
      if (recordId == null || photos.isEmpty) return;
      final lat = op.payload[OfflineTicketsRepository.latKey];
      final lng = op.payload[OfflineTicketsRepository.lngKey];
      await _tickets.attachPhotos(
        recordId,
        photos,
        capturedAt: at ?? op.capturedAt,
        location: lat is num && lng is num
            ? TicketLocation(
                latitude: lat.toDouble(),
                longitude: lng.toDouble(),
                origin: TicketLocationOrigin.gps,
              )
            : null,
      );
      return;
    }
    final ticketId = op.recordId;
    if (ticketId == null) return;
    await _tickets.finishFollowUp(
      ticketId,
      recordId,
      photos: photos,
      at: at ?? op.capturedAt,
      attended: op.payload[OfflineTicketsRepository.attendedKey] == true,
    );
  }
}
