import 'package:equatable/equatable.dart';

import 'geo_bounds.dart';

/// Un paquete de teselas de una concesion, tal como lo publica el servidor
/// (`GET /api/maps/packs`): un archivo MBTiles versionado con su huella.
class MapPack extends Equatable {
  const MapPack({
    required this.id,
    required this.name,
    required this.version,
    required this.sizeBytes,
    required this.sha256,
    required this.minZoom,
    required this.maxZoom,
    required this.bounds,
    this.format = 'mbtiles',
    this.generatedAt,
    this.attribution,
  });

  final String id;
  final String name;

  /// Sube con cada paquete nuevo de la misma concesion.
  final int version;

  /// Tamano exacto del archivo: con la huella, es lo que se verifica al bajarlo.
  final int sizeBytes;

  /// SHA-256 del archivo, en hexadecimal.
  final String sha256;
  final int minZoom;
  final int maxZoom;
  final GeoBounds bounds;
  final String format;

  /// UTC.
  final DateTime? generatedAt;

  /// Texto de atribucion que debe verse con estas teselas.
  final String? attribution;

  /// Lo minimo para aceptar un paquete del servidor: formato conocido, tamano
  /// y huella validos y un rango de zoom con sentido.
  bool get isUsable =>
      id.isNotEmpty &&
      format == 'mbtiles' &&
      sizeBytes > 0 &&
      RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(sha256) &&
      minZoom >= 0 &&
      maxZoom >= minZoom &&
      maxZoom <= 24 &&
      bounds.isValid;

  @override
  List<Object?> get props => [
    id,
    name,
    version,
    sizeBytes,
    sha256,
    minZoom,
    maxZoom,
    bounds,
    format,
    generatedAt,
    attribution,
  ];
}

/// Un paquete ya guardado en el telefono.
class InstalledPack extends Equatable {
  const InstalledPack({
    required this.id,
    required this.name,
    required this.version,
    required this.sizeBytes,
    required this.sha256,
    required this.minZoom,
    required this.maxZoom,
    required this.bounds,
    required this.installedAt,
    this.attribution,
  });

  final String id;
  final String name;
  final int version;
  final int sizeBytes;
  final String sha256;
  final int minZoom;
  final int maxZoom;
  final GeoBounds bounds;

  /// UTC.
  final DateTime installedAt;
  final String? attribution;

  /// El servidor ya tiene una version mas nueva de este paquete.
  bool isOlderThan(MapPack remote) =>
      remote.id == id && remote.version > version;

  @override
  List<Object?> get props => [
    id,
    name,
    version,
    sizeBytes,
    sha256,
    minZoom,
    maxZoom,
    bounds,
    installedAt,
    attribution,
  ];
}

/// Avance de una descarga.
class PackProgress extends Equatable {
  const PackProgress({
    required this.receivedBytes,
    required this.totalBytes,
    this.verifying = false,
  });

  final int receivedBytes;
  final int totalBytes;

  /// Ya llego todo y se esta comprobando la huella.
  final bool verifying;

  double get fraction =>
      totalBytes <= 0 ? 0 : (receivedBytes / totalBytes).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [receivedBytes, totalBytes, verifying];
}
