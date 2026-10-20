import '../../features/map/domain/entities/map_record_target.dart';
import '../../features/tickets/domain/entities/ticket.dart';

/// La ruta del formulario de un ticket nuevo levantado desde el mapa: el lugar
/// viaja como parametros (el mapa y los tickets no se importan entre si).
String ticketNewRoute(MapRecordTarget target) => Uri(
  path: '/tickets/new',
  queryParameters: {
    'lat': '${target.latitude}',
    'lon': '${target.longitude}',
    'src': target.origin.name,
    if (target.accuracyMeters != null) 'acc': '${target.accuracyMeters}',
    if (target.readAt != null) 'at': target.readAt!.toUtc().toIso8601String(),
    if (target.assetId != null) 'asset': target.assetId!,
    if (target.kmLabel != null) 'km': target.kmLabel!,
  },
).toString();

/// El lugar que traen los parametros de [ticketNewRoute]; null si no hay o son
/// invalidos (el formulario se abre normal, sin ubicacion).
TicketLocation? parseTicketLocation(Map<String, String> query) {
  final lat = double.tryParse(query['lat'] ?? '');
  final lon = double.tryParse(query['lon'] ?? '');
  if (lat == null ||
      lon == null ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat.abs() > 90 ||
      lon.abs() > 180) {
    return null;
  }
  final origin = TicketLocationOrigin.values
      .where((o) => o.name == query['src'])
      .firstOrNull;
  if (origin == null) return null;
  return TicketLocation(
    latitude: lat,
    longitude: lon,
    origin: origin,
    accuracyMeters: double.tryParse(query['acc'] ?? ''),
    readAt: DateTime.tryParse(query['at'] ?? '')?.toUtc(),
    assetId: query['asset'],
    kmLabel: query['km'],
  );
}
