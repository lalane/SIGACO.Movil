import '../../features/inventory/domain/entities/inventory_asset.dart';
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

/// La ruta del formulario de un ticket nuevo levantado desde la ficha de un
/// activo: va el activo y no un punto, asi que sirve aunque no tenga geometria
/// (el servidor toma de el carretera, km, sentido y geometria). Se precargan su
/// km y su indicador.
String ticketNewRouteForAsset(InventoryAsset asset) {
  final (start, end) = _kmRange(asset.kmLabel);
  return Uri(
    path: '/tickets/new',
    queryParameters: {
      'asset': asset.id,
      'assetCode': ?asset.code,
      'km': ?start,
      'kmEnd': ?end,
      'indicator': ?asset.subsystemCode,
    },
  ).toString();
}

/// `KM 150+200 - 151+000` -> (`KM 150+200`, `KM 151+000`); sin final, null.
(String?, String?) _kmRange(String? label) {
  final text = label?.trim();
  if (text == null || text.isEmpty) return (null, null);
  final parts = text.split(' - ');
  if (parts.length != 2) return (text, null);
  final end = parts[1].trim();
  return (
    parts[0].trim(),
    end.toUpperCase().startsWith('KM') ? end : 'KM $end',
  );
}

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

/// El activo que traen los parametros de [ticketNewRouteForAsset] (o el del
/// mapa, que ademas trae su punto); null si no viene.
TicketAssetRef? parseTicketAsset(Map<String, String> query) {
  String? text(String key) {
    final v = query[key]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  final id = text('asset');
  if (id == null) return null;
  return TicketAssetRef(
    id: id,
    code: text('assetCode'),
    kmLabel: text('km'),
    kmEndLabel: text('kmEnd'),
    subsystemCode: text('indicator'),
  );
}
