import 'package:equatable/equatable.dart';

/// Como esta el activo (estado fisico, de la ultima inspeccion).
enum AssetCondition { good, regular, poor }

/// Un activo de la carretera (senal, defensa, drenaje, obra de arte...): lo que
/// la app consulta; el alta y la baja son de la plataforma web (M13).
class InventoryAsset extends Equatable {
  const InventoryAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.condition,
    this.kmLabel,
    this.segmentCode,
    this.direction,
    this.latitude,
    this.longitude,
    this.installedAt,
    this.lastInspectionAt,
    this.notes,
  });

  final String id;
  final String name;

  /// Tipo de activo tal como lo entrega el servidor (`Defensa metálica`).
  final String category;
  final AssetCondition condition;

  /// Referencia kilometrica tal como la muestra el negocio (`KM 150+200`).
  final String? kmLabel;
  final String? segmentCode;

  /// Sentido de la carretera, tal como lo entrega el servidor.
  final String? direction;

  /// Donde esta; sin ella no se puede abrir en el mapa.
  final double? latitude;
  final double? longitude;

  /// Fechas, en UTC.
  final DateTime? installedAt;
  final DateTime? lastInspectionAt;
  final String? notes;

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;

  /// Texto para buscar: nombre, tipo, codigo, tramo y kilometro (la ubicacion).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      id,
      name,
      category,
      segmentCode,
      kmLabel,
    ].any((v) => v != null && v.toLowerCase().contains(q));
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    condition,
    kmLabel,
    segmentCode,
    direction,
    latitude,
    longitude,
    installedAt,
    lastInspectionAt,
    notes,
  ];
}
